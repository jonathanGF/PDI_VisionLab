function cfg = configuracion()
% Configuración general de PDI VisionLab: cámara, FPS objetivo y métricas.

% Cámara
cfg.camara.backend = 'auto';   % 'auto' (webcam si está instalado, si no OpenCV), 'webcam' u 'opencv'
cfg.camara.indice = 1;         % 1 = primera cámara (webcam usa 1; OpenCV cuenta desde 0 y usa indice - 1)
cfg.camara.resolucion = [640 480];   % [ancho alto]
% El entorno .venv con opencv-python solo hace falta si no está instalado el paquete de webcam
raiz = fileparts(mfilename('fullpath'));
cfg.camara.python = fullfile(raiz, '.venv', 'Scripts', 'python.exe');
cfg.camara.submuestreo_duplicados = 8;   % se compara 1 de cada 8 píxeles para detectar cuadros repetidos

% Exposición: en 'auto' la cámara alarga la exposición con poca luz y baja a 9-15 cuadros únicos/s;
% con -5 entrega ~30 cuadros únicos/s. Brillo y gamma compensan la imagen más oscura
cfg.camara.exposicion = -5;   % 'auto' o un entero (más negativo = exposición más corta)
cfg.camara.brillo = 100;      % solo se aplica con exposición manual
cfg.camara.gamma = 100;       % solo se aplica con exposición manual

% Rendimiento
cfg.fps_objetivo = 20;

% Métricas
cfg.metricas.ventana_s = 1;            % ventana móvil para FPS y promedios (s)
cfg.metricas.carpeta = 'resultados';   % carpeta de los CSV
end
