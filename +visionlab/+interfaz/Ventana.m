classdef Ventana < handle
% Ventana: interfaz de captura y visualización en tiempo real.
% Mantiene el lazo fluido y solo escribe en Estado cuando el usuario cambia
% la operación o mueve parámetros.

    properties
        fig            % figura principal
        cerrando = false % evita cierres repetidos o callbacks reentrantes
        estado         % Estado compartido
        ops            % registro de operaciones
        orden          % orden del menú (agrupado por categoría) -> índice en ops
        img_orig       % image del original
        img_proc       % image del procesado
        menu           % popupmenu de operaciones
        info           % indicador de estado de la captura
        metricasUI = gobjects(1, 7) % valores de rendimiento
        controles = gobjects(0)   % controles dinámicos de la operación activa

        % Controles auxiliares de la interfaz
        panelLateral
        panelParametros
        panelEstado
        txtOperacion
        txtCategoria
        txtResumen
        txtAyuda
        botonSalir

        % Paleta visual
        C
    end

    methods
        function obj = Ventana(ops, estado, titulo)
            obj.ops = ops;
            obj.estado = estado;
            obj.C = obj.paleta();

            % Figura clásica: se conserva por rendimiento en video continuo.
            obj.fig = figure('Name', ['PDI VisionLab - webcam: ' titulo], 'NumberTitle', 'off', ...
                'Color', obj.C.bg, 'Position', [40 40 1450 790], 'MenuBar', 'none', ...
                'Resize', 'on', 'CloseRequestFcn', @(src, ~) obj.al_solicitar_cierre(src), ...
                'DeleteFcn', @(~, ~) obj.al_cerrar());

            obj.construir_layout();
            obj.crear_deslizadores();
            obj.actualizar_textos_operacion();
            obj.texto('Esperando cuadros de la cámara...');
            drawnow;
        end

        function mostrar(obj, rgb, salida)
            % No devuelve valores: solo actualiza los objetos gráficos.
            % Si la ventana se cerró, se detiene el lazo sin tocar handles borrados.
            if ~obj.abierta() || ~isgraphics(obj.img_orig) || ~isgraphics(obj.img_proc)
                obj.estado.corriendo = false;
                return;
            end

            set(obj.img_orig, 'CData', rgb);
            set(obj.img_proc, 'CData', salida);
        end

        function texto(obj, cadena)
            % Actualiza las tarjetas sin modificar el lazo de captura.
            if ~isgraphics(obj.info), return; end

            valores = regexp(cadena, '\d+(?:\.\d+)?', 'match');
            if numel(valores) >= 7
                % Asignar cada valor por separado evita que MATLAB interprete
                % el cell array como texto multilínea en todas las tarjetas.
                for k = 1:7
                    if isgraphics(obj.metricasUI(k))
                        valor = valores{k};
                        if k >= 3
                            valor = [valor ' ms'];
                        end
                        set(obj.metricasUI(k), 'String', valor);
                    end
                end
                set(obj.info, 'String', '● EN VIVO');
            elseif contains(cadena, 'Esperando')
                for k = 1:numel(obj.metricasUI)
                    if isgraphics(obj.metricasUI(k))
                        set(obj.metricasUI(k), 'String', '—');
                    end
                end
                set(obj.info, 'String', '● INICIANDO');
            else
                set(obj.info, 'String', '● PROCESANDO');
            end
        end

        function si = abierta(obj)
            si = obj.estado.corriendo && isgraphics(obj.fig) && ...
                isgraphics(obj.img_orig) && isgraphics(obj.img_proc);
            if ~si
                obj.estado.corriendo = false;
            end
        end

        function cerrar(obj)
            % Cierre idempotente: puede llamarse desde Salir, la X y onCleanup.
            if obj.cerrando
                return;
            end

            obj.cerrando = true;
            obj.estado.corriendo = false;

            % Guardar el handle y desvincular callbacks antes de eliminarlo.
            fig = obj.fig;
            obj.fig = gobjects(1);

            if ~isempty(fig) && isgraphics(fig)
                try
                    set(fig, 'CloseRequestFcn', [], 'DeleteFcn', []);
                    delete(fig);
                catch err
                    warning('PDI:Ventana:Cierre', ...
                        'No se pudo cerrar limpiamente la ventana: %s', err.message);
                end
            end
        end
    end

    methods (Access = private)
        function construir_layout(obj)
            C = obj.C;

            % ===== Barra lateral =====
            obj.panelLateral = uipanel(obj.fig, 'Units', 'normalized', ...
                'Position', [0.015 0.03 0.215 0.94], 'BackgroundColor', C.panel, ...
                'ForegroundColor', C.border, 'BorderType', 'line');

            uicontrol(obj.panelLateral, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.08 0.915 0.84 0.05], 'String', 'PDI VisionLab', ...
                'FontSize', 21, 'FontWeight', 'bold', 'ForegroundColor', C.text, ...
                'BackgroundColor', C.panel, 'HorizontalAlignment', 'left');

            uicontrol(obj.panelLateral, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.08 0.885 0.84 0.03], 'String', 'IMAGE PROCESSING STUDIO', ...
                'FontSize', 9, 'FontWeight', 'bold', 'ForegroundColor', C.accent, ...
                'BackgroundColor', C.panel, 'HorizontalAlignment', 'left');

            uicontrol(obj.panelLateral, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.08 0.83 0.84 0.03], 'String', 'OPERACIÓN ACTIVA', ...
                'FontSize', 10, 'FontWeight', 'bold', 'ForegroundColor', C.muted, ...
                'BackgroundColor', C.panel, 'HorizontalAlignment', 'left');

            obj.menu = uicontrol(obj.panelLateral, 'Style', 'popupmenu', 'Units', 'normalized', ...
                'Position', [0.08 0.785 0.84 0.045], 'FontSize', 10, ...
                'BackgroundColor', C.panel2, 'ForegroundColor', C.text, ...
                'Callback', @(src, ~) obj.al_elegir(src));

            obj.txtCategoria = uicontrol(obj.panelLateral, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.08 0.742 0.84 0.03], 'String', '', 'FontSize', 10, ...
                'FontWeight', 'bold', 'ForegroundColor', C.accent2, ...
                'BackgroundColor', C.panel, 'HorizontalAlignment', 'left');

            obj.txtOperacion = uicontrol(obj.panelLateral, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.08 0.695 0.84 0.05], 'String', '', 'FontSize', 12, ...
                'FontWeight', 'bold', 'ForegroundColor', C.text, ...
                'BackgroundColor', C.panel, 'HorizontalAlignment', 'left');

            uicontrol(obj.panelLateral, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.08 0.645 0.84 0.03], 'String', 'PARÁMETROS', ...
                'FontSize', 10, 'FontWeight', 'bold', 'ForegroundColor', C.muted, ...
                'BackgroundColor', C.panel, 'HorizontalAlignment', 'left');

            obj.panelParametros = uipanel(obj.panelLateral, 'Units', 'normalized', ...
                'Position', [0.06 0.26 0.88 0.38], 'BackgroundColor', C.panel2, ...
                'ForegroundColor', C.border, 'BorderType', 'line');

            obj.txtAyuda = uicontrol(obj.panelLateral, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.08 0.19 0.84 0.065], ...
                'String', sprintf('Ajusta parámetros en tiempo real.\nEl lazo no se detiene.'), ...
                'FontSize', 9, 'ForegroundColor', C.muted, ...
                'BackgroundColor', C.panel, 'HorizontalAlignment', 'left');

            obj.botonSalir = uicontrol(obj.panelLateral, 'Style', 'pushbutton', 'Units', 'normalized', ...
                'Position', [0.08 0.08 0.84 0.055], 'String', 'Salir', 'FontSize', 11, ...
                'FontWeight', 'bold', 'BackgroundColor', C.panel2, 'ForegroundColor', C.text, ...
                'Callback', @(~, ~) obj.cerrar());

            uicontrol(obj.panelLateral, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.08 0.025 0.84 0.03], 'String', 'Proyecto académico | MATLAB', ...
                'FontSize', 8, 'ForegroundColor', C.muted, ...
                'BackgroundColor', C.panel, 'HorizontalAlignment', 'left');

            % ===== Encabezado del contenido =====
            uicontrol(obj.fig, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.255 0.90 0.46 0.055], 'String', 'Laboratorio de procesamiento digital de imágenes', ...
                'FontSize', 20, 'FontWeight', 'bold', 'ForegroundColor', C.text, ...
                'BackgroundColor', C.bg, 'HorizontalAlignment', 'left');

            obj.txtResumen = uicontrol(obj.fig, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.255 0.865 0.50 0.03], ...
                'String', 'Captura continua, visualización paralela y métricas de rendimiento en tiempo real.', ...
                'FontSize', 10, 'ForegroundColor', C.accent2, ...
                'BackgroundColor', C.bg, 'HorizontalAlignment', 'left');

            % ===== Panel original =====
            panelOriginal = uipanel(obj.fig, 'Units', 'normalized', ...
                'Position', [0.255 0.265 0.35 0.57], 'BackgroundColor', C.panel, ...
                'ForegroundColor', C.border, 'BorderType', 'line');

            uicontrol(panelOriginal, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.04 0.92 0.92 0.05], 'String', 'ENTRADA DE VIDEO', ...
                'FontSize', 11, 'FontWeight', 'bold', 'ForegroundColor', C.muted, ...
                'BackgroundColor', C.panel, 'HorizontalAlignment', 'left');

            ax1 = axes('Parent', panelOriginal, 'Units', 'normalized', 'Position', [0.05 0.07 0.90 0.78], ...
                'Color', C.panel2, 'XColor', C.panel2, 'YColor', C.panel2, 'Box', 'off');
            obj.img_orig = image(ax1, zeros(480, 640, 3, 'uint8'));
            axis(ax1, 'image', 'off');
            title(ax1, 'Original', 'Color', C.text, 'FontWeight', 'bold', 'FontSize', 15);

            % ===== Panel procesado =====
            panelProcesado = uipanel(obj.fig, 'Units', 'normalized', ...
                'Position', [0.62 0.265 0.35 0.57], 'BackgroundColor', C.panel, ...
                'ForegroundColor', C.border, 'BorderType', 'line');

            uicontrol(panelProcesado, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.04 0.92 0.92 0.05], 'String', 'SALIDA PROCESADA', ...
                'FontSize', 11, 'FontWeight', 'bold', 'ForegroundColor', C.muted, ...
                'BackgroundColor', C.panel, 'HorizontalAlignment', 'left');

            ax2 = axes('Parent', panelProcesado, 'Units', 'normalized', 'Position', [0.05 0.07 0.90 0.78], ...
                'Color', C.panel2, 'XColor', C.panel2, 'YColor', C.panel2, 'Box', 'off');
            obj.img_proc = image(ax2, zeros(480, 640, 'uint8'), 'CDataMapping', 'direct');
            colormap(ax2, gray(256));
            axis(ax2, 'image', 'off');
            title(ax2, 'Procesado', 'Color', C.text, 'FontWeight', 'bold', 'FontSize', 15);

            % ===== Panel de estado y métricas =====
            obj.panelEstado = uipanel(obj.fig, 'Units', 'normalized', ...
                'Position', [0.255 0.045 0.715 0.20], 'BackgroundColor', C.panel, ...
                'ForegroundColor', C.border, 'BorderType', 'line');

            uicontrol(obj.panelEstado, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.02 0.77 0.55 0.15], 'String', 'RENDIMIENTO EN TIEMPO REAL', ...
                'FontSize', 10, 'FontWeight', 'bold', 'ForegroundColor', C.muted, ...
                'BackgroundColor', C.panel, 'HorizontalAlignment', 'left');

            obj.info = uicontrol(obj.panelEstado, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.76 0.77 0.22 0.15], 'String', '● INICIANDO', 'FontSize', 9, ...
                'FontWeight', 'bold', 'ForegroundColor', C.accent2, ...
                'BackgroundColor', C.panel, 'HorizontalAlignment', 'right');

            % Tarjetas compactas: FPS, lecturas y latencia de cada etapa.
            titulosMetricas = {'FPS ÚNICOS', 'LECTURAS/S', 'CAPTURA', ...
                'GRIS', 'OPERACIÓN', 'DESPLIEGUE', 'TOTAL'};
            anchoTarjeta = 0.132;
            separacion = 0.008;
            inicio = 0.014;
            for k = 1:numel(titulosMetricas)
                x = inicio + (k - 1) * (anchoTarjeta + separacion);
                tarjeta = uipanel(obj.panelEstado, 'Units', 'normalized', ...
                    'Position', [x 0.09 anchoTarjeta 0.62], ...
                    'BackgroundColor', C.panel2, 'ForegroundColor', C.border, ...
                    'BorderType', 'line');
                uicontrol(tarjeta, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.04 0.65 0.92 0.20], 'String', titulosMetricas{k}, ...
                    'FontSize', 8, 'FontWeight', 'bold', 'ForegroundColor', C.muted, ...
                    'BackgroundColor', C.panel2, 'HorizontalAlignment', 'center');
                obj.metricasUI(k) = uicontrol(tarjeta, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.04 0.16 0.92 0.40], 'String', '—', ...
                    'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Consolas', ...
                    'ForegroundColor', C.text, 'BackgroundColor', C.panel2, ...
                    'HorizontalAlignment', 'center');
            end

            % Menú con las operaciones agrupadas por categoría ('Categoría: Nombre')
            [~, ~, g] = unique({obj.ops.categoria}, 'stable');
            [~, obj.orden] = sort(g);
            textos = strcat({obj.ops(obj.orden).categoria}, {': '}, {obj.ops(obj.orden).nombre});
            set(obj.menu, 'String', textos, 'Value', find(obj.orden == obj.estado.op));
        end

        function al_solicitar_cierre(obj, ~)
            % El botón X utiliza exactamente la misma ruta que el botón Salir.
            obj.cerrar();
        end

        function al_cerrar(obj)
            % Respaldo si otra parte del programa elimina la figura directamente.
            obj.estado.corriendo = false;
            obj.cerrando = true;
            obj.fig = gobjects(1);
        end

        function al_elegir(obj, src)
            obj.estado.cambiar_operacion(obj.orden(get(src, 'Value')), obj.ops);
            obj.crear_deslizadores();
            obj.actualizar_textos_operacion();
        end

        function crear_deslizadores(obj)
            delete(obj.controles(isvalid(obj.controles)));
            obj.controles = gobjects(0);

            C = obj.C;
            par = obj.ops(obj.estado.op).parametros;

            if isempty(par)
                % Compacta el bloque cuando la operación no tiene parámetros.
                set(obj.panelParametros, 'Position', [0.06 0.42 0.88 0.18]);
                set(obj.txtAyuda, 'Position', [0.08 0.31 0.84 0.06], ...
                    'String', 'La captura continúa en tiempo real.');
                vacio = uicontrol(obj.panelParametros, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.06 0.28 0.88 0.44], ...
                    'String', 'Esta operación no requiere ajustes.', ...
                    'FontSize', 9, 'FontAngle', 'italic', 'ForegroundColor', C.muted, ...
                    'BackgroundColor', C.panel2, 'HorizontalAlignment', 'center');
                obj.controles(end + 1) = vacio;
                return;
            end

            set(obj.panelParametros, 'Position', [0.06 0.26 0.88 0.38]);
            set(obj.txtAyuda, 'Position', [0.08 0.19 0.84 0.065], ...
                'String', sprintf('Ajusta parámetros en tiempo real.\nEl lazo no se detiene.'));

            margenSuperior = 0.90;
            bloque = min(0.24, 0.78 / max(1, numel(par)));
            for i = 1:numel(par)
                y = margenSuperior - i * bloque;
                y = max(y, 0.08);

                nombre = obj.nombre_amigable(par(i).nombre);
                valorStr = obj.formatear_valor(par(i).inicial, par(i).paso);

                etiqueta = uicontrol(obj.panelParametros, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.07 y + 0.08 0.55 0.10], 'String', nombre, ...
                    'FontSize', 10, 'FontWeight', 'bold', 'ForegroundColor', C.text, ...
                    'BackgroundColor', C.panel2, 'HorizontalAlignment', 'left');

                valor = uicontrol(obj.panelParametros, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.64 y + 0.08 0.28 0.10], 'String', valorStr, ...
                    'FontSize', 10, 'ForegroundColor', C.accent, ...
                    'BackgroundColor', C.panel2, 'HorizontalAlignment', 'right');

                rango = par(i).max - par(i).min;
                if rango <= 0
                    pasos = [1 1];
                elseif par(i).paso > 0
                    pasos = [par(i).paso, max(par(i).paso, 0.1 * rango)] / rango;
                else
                    pasos = [0.01 0.10];
                end
                pasos = min(max(pasos, eps), 1);

                barra = uicontrol(obj.panelParametros, 'Style', 'slider', 'Units', 'normalized', ...
                    'Position', [0.07 y 0.85 0.07], 'Min', par(i).min, 'Max', par(i).max, ...
                    'Value', par(i).inicial, 'SliderStep', pasos, 'BackgroundColor', C.panel2);
                barra.Callback = @(src, ~) obj.al_mover(src, par(i), valor);
                addlistener(barra, 'ContinuousValueChange', @(src, ~) obj.al_mover(src, par(i), valor));

                referencia = uicontrol(obj.panelParametros, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.07 y - 0.05 0.85 0.05], ...
                    'String', sprintf('%s     rango [%g, %g]', obj.descripcion_paso(par(i).paso), par(i).min, par(i).max), ...
                    'FontSize', 8, 'ForegroundColor', C.muted, ...
                    'BackgroundColor', C.panel2, 'HorizontalAlignment', 'left');

                obj.controles(end + 1:end + 4) = [etiqueta, valor, barra, referencia]; %#ok<AGROW>
            end
        end

        function al_mover(obj, src, par, txtValor)
            v = get(src, 'Value');
            if par.paso > 0
                v = par.min + round((v - par.min) / par.paso) * par.paso;
                v = min(max(v, par.min), par.max);
                set(src, 'Value', v);
            end
            obj.estado.p.(par.nombre) = v;
            set(txtValor, 'String', obj.formatear_valor(v, par.paso));
        end

        function actualizar_textos_operacion(obj)
            op = obj.ops(obj.estado.op);
            set(obj.txtCategoria, 'String', ['● ' upper(op.categoria)]);
            set(obj.txtOperacion, 'String', op.nombre);

            if obj.estado.op <= numel(obj.orden)
                idx = find(obj.orden == obj.estado.op, 1);
                if ~isempty(idx) && get(obj.menu, 'Value') ~= idx
                    set(obj.menu, 'Value', idx);
                end
            end
        end

        function C = paleta(~)
            C.bg = [0.035 0.055 0.09];
            C.panel = [0.08 0.11 0.17];
            C.panel2 = [0.11 0.14 0.20];
            C.text = [0.93 0.96 1.00];
            C.muted = [0.62 0.69 0.78];
            C.border = [0.20 0.26 0.35];
            C.accent = [0.15 0.62 0.95];
            C.accent2 = [0.20 0.82 0.78];
        end

        function s = nombre_amigable(~, nombre)
            s = strrep(nombre, '_', ' ');
            if ~isempty(s)
                s(1) = upper(s(1));
            end
        end

        function s = formatear_valor(~, v, paso)
            if paso >= 1 && abs(v - round(v)) < 1e-9
                s = sprintf('%d', round(v));
            elseif paso > 0 && paso < 1
                s = sprintf('%.2f', v);
            else
                if abs(v - round(v)) < 1e-9
                    s = sprintf('%d', round(v));
                else
                    s = sprintf('%.2f', v);
                end
            end
        end

        function s = descripcion_paso(~, paso)
            if paso > 0
                s = sprintf('paso %g', paso);
            else
                s = 'ajuste continuo';
            end
        end
    end
end
