classdef Metricas < handle
% Métricas: guarda los tiempos de cada lectura, calcula FPS de cuadros únicos
% y ms promedio por etapa en una ventana móvil, y exporta todo a CSV.
% También toma muestras de memoria y CPU del proceso de MATLAB (consumo de recursos).

    properties
        ventana_s = 1       % duración de la ventana móvil (s)
        reloj               % tic de inicio
        n = 0               % lecturas registradas
        datos = []          % columnas: tiempo, nuevo, captura, gris, operación, despliegue
        operacion = {}      % nombre de la operación en cada lectura
        inicio = 1          % primera fila dentro de la ventana móvil
        marca = ''          % fecha y hora con milisegundos para los nombres de los CSV
        recursos = zeros(0, 3)  % una fila por muestra: memoria MB, CPU acumulado (s), tiempo de vida del proceso (s)
        recursos_op = {}        % operación que terminó en cada muestra ('' en la del inicio)
        nucleos = 1             % núcleos físicos (feature numcores) para pasar el CPU a porcentaje
        descontado = 0          % segundos gastados en tomar muestras, se quitan de la línea de tiempo
    end

    methods
        function obj = Metricas(cfg)
            obj.ventana_s = cfg.metricas.ventana_s;
            obj.datos = zeros(10000, 6);
            obj.operacion = cell(10000, 1);
            obj.marca = datestr(now, 'yyyymmdd_HHMMSS_FFF');
            try
                obj.nucleos = feature('numcores');
            catch
                obj.nucleos = 1;
            end
            % La muestra del inicio se toma antes de arrancar el reloj, así no hay que descontarla
            obj.tomar_recursos('');
            obj.descontado = 0;
            obj.reloj = tic;
        end

        function registrar(obj, ms_captura, ms_gris, ms_operacion, ms_despliegue, nuevo, nombre_op)
            % Si se llenó el espacio reservado se duplica
            if obj.n == size(obj.datos, 1)
                obj.datos = [obj.datos; zeros(size(obj.datos))];
                obj.operacion = [obj.operacion; cell(size(obj.operacion))];
            end
            obj.n = obj.n + 1;
            obj.datos(obj.n, :) = [toc(obj.reloj) - obj.descontado, nuevo, ms_captura, ms_gris, ms_operacion, ms_despliegue];
            obj.operacion{obj.n} = nombre_op;
        end

        function tomar_recursos(obj, nombre_op)
            % Guarda memoria y CPU acumulado en este momento. PowerShell tarda ~0.3 s,
            % por eso solo se llama al inicio, al final y en cada cambio de operación.
            a = tic;

            % memory solo existe en Windows
            mem = NaN;
            try
                m = memory;
                mem = m.MemUsedMATLAB / 2^20;
            catch
            end

            % CPU acumulado y tiempo de vida del proceso, leídos en el mismo instante por PowerShell
            % (InvariantCulture para que el decimal salga con punto y no con coma)
            cpu = NaN;
            vida = NaN;
            try
                pid = feature('getpid');
                orden = ['powershell -NoProfile -Command "$p = Get-Process -Id ' num2str(pid) '; ' ...
                    '[string]::Format([cultureinfo]::InvariantCulture, ''{0} {1}'', ' ...
                    '$p.TotalProcessorTime.TotalSeconds, ((Get-Date) - $p.StartTime).TotalSeconds)"'];
                [estado, s] = system(orden);
                v = sscanf(s, '%f');
                if estado == 0 && numel(v) == 2
                    cpu = v(1);
                    vida = v(2);
                end
            catch
            end

            obj.recursos(end + 1, :) = [mem, cpu, vida];
            obj.recursos_op{end + 1} = nombre_op;
            obj.descontado = obj.descontado + toc(a);
        end

        function p = cpu_pct(obj, j0, j1)
            % Porcentaje medio de CPU del proceso entre las muestras j0 y j1 (100 % = todos los núcleos)
            d = obj.recursos(j1, :) - obj.recursos(j0, :);
            p = 100 * d(2) / (d(3) * obj.nucleos);
        end

        function r = resumen(obj, total)
            % resumen(): última ventana de ventana_s segundos; resumen(true): toda la corrida
            if nargin < 2, total = false; end
            r = struct('fps_unicos', 0, 'lecturas_por_s', 0, 'lecturas', 0, 'unicos', 0, ...
                'segundos', 0, 'ms_captura', 0, 'ms_gris', 0, 'ms_operacion', 0, 'ms_despliegue', 0, ...
                'medianas', zeros(1, 4), 'mem_inicio', NaN, 'mem_fin', NaN, 'cpu_pct', NaN);

            % Recursos de toda la corrida: primera y última muestra
            if total && size(obj.recursos, 1) >= 2
                r.mem_inicio = obj.recursos(1, 1);
                r.mem_fin = obj.recursos(end, 1);
                r.cpu_pct = obj.cpu_pct(1, size(obj.recursos, 1));
            end
            if obj.n == 0, return; end

            ahora = obj.datos(obj.n, 1);
            if total
                filas = 1:obj.n;
                dur = ahora;
            else
                % Se avanza el inicio de la ventana hasta quedar dentro del último segundo
                while obj.datos(obj.inicio, 1) < ahora - obj.ventana_s
                    obj.inicio = obj.inicio + 1;
                end
                filas = obj.inicio:obj.n;
                dur = min(obj.ventana_s, ahora);
            end
            d = obj.datos(filas, :);
            u = d(d(:, 2) == 1, :);   % solo cuadros únicos

            r.fps_unicos = size(u, 1) / dur;
            r.lecturas_por_s = size(d, 1) / dur;
            r.lecturas = size(d, 1);
            r.unicos = size(u, 1);
            r.segundos = dur;

            % Promedios por etapa sobre los cuadros únicos (los que pasan por todo el pipeline)
            if ~isempty(u)
                m = mean(u(:, 3:6), 1);
                r.ms_captura = m(1);
                r.ms_gris = m(2);
                r.ms_operacion = m(3);
                r.ms_despliegue = m(4);
                % Medianas [captura gris operación despliegue]: no les afecta el primer cuadro lento
                r.medianas = median(u(:, 3:6), 1);
            end
        end

        function s = texto(obj)
            r = obj.resumen();
            s = sprintf(['FPS únicos: %.1f   (lecturas/s: %.1f)\n' ...
                'ms  captura %.1f | gris %.1f | operación %.1f | despliegue %.1f | suma %.1f'], ...
                r.fps_unicos, r.lecturas_por_s, r.ms_captura, r.ms_gris, r.ms_operacion, ...
                r.ms_despliegue, r.ms_captura + r.ms_gris + r.ms_operacion + r.ms_despliegue);
        end

        function archivo = exportar(obj, carpeta)
            % CSV con una fila por lectura y otro con los promedios por operación
            if ~exist(carpeta, 'dir'), mkdir(carpeta); end
            archivo = fullfile(carpeta, ['metricas_' obj.marca '.csv']);

            f = fopen(archivo, 'w', 'n', 'UTF-8');
            fprintf(f, 'indice,nuevo,operacion,ms_captura,ms_gris,ms_operacion,ms_despliegue\n');
            for i = 1:obj.n
                fprintf(f, '%d,%d,"%s",%.3f,%.3f,%.3f,%.3f\n', i, obj.datos(i, 2), obj.operacion{i}, obj.datos(i, 3:6));
            end
            fclose(f);

            % Promedios por operación (solo cuadros únicos)
            f = fopen(fullfile(carpeta, ['metricas_' obj.marca '_promedios.csv']), 'w', 'n', 'UTF-8');
            fprintf(f, 'operacion,lecturas,cuadros_unicos,ms_captura,ms_gris,ms_operacion,ms_despliegue\n');
            nombres = unique(obj.operacion(1:obj.n), 'stable');
            for i = 1:numel(nombres)
                es = strcmp(obj.operacion(1:obj.n), nombres{i});
                u = es & obj.datos(1:obj.n, 2) == 1;
                fprintf(f, '"%s",%d,%d,%.3f,%.3f,%.3f,%.3f\n', nombres{i}, nnz(es), nnz(u), mean(obj.datos(u, 3:6), 1));
            end
            fclose(f);
        end

        function t = por_operacion(obj)
            % Una fila por operación: cuadros únicos, FPS únicos, medianas de ms por etapa,
            % memoria al terminar la operación y CPU medio mientras corrió
            d = obj.datos(1:obj.n, :);
            nombres = unique(obj.operacion(1:obj.n), 'stable');
            dt = diff([0; d(:, 1)]);   % tiempo que tomó cada lectura (s)
            t = struct('nombre', nombres, 'unicos', 0, 'fps_unicos', 0, 'medianas', zeros(1, 4), ...
                'memoria_mb', NaN, 'cpu_pct', NaN);
            for i = 1:numel(nombres)
                es = strcmp(obj.operacion(1:obj.n), nombres{i});
                u = es & d(:, 2) == 1;
                t(i).unicos = nnz(u);
                t(i).fps_unicos = nnz(u) / sum(dt(es));
                if any(u), t(i).medianas = median(d(u, 3:6), 1); end

                % La muestra que cerró esta operación y la anterior delimitan su tramo
                j = find(strcmp(obj.recursos_op, nombres{i}), 1, 'last');
                if ~isempty(j) && j > 1
                    t(i).memoria_mb = obj.recursos(j, 1);
                    t(i).cpu_pct = obj.cpu_pct(j - 1, j);
                end
            end
        end

        function [archivo, t] = exportar_recorrido(obj, carpeta)
            % CSV con la tabla por operación del modo recorrido
            t = obj.por_operacion();
            if ~exist(carpeta, 'dir'), mkdir(carpeta); end
            archivo = fullfile(carpeta, ['recorrido_' obj.marca '.csv']);
            f = fopen(archivo, 'w', 'n', 'UTF-8');
            fprintf(f, 'operacion,cuadros_unicos,fps_unicos,mediana_ms_captura,mediana_ms_gris,mediana_ms_operacion,mediana_ms_despliegue,memoria_mb,cpu_pct\n');
            for i = 1:numel(t)
                fprintf(f, '"%s",%d,%.2f,%.3f,%.3f,%.3f,%.3f,%.1f,%.1f\n', t(i).nombre, t(i).unicos, t(i).fps_unicos, ...
                    t(i).medianas, t(i).memoria_mb, t(i).cpu_pct);
            end
            fclose(f);
        end
    end
end
