function medir_todo()
% Evaluación experimental: tiempo por cuadro de cada operación y barridos de parámetros.
% Escribe resultados/tiempos_operaciones.csv, resultados/barridos.csv y gráficas PNG.

% Carpeta del proyecto (este archivo vive en experimentos/)
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(raiz);
carpeta = fullfile(raiz, 'resultados');
if ~exist(carpeta, 'dir'), mkdir(carpeta); end

%% 1. Dos cuadros reales de la cámara (si falla se usan sintéticos)
cfg = configuracion();
fuente = '';
try
    cam = visionlab.camara.Camara();
    cam.abrir(cfg);
    fuente = cam.nombre;
    rgb1 = cam.leer();
    % Se leen varios cuadros para que el segundo tenga algo de movimiento
    for k = 1:5, rgb2 = cam.leer(); end
    cam.cerrar();
catch err
    fprintf('No se pudo usar la cámara (%s); se usan cuadros sintéticos\n', err.message);
    cfg.camara.backend = 'sintetica';
    cam = visionlab.camara.Camara();
    cam.abrir(cfg);
    fuente = ['SINTÉTICA (falló la cámara: ' err.message ')'];
    rgb1 = cam.leer();
    for k = 1:5, rgb2 = cam.leer(); end
end
g1 = visionlab.camara.a_gris(rgb1);
g2 = visionlab.camara.a_gris(rgb2);
fprintf('Fuente: %s | cuadro %dx%d\n', fuente, size(g1, 2), size(g1, 1));

%% 2. Tiempo de cada operación con sus parámetros iniciales
ops = visionlab.nucleo.registro();
n_ops = numel(ops);
ms_med = zeros(n_ops, 1);
ms_p90 = zeros(n_ops, 1);
texto_p = cell(n_ops, 1);
for i = 1:n_ops
    [p, texto_p{i}] = parametros_iniciales(ops(i));
    if ops(i).movimiento, p.anterior = g1; end
    t = medir(ops(i).funcion, g2, p, 2, 20);
    ms_med(i) = median(t);
    ms_p90(i) = percentil(t, 90);
end
fps_max = 1000 ./ ms_med;

% CSV de tiempos
f = fopen(fullfile(carpeta, 'tiempos_operaciones.csv'), 'w', 'n', 'UTF-8');
fprintf(f, 'operacion,categoria,parametros,ms_mediana,ms_p90,fps_max\n');
for i = 1:n_ops
    fprintf(f, '"%s","%s","%s",%.3f,%.3f,%.1f\n', ops(i).nombre, ops(i).categoria, texto_p{i}, ms_med(i), ms_p90(i), fps_max(i));
end
fclose(f);

%% 3. Barridos de parámetros (mediana de 10 corridas por punto)
% Cada fila: índice en el registro, parámetro que se barre, valores
barr = {7,  'longitud', 3:2:15;
        8,  'longitud', 3:2:11;
        9,  'longitud', 3:2:11;
        5,  'orden',    1:3;
        6,  'niveles',  [2 4 8 16 32 64 128 256];
        10, 'tamano',   3:2:15;
        11, 'tamano',   3:2:15;
        13, 'bloque',   [8 16 24 32];
        13, 'radio',    1:6};
n_b = size(barr, 1);
res_b = cell(n_b, 1);
for b = 1:n_b
    op = ops(barr{b, 1});
    p = parametros_iniciales(op);
    if op.movimiento, p.anterior = g1; end
    vals = barr{b, 3};
    ms = zeros(size(vals));
    for j = 1:numel(vals)
        p.(barr{b, 2}) = vals(j);
        ms(j) = median(medir(op.funcion, g2, p, 1, 10));
    end
    res_b{b} = ms;
end

% CSV de barridos
f = fopen(fullfile(carpeta, 'barridos.csv'), 'w', 'n', 'UTF-8');
fprintf(f, 'operacion,parametro,valor,ms_mediana\n');
for b = 1:n_b
    vals = barr{b, 3};
    for j = 1:numel(vals)
        fprintf(f, '"%s",%s,%g,%.3f\n', ops(barr{b, 1}).nombre, barr{b, 2}, vals(j), res_b{b}(j));
    end
