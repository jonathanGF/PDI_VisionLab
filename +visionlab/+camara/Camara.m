classdef Camara < handle
% Cámara: abre la cámara (webcam de MATLAB u OpenCV a través de Python),
% lee cuadros RGB uint8 y avisa si el cuadro es nuevo o repetido.
% El backend 'sintetica' genera un patrón en movimiento para probar sin cámara.

    properties
        nombre = ''   % texto con el backend y la cámara
    end

    properties (Access = private)
        backend = ''   % 'webcam', 'opencv' o 'sintetica'
        cam = []       % objeto webcam
        cap = []       % objeto VideoCapture de OpenCV
        ancho = 640
        alto = 480
        paso = 8       % submuestreo para comparar cuadros
        muestra = []   % versión submuestreada del cuadro anterior
        k = 0          % contador de lecturas (cámara sintética)
        X = []         % coordenadas de los píxeles (cámara sintética)
        Y = []
    end

    methods
        function abrir(obj, cfg)
            obj.ancho = cfg.camara.resolucion(1);
            obj.alto = cfg.camara.resolucion(2);
            obj.paso = cfg.camara.submuestreo_duplicados;

            obj.backend = cfg.camara.backend;
            switch obj.backend
                case 'auto'
                    % Se usa webcam si el paquete de MATLAB está instalado;
                    % si no está o falla al abrir (p. ej. cámara ocupada) se usa OpenCV
                    obj.backend = 'opencv';
                    if exist('webcam', 'file')
                        try
                            obj.abrir_webcam(cfg);
                            obj.backend = 'webcam';
                        catch err
                            obj.cam = [];
                            warning('Camara:webcam', 'No se pudo usar webcam (%s); se intenta con OpenCV', err.message);
                        end
                    end
                    if strcmp(obj.backend, 'opencv'), obj.abrir_opencv(cfg); end
                case 'webcam'
                    obj.abrir_webcam(cfg);
                case 'opencv'
                    obj.abrir_opencv(cfg);
                case 'sintetica'
                    [obj.X, obj.Y] = meshgrid(1:obj.ancho, 1:obj.alto);
                    obj.nombre = sprintf('sintética @ %dx%d', obj.ancho, obj.alto);
                otherwise
                    error('Camara:abrir', 'Backend de cámara desconocido: %s', obj.backend);
            end
            obj.muestra = [];
        end

        function [rgb, nuevo] = leer(obj)
            switch obj.backend
                case 'webcam'
                    rgb = snapshot(obj.cam);

                case 'opencv'
                    r = obj.cap.read();
                    if ~r{1}
                        error('Camara:leer', 'OpenCV no entregó cuadro');
                    end
                    fr = r{2};                                % arreglo numpy BGR alto x ancho x 3
                    b = uint8(fr.tobytes());                  % bytes -> uint8
                    img = permute(reshape(b, [3 obj.ancho obj.alto]), [3 2 1]);   % a alto x ancho x 3
                    rgb = img(:, :, [3 2 1]);                 % BGR -> RGB

                case 'sintetica'
                    rgb = obj.patron();
            end

            % Es nuevo si la versión submuestreada cambió respecto al cuadro anterior
            s = obj.paso;
            m = rgb(1:s:end, 1:s:end, :);
            nuevo = ~isequal(m, obj.muestra);
            obj.muestra = m;
        end

        function cerrar(obj)
            switch obj.backend
                case 'webcam'
                    obj.cam = [];   % al borrar el objeto se libera la cámara
                case 'opencv'
                    if ~isempty(obj.cap), obj.cap.release(); end
                    obj.cap = [];
            end
        end
    end

    methods (Access = private)
        function abrir_webcam(obj, cfg)
            % MATLAB Support Package for USB Webcams
            obj.cam = webcam(cfg.camara.indice);
            obj.cam.Resolution = sprintf('%dx%d', obj.ancho, obj.alto);

            % Exposición: en 'auto' se deja que la cámara decida y no se tocan brillo ni gamma
            e = cfg.camara.exposicion;
            try
                if strcmpi(e, 'auto')
                    obj.cam.ExposureMode = 'auto';
                else
                    obj.cam.ExposureMode = 'manual';
                    obj.cam.Exposure = e;
                    obj.cam.Brightness = cfg.camara.brillo;
                    obj.cam.Gamma = cfg.camara.gamma;
                end
            catch err
                warning('Camara:exposicion', 'La cámara no aceptó la exposición %s (%s)', num2str(e), err.message);
            end
            for i = 1:10, snapshot(obj.cam); end   % calentamiento (primeros cuadros)
            obj.nombre = ['webcam: ' obj.cam.Name ' @ ' obj.cam.Resolution];
        end

        function abrir_opencv(obj, cfg)
            % Python embebido: solo se cambia el intérprete si no es el configurado
            pe = pyenv;
            actual = strrep(char(pe.Executable), '\', '/');
            if pe.Version == "" || ~strcmpi(actual, strrep(cfg.camara.python, '\', '/'))
                pyenv('Version', cfg.camara.python);
            end
            cv = py.importlib.import_module('cv2');

            % OpenCV cuenta las cámaras desde 0
            obj.cap = cv.VideoCapture(int32(cfg.camara.indice - 1), int32(cv.CAP_MSMF));
            if ~obj.cap.isOpened()
                error('Camara:abrir', 'OpenCV no pudo abrir la cámara %d', cfg.camara.indice - 1);
            end
            obj.cap.set(cv.CAP_PROP_FRAME_WIDTH, obj.ancho);
            obj.cap.set(cv.CAP_PROP_FRAME_HEIGHT, obj.alto);

            % Exposición: 0.25 = manual y 0.75 = automática (convención de OpenCV)
            % Con MSMF la exposición sí cambia (-3 baja a ~8 FPS, -8 oscurece), pero el brillo
            % no tiene efecto visible y get() no regresa los valores nuevos
            e = cfg.camara.exposicion;
            try
                if strcmpi(e, 'auto')
                    obj.cap.set(cv.CAP_PROP_AUTO_EXPOSURE, 0.75);
                else
                    obj.cap.set(cv.CAP_PROP_AUTO_EXPOSURE, 0.25);
                    obj.cap.set(cv.CAP_PROP_EXPOSURE, e);
                    obj.cap.set(cv.CAP_PROP_BRIGHTNESS, cfg.camara.brillo);
                end
            catch err
                warning('Camara:exposicion', 'OpenCV no aceptó la exposición %s (%s)', num2str(e), err.message);
            end

            % Tamaño que de verdad entrega la cámara
            obj.ancho = double(obj.cap.get(cv.CAP_PROP_FRAME_WIDTH));
            obj.alto = double(obj.cap.get(cv.CAP_PROP_FRAME_HEIGHT));
            for i = 1:15, obj.cap.read(); end   % calentamiento (primeros cuadros)
            obj.nombre = sprintf('OpenCV (MSMF): cámara %d @ %dx%d', cfg.camara.indice - 1, obj.ancho, obj.alto);
        end

        function rgb = patron(obj)
            % Patrón que se mueve: franjas diagonales y un círculo que recorre la imagen.
            % Cada cuadro se repite una vez para probar la detección de repetidos.
            obj.k = obj.k + 1;
            f = floor(obj.k / 2);
            R = uint8(mod(obj.X + 6 * f, 256));
            G = uint8(mod(obj.Y + obj.X / 2 - 4 * f, 256));
            cx = obj.ancho / 2 + 0.4 * obj.ancho * cos(f / 10);
            cy = obj.alto / 2 + 0.4 * obj.alto * sin(f / 10);
            B = uint8(255 * ((obj.X - cx).^2 + (obj.Y - cy).^2 < 60^2));
            rgb = cat(3, R, G, B);
        end
    end
end
