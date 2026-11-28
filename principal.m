function principal(opts)
% PDI VisionLab: captura video de la cámara, aplica la operación elegida y
% muestra el original y el procesado con FPS de cuadros únicos y ms por etapa.
% Uso: principal   o   principal(struct('cuadros_max', 150, 'sin_camara', true))
% opts.cuadros_max: número de lecturas (0 = sin límite)
% opts.sin_camara: usa cuadros sintéticos 480x640 en lugar de la cámara
% opts.sin_ventana: no abre la figura; solo captura, procesa y mide
% opts.recorrer: pasa por todas las operaciones del registro y al final imprime una tabla
% opts.cuadros_por_op: cuadros únicos por operación en el recorrido (por defecto 60)

%% 1. Opciones
if nargin < 1, opts = struct(); end
if ~isfield(opts, 'cuadros_max'), opts.cuadros_max = 0; end
if ~isfield(opts, 'sin_camara'), opts.sin_camara = false; end
if ~isfield(opts, 'sin_ventana'), opts.sin_ventana = false; end
if ~isfield(opts, 'recorrer'), opts.recorrer = false; end
if ~isfield(opts, 'cuadros_por_op'), opts.cuadros_por_op = 60; end

% La raíz del repositorio en el path para que se encuentren los paquetes +visionlab
raiz = fileparts(mfilename('fullpath'));
addpath(raiz);

%% 2. Configuración, registro y estado
cfg = configuracion();
if opts.sin_camara
    cfg.camara.backend = 'sintetica';
end
carpeta = fullfile(raiz, cfg.metricas.carpeta);
ops = visionlab.nucleo.registro();
estado = visionlab.nucleo.Estado();
estado.cambiar_operacion(1, ops);

%% 3. Cámara, ventana y métricas
% onCleanup libera la cámara al salir de la función, aunque haya error o Ctrl+C
cam = visionlab.camara.Camara();
cierre_camara = onCleanup(@() cam.cerrar());
t_abrir = tic;
cam.abrir(cfg);
fprintf('Cámara: %s (abierta en %.1f s)\n', cam.nombre, toc(t_abrir));

ventana = [];
if ~opts.sin_ventana
    ventana = visionlab.interfaz.Ventana(ops, estado, cam.nombre);
end
hay_ventana = ~isempty(ventana);
metricas = visionlab.rendimiento.Metricas(cfg);

% Igual que con la cámara: el CSV se escribe y la figura se cierra pase lo que pase
cierre = onCleanup(@() liberar(ventana, metricas, carpeta));

%% 4. Lazo principal
k = 0;
i_op = 1;        % operación actual del recorrido
unicos_op = 0;   % cuadros únicos que lleva esa operación
while estado.corriendo && (opts.cuadros_max == 0 || k < opts.cuadros_max)
    k = k + 1;

    % Captura
    a = tic;
    [rgb, nuevo] = cam.leer();
    ms_captura = 1000 * toc(a);

    % La operación se lee después de capturar para no mezclar una op vieja con parámetros nuevos
    op = ops(estado.op);

    % Cuadro repetido: no se procesa, solo se cuenta la lectura
    if ~nuevo
        metricas.registrar(ms_captura, 0, 0, 0, false, op.nombre);
        if hay_ventana, drawnow limitrate; end
        continue
    end

    % Conversión a gris
    b = tic;
    gris = visionlab.camara.a_gris(rgb);
    ms_gris = 1000 * toc(b);

    % Operación activa (el pipeline mide su tiempo)
    [salida, ms_operacion] = visionlab.nucleo.Pipeline.procesar(gris, op, estado);

    % Despliegue (aquí también se atienden los controles de la ventana)
    c = tic;
    img = visionlab.nucleo.Pipeline.a_despliegue(salida);
    if hay_ventana
        ventana.mostrar(rgb, img);
        ventana.texto(metricas.texto());
        drawnow limitrate;
    end
    ms_despliegue = 1000 * toc(c);

    metricas.registrar(ms_captura, ms_gris, ms_operacion, ms_despliegue, true, op.nombre);

    % Recorrido: al juntar cuadros_por_op cuadros únicos se pasa a la siguiente operación
    if opts.recorrer
        unicos_op = unicos_op + 1;
        if unicos_op >= opts.cuadros_por_op
            if i_op == numel(ops), break; end
            % Muestra de memoria y CPU que cierra la operación que acaba de terminar
            metricas.tomar_recursos(op.nombre);
            i_op = i_op + 1;
            unicos_op = 0;
            if hay_ventana
                % Se usa el menú para que también se cambien los deslizadores
                set(ventana.menu, 'Value', find(ventana.orden == i_op));
                elegir = get(ventana.menu, 'Callback');
                elegir(ventana.menu, []);
            else
                estado.cambiar_operacion(i_op, ops);
            end
        end
    end
end

%% 5. Cierre: CSV, cámara, ventana y resumen
% Última muestra de recursos, cierra la última operación y toda la corrida
metricas.tomar_recursos(ops(estado.op).nombre);
r = metricas.resumen(true);
clear cierre cierre_camara   % aquí se ejecutan los onCleanup

suma = r.ms_captura + r.ms_gris + r.ms_operacion + r.ms_despliegue;
fprintf('\nLecturas: %d en %.2f s -> %.1f lecturas/s\n', r.lecturas, r.segundos, r.lecturas_por_s);
fprintf('Cuadros únicos: %d -> %.1f FPS únicos (objetivo %d)\n', r.unicos, r.fps_unicos, cfg.fps_objetivo);
fprintf('ms por cuadro único: captura %.2f | gris %.2f | operación %.2f | despliegue %.2f | suma %.2f\n', ...
    r.ms_captura, r.ms_gris, r.ms_operacion, r.ms_despliegue, suma);
fprintf('medianas:            captura %.2f | gris %.2f | operación %.2f | despliegue %.2f | suma %.2f\n', ...
    r.medianas, sum(r.medianas));
fprintf('Memoria de MATLAB: %.0f MB al inicio, %.0f MB al final | CPU medio del proceso: %.1f %% (%d núcleos)\n', ...
    r.mem_inicio, r.mem_fin, r.cpu_pct, metricas.nucleos);

% Tabla del recorrido (medianas en ms por cuadro único, memoria al terminar cada operación y CPU medio)
if opts.recorrer
    [archivo, t] = metricas.exportar_recorrido(carpeta);
    fprintf('\nRecorrido: %d operaciones, %d cuadros únicos por operación\n', numel(t), opts.cuadros_por_op);
    fprintf('%-34s %7s %7s %8s %7s %10s %11s %11s %7s\n', 'operación', 'únicos', 'FPS', 'captura', 'gris', ...
        'operación', 'despliegue', 'memoria MB', 'CPU %');
    for i = 1:numel(t)
        fprintf('%-34s %7d %7.1f %8.2f %7.2f %10.2f %11.2f %11.0f %7.1f\n', t(i).nombre, t(i).unicos, t(i).fps_unicos, ...
            t(i).medianas, t(i).memoria_mb, t(i).cpu_pct);
    end
    fprintf('CSV del recorrido: %s\n', archivo);
end
end

function liberar(ventana, metricas, carpeta)
% Se llama al salir de principal: exporta las métricas y cierra la figura
if metricas.n > 0
    fprintf('CSV: %s\n', metricas.exportar(carpeta));
end
if ~isempty(ventana), ventana.cerrar(); end
end