end
fclose(f);

%% 4. Gráficas PNG
% Barras con el tiempo de cada operación y las líneas de 50 ms (20 FPS) y 33 ms (30 FPS)
fig = figure('Visible', 'off', 'Position', [100 100 1100 600]);
bar(ms_med);
hold on;
plot([0 n_ops + 1], [50 50], 'r--', 'LineWidth', 1.5);
plot([0 n_ops + 1], [33.3 33.3], 'm--', 'LineWidth', 1.5);
hold off;
xlim([0 n_ops + 1]);
ylim([0 max(55, 1.1 * max(ms_med))]);
set(gca, 'XTick', 1:n_ops, 'XTickLabel', {ops.nombre}, 'XTickLabelRotation', 40);
ylabel('ms por cuadro (mediana de 20)');
title('Tiempo por operación con parámetros iniciales (640x480)');
legend({'mediana', '50 ms (20 FPS)', '33 ms (30 FPS)'}, 'Location', 'northwest');
grid on;
print(fig, fullfile(carpeta, 'tiempos_operaciones.png'), '-dpng', '-r120');
close(fig);

% Una gráfica por barrido
claves = {'binomial', 'bordes', 'laplaciano', 'bayer', 'cuantizacion', 'erosion', 'dilatacion', 'bm_bloque', 'bm_radio'};
for b = 1:n_b
    fig = figure('Visible', 'off', 'Position', [100 100 700 450]);
    plot(barr{b, 3}, res_b{b}, 'o-', 'LineWidth', 1.5);
    set(gca, 'XTick', barr{b, 3});
    % El eje y empieza en 0 para no exagerar las variaciones pequeñas
    ylim([0 1.15 * max(res_b{b})]);
    % Los niveles van de 2 a 256 en potencias de 2: eje x logarítmico
    if strcmp(barr{b, 2}, 'niveles'), set(gca, 'XScale', 'log'); end
    xlabel(barr{b, 2});
    ylabel('ms por cuadro (mediana de 10)');
    title(sprintf('%s: barrido de %s', ops(barr{b, 1}).nombre, barr{b, 2}));
    grid on;
    print(fig, fullfile(carpeta, ['barrido_' claves{b} '.png']), '-dpng', '-r120');
    close(fig);
end

%% 5. Tablas en consola
fprintf('\n%-34s %-26s %-22s %9s %9s %9s\n', 'Operación', 'Categoría', 'Parámetros', 'ms med', 'ms p90', 'FPS máx');
for i = 1:n_ops
    fprintf('%-34s %-26s %-22s %9.2f %9.2f %9.1f\n', ops(i).nombre, ops(i).categoria, texto_p{i}, ms_med(i), ms_p90(i), fps_max(i));
end
fprintf('\nBarridos (ms mediana de 10 corridas)\n');
for b = 1:n_b
    fprintf('%s, %s:', ops(barr{b, 1}).nombre, barr{b, 2});
    fprintf(' %g->%.2f', [barr{b, 3}; res_b{b}]);
    fprintf('\n');
end
fprintf('\nArchivos en %s\n', carpeta);
end

function [p, texto] = parametros_iniciales(op)
% Struct con el valor inicial de cada parámetro y un texto para la tabla
p = struct();
partes = cell(1, numel(op.parametros));
for k = 1:numel(op.parametros)
    p.(op.parametros(k).nombre) = op.parametros(k).inicial;
    partes{k} = sprintf('%s=%g', op.parametros(k).nombre, op.parametros(k).inicial);
end
texto = strjoin(partes, '; ');
if isempty(texto), texto = '-'; end
end

function t = medir(fun, img, p, n_cal, n)
% Corridas de calentamiento sin medir y luego n corridas medidas en ms
for k = 1:n_cal, fun(img, p); end
t = zeros(n, 1);
for k = 1:n
    a = tic;
    fun(img, p);
    t(k) = 1000 * toc(a);
end
end

function v = percentil(t, q)
% Percentil por interpolación lineal sobre los datos ordenados
s = sort(t(:));
pos = 1 + (numel(s) - 1) * q / 100;
v = interp1(1:numel(s), s, pos);
end
