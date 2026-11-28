classdef Ventana < handle
% Ventana: figura con el video original y el procesado, menú de operaciones,
% deslizadores generados desde el registro, texto de FPS/ms y botón Salir.
% Los controles solo escriben en Estado; el lazo principal nunca se detiene.

    properties
        fig            % figura
        estado         % Estado compartido
        ops            % registro de operaciones
        orden          % orden del menú (agrupado por categoría) -> índice en ops
        img_orig       % image del original
        img_proc       % image del procesado
        menu           % popupmenu de operaciones
        info           % texto con FPS y ms
        controles = gobjects(0)   % deslizadores y etiquetas de la operación activa
    end

    methods
        function obj = Ventana(ops, estado, titulo)
            obj.ops = ops;
            obj.estado = estado;

            % Figura clásica (más rápida para video que uifigure)
            obj.fig = figure('Name', ['PDI VisionLab - ' titulo], 'NumberTitle', 'off', ...
                'Color', 'w', 'Position', [60 60 1300 680], 'MenuBar', 'none', ...
                'DeleteFcn', @(~, ~) obj.al_cerrar());

            % Ejes: original (RGB) y procesado (gris con colormap o RGB)
            ax1 = axes(obj.fig, 'Position', [0.01 0.30 0.48 0.66]);
            obj.img_orig = image(ax1, zeros(480, 640, 3, 'uint8'));
            axis(ax1, 'image', 'off'); title(ax1, 'Original');
            ax2 = axes(obj.fig, 'Position', [0.51 0.30 0.48 0.66]);
            obj.img_proc = image(ax2, zeros(480, 640, 'uint8'), 'CDataMapping', 'direct');
            colormap(ax2, gray(256));
            axis(ax2, 'image', 'off'); title(ax2, 'Procesado');

            % Menú con las operaciones agrupadas por categoría ('Categoría: Nombre')
            [~, ~, g] = unique({ops.categoria}, 'stable');
            [~, obj.orden] = sort(g);
            textos = strcat({ops(obj.orden).categoria}, {': '}, {ops(obj.orden).nombre});
            obj.menu = uicontrol(obj.fig, 'Style', 'popupmenu', 'String', textos, ...
                'Units', 'normalized', 'Position', [0.01 0.21 0.30 0.05], 'FontSize', 10, ...
                'Value', find(obj.orden == estado.op), 'Callback', @(src, ~) obj.al_elegir(src));

            % Texto de FPS y ms por etapa
            obj.info = uicontrol(obj.fig, 'Style', 'text', 'String', '', 'Units', 'normalized', ...
                'Position', [0.33 0.20 0.55 0.06], 'FontSize', 10, ...
                'HorizontalAlignment', 'left', 'BackgroundColor', 'w');

            % Botón Salir: borra la figura y eso detiene el lazo
            uicontrol(obj.fig, 'Style', 'pushbutton', 'String', 'Salir', 'Units', 'normalized', ...
                'Position', [0.89 0.21 0.10 0.05], 'FontSize', 10, 'Callback', @(~, ~) delete(obj.fig));

            obj.crear_deslizadores();
            drawnow;
        end

        function mostrar(obj, rgb, salida)
            set(obj.img_orig, 'CData', rgb);
            set(obj.img_proc, 'CData', salida);
        end

        function texto(obj, cadena)
            set(obj.info, 'String', cadena);
        end

        function si = abierta(obj)
            si = isvalid(obj.fig) && obj.estado.corriendo;
        end

        function cerrar(obj)
            if isvalid(obj.fig), delete(obj.fig); end
        end
    end

    methods (Access = private)
        function al_cerrar(obj)
            % Cerrar con la X o con Salir detiene el lazo principal
            obj.estado.corriendo = false;
        end

        function al_elegir(obj, src)
            % Cambio de operación: valores iniciales y deslizadores nuevos
            obj.estado.cambiar_operacion(obj.orden(get(src, 'Value')), obj.ops);
            obj.crear_deslizadores();
        end

        function crear_deslizadores(obj)
            % Se borran los de la operación anterior
            delete(obj.controles(isvalid(obj.controles)));
            obj.controles = gobjects(0);

            % Un deslizador por parámetro, en renglones debajo del menú
            par = obj.ops(obj.estado.op).parametros;
            alto = min(0.05, 0.18 / max(1, numel(par)));
            for i = 1:numel(par)
                y = 0.19 - i * alto;
                rango = par(i).max - par(i).min;
                if par(i).paso > 0
                    pasos = [par(i).paso, max(par(i).paso, 0.1 * rango)] / rango;
                else
                    pasos = [0.01 0.1];
                end
                etiqueta = uicontrol(obj.fig, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.01 y 0.20 0.8 * alto], 'FontSize', 10, ...
                    'HorizontalAlignment', 'left', 'BackgroundColor', 'w', ...
                    'String', sprintf('%s = %g', par(i).nombre, par(i).inicial));
                barra = uicontrol(obj.fig, 'Style', 'slider', 'Units', 'normalized', ...
                    'Position', [0.22 y 0.66 0.8 * alto], 'Min', par(i).min, 'Max', par(i).max, ...
                    'Value', par(i).inicial, 'SliderStep', min(pasos, 1));
                barra.Callback = @(src, ~) obj.al_mover(src, par(i), etiqueta);
                % Así el parámetro cambia mientras se arrastra, no solo al soltar
                addlistener(barra, 'ContinuousValueChange', @(src, ~) obj.al_mover(src, par(i), etiqueta));
                obj.controles(end + 1) = etiqueta;
                obj.controles(end + 1) = barra;
            end
        end

        function al_mover(obj, src, par, etiqueta)
            % Con paso > 0 se redondea a múltiplos de paso desde min
            v = get(src, 'Value');
            if par.paso > 0
                v = par.min + round((v - par.min) / par.paso) * par.paso;
                v = min(max(v, par.min), par.max);
                set(src, 'Value', v);
            end
            obj.estado.p.(par.nombre) = v;
            set(etiqueta, 'String', sprintf('%s = %g', par.nombre, v));
        end
    end
end
