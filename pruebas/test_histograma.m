function test_histograma()
% Prueba del histograma dinámico con imágenes pequeñas.
% Se corre desde la raíz del repo y al final imprime "OK test_histograma".

p = struct();

% Imagen constante de 40x512: una sola barra de altura completa
C = uint8(100 * ones(40, 512));
S = visionlab.algoritmos.adicionales.histograma(C, p);
assert(isa(S, 'uint8'), 'La salida debe ser uint8');
assert(isequal(size(S), size(C)), 'La salida debe tener el tamaño de la entrada');
assert(all(S(:) == 0 | S(:) == 255), 'La salida solo debe tener 0 y 255');
% Con 512 columnas cada nivel ocupa 2 columnas: el nivel 100 queda en las columnas 201 y 202
esperada = zeros(40, 512, 'uint8');
esperada(:, 201:202) = 255;
assert(isequal(S, esperada), 'La imagen constante debe dar una sola barra completa');

% Mitad 0 y mitad 255 en 30x640: dos barras de igual altura en los extremos
D = zeros(30, 640, 'uint8');
D(:, 321:end) = 255;
S = visionlab.algoritmos.adicionales.histograma(D, p);
alto_col = sum(S == 255, 1);
% Con 640 columnas el nivel 0 queda en las columnas 1 a 3 y el nivel 255 en la 639 y 640
assert(all(alto_col([1:3 639:640]) == 30), 'Las barras de los extremos deben ser completas');
assert(all(alto_col(4:638) == 0), 'No debe haber más barras que las de los extremos');
assert(all(S(:, 1) == 255) && all(S(:, 640) == 255), 'Las barras deben llegar de abajo hasta arriba');

% Caso a mano 10x256: nivel 0 con 1280 píxeles, nivel 1 con 640 y nivel 2 con 640
A = zeros(10, 256, 'uint8');
A(:, 129:192) = 1;
A(:, 193:256) = 2;
S = visionlab.algoritmos.adicionales.histograma(A, p);
alto_col = sum(S == 255, 1);
% Alturas: 10, 5 y 5 (mitad del máximo); las demás columnas vacías
assert(isequal(alto_col(1:3), [10 5 5]), 'Las alturas no coinciden con el caso a mano');
assert(all(alto_col(4:end) == 0), 'Los niveles vacíos no deben tener barra');
% La barra de altura 5 ocupa las 5 filas de abajo
assert(all(S(6:10, 2) == 255) && all(S(1:5, 2) == 0), 'La barra debe crecer desde el borde inferior');

% Imagen angosta (8x64): varias barras por columna, se ve la más alta
B = uint8(repmat(0:4:252, 8, 1));
S = visionlab.algoritmos.adicionales.histograma(B, p);
assert(isequal(size(S), [8 64]), 'La salida angosta debe tener el tamaño de la entrada');
assert(all(S(:) == 255), 'Con 64 niveles de igual frecuencia todas las columnas deben ser completas');

% Comparación contra imhist de IPT si existe: la altura de cada columna sale del mismo conteo
[x, y] = meshgrid(1:300, 1:120);
R = uint8(mod(3 * x + 2 * y + round(20 * sin(x / 9)), 256));
S = visionlab.algoritmos.adicionales.histograma(R, p);
if exist('imhist', 'file')
    h_ref = imhist(R, 256);
    alt_ref = round(120 * h_ref / max(h_ref));
    barra = floor((0:299) * 256 / 300) + 1;
    assert(isequal(sum(S == 255, 1), alt_ref(barra)'), 'Las alturas no coinciden con imhist');
    disp('imhist: las alturas de las barras coinciden');
else
    disp('imhist no está disponible: se omite la comparación');
end

disp('OK test_histograma');
end
