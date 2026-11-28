function calidad_visual()
% Calidad visual: aplica cada operación a un mismo cuadro con varios valores del parámetro,
% guarda un mosaico PNG por operación y calcula el MSE y el PSNR contra el cuadro original.
% Escribe recursos/imagenes_prueba/cuadro_prueba.png y documentacion/experimentos/figuras/.

% Carpetas del proyecto (este archivo vive en experimentos/)
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(raiz);
carpeta = fullfile(raiz, 'documentacion', 'experimentos', 'figuras');
if ~exist(carpeta, 'dir'), mkdir(carpeta); end

%% 1. Imagen de prueba estándar (peppers.png de Image Processing Toolbox)
% Se usa una imagen estándar y no un cuadro de la cámara para que el experimento
% sea reproducible en cualquier equipo. peppers.png mide 384x512 (proporción 3:4),
% así que se amplía a 480x640 sin deformarla. Si no está disponible, se usa un cuadro sintético.
cfg = configuracion();
try
    rgb = imresize(imread('peppers.png'), [480 640], 'bicubic');
    fuente = 'peppers.png (IPT) ampliada a 640x480';
catch err
    fprintf('No se pudo leer peppers.png (%s); se usa un cuadro sintético\n', err.message);
    cfg.camara.backend = 'sintetica';
    cam = visionlab.camara.Camara();
    cam.abrir(cfg);
    fuente = ['SINTÉTICA (' err.message ')'];
    rgb = cam.leer();
end
gris = visionlab.camara.a_gris(rgb);
imwrite(gris, fullfile(raiz, 'recursos', 'imagenes_prueba', 'cuadro_prueba.png'));
fprintf('Fuente: %s | cuadro %dx%d | gris de %d a %d, media %.1f\n', fuente, size(gris, 2), size(gris, 1), ...
    min(gris(:)), max(gris(:)), mean(double(gris(:))));

%% 2. Operaciones y valores a probar
% Cada fila: archivo, función, parámetro, valores, parámetros fijos y si se calcula el PSNR
casos = {'bayer',        @visionlab.algoritmos.tramado.bayer,             'orden',    [1 2 3],         struct(),                true;
         'cuantizacion', @visionlab.algoritmos.tramado.cuantizacion,      'niveles',  [2 4 8 32],      struct(),                true;
         'binomial',     @visionlab.algoritmos.filtrado.binomial,         'longitud', [3 7 15],        struct(),                true;
         'bordes_u0',    @visionlab.algoritmos.filtrado.bordes_binomial,  'longitud', [3 7],           struct('umbral', 0),     false;
         'bordes_u60',   @visionlab.algoritmos.filtrado.bordes_binomial,  'longitud', [3 7],           struct('umbral', 60),    false;
         'laplaciano',   @visionlab.algoritmos.filtrado.laplaciano,       'longitud', [3 7],           struct(),                false;
         'erosion',      @visionlab.algoritmos.morfologia.erosion,        'tamano',   [3 7 15],        struct(),                false;
         'dilatacion',   @visionlab.algoritmos.morfologia.dilatacion,     'tamano',   [3 7 15],        struct(),                false;
         'gamma',        @visionlab.algoritmos.niveles_gris.gamma,        'gamma',    [0.5 1 2],       struct(),                false;
         'umbral',       @visionlab.algoritmos.niveles_gris.umbral,       'umbral',   [64 128 192],    struct(),                false};

%% 3. Mosaicos y PSNR
filas_csv = cell(0, 5);
for c = 1:size(casos, 1)
    [clave, fun, nombre_p, vals, p, con_psnr] = casos{c, :};

    % El original va primero para comparar; luego una salida por valor
    mosaico = gris;
    etiquetas = {'original'};
    for j = 1:numel(vals)
        p.(nombre_p) = vals(j);
        salida = fun(gris, p);
        % Las salidas binarias se pasan a 0/255 igual que en el despliegue
        img = visionlab.nucleo.Pipeline.a_despliegue(salida);

        % Una franja blanca de 8 px separa cada imagen
        mosaico = horzcat(mosaico, 255 * ones(size(gris, 1), 8, 'uint8'), img);
        etiquetas{end + 1} = sprintf('%s = %g', nombre_p, vals(j));

        if con_psnr
            [mse, ps] = psnr_propio(gris, img);
            filas_csv(end + 1, :) = {clave, nombre_p, vals(j), mse, ps};
        end
    end

    % Nombre del archivo con los valores, p. ej. mosaico_bayer_orden_1_2_3.png
    txt_vals = strjoin(arrayfun(@(v) strrep(sprintf('%g', v), '.', 'p'), vals, 'UniformOutput', false), '_');
    archivo = sprintf('mosaico_%s_%s_%s.png', clave, nombre_p, txt_vals);
    titulo = strjoin(etiquetas, '   |   ');
    if isfield(p, 'umbral') && ~strcmp(nombre_p, 'umbral')
        titulo = sprintf('umbral = %g:   %s', p.umbral, titulo);
    end
    guardar_mosaico(mosaico, titulo, fullfile(carpeta, archivo));
    fprintf('Mosaico: %s\n', archivo);
end

%% 4. CSV y tabla de PSNR
f = fopen(fullfile(carpeta, 'calidad.csv'), 'w', 'n', 'UTF-8');
fprintf(f, 'operacion,parametro,valor,mse,psnr\n');
for i = 1:size(filas_csv, 1)
    fprintf(f, '%s,%s,%g,%.2f,%.2f\n', filas_csv{i, :});
end
fclose(f);

fprintf('\n%-14s %-10s %6s %10s %9s\n', 'operación', 'parámetro', 'valor', 'MSE', 'PSNR dB');
for i = 1:size(filas_csv, 1)
    fprintf('%-14s %-10s %6g %10.2f %9.2f\n', filas_csv{i, :});
end
fprintf('\nArchivos en %s\n', carpeta);
end

function [mse, ps] = psnr_propio(a, b)
% Error cuadrático medio y PSNR para imágenes de 8 bits (pico 255)
mse = mean((double(a(:)) - double(b(:))).^2);
ps = 10 * log10(255^2 / mse);
end

function guardar_mosaico(mosaico, titulo, archivo)
% Figura invisible con el mosaico en gris y el título con los valores del parámetro.
% El tamaño en pulgadas es píxeles/100 y se imprime a 100 dpi: cada píxel del mosaico
% queda como un píxel del PNG y el tramado de Bayer no se deforma al reescalar
[alto, ancho] = size(mosaico);
margen = 40;   % espacio arriba para el título (px)
fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'inches', ...
    'Position', [0 0 ancho / 100 (alto + margen) / 100]);
% image con las tres capas iguales evita depender del mapa de color
image(repmat(mosaico, 1, 1, 3));
axis image off;
set(gca, 'Units', 'normalized', 'Position', [0 0 1 alto / (alto + margen)]);
title(titulo, 'Interpreter', 'none', 'FontSize', 14);
set(fig, 'PaperUnits', 'inches', 'PaperPosition', [0 0 ancho / 100 (alto + margen) / 100]);
print(fig, archivo, '-dpng', '-r100');
close(fig);
end
