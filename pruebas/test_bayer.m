function test_bayer()
% Prueba del dithering de Bayer con imágenes pequeñas de resultado conocido.

% Matriz 4x4 de la práctica 2
M4 = [ 0,  8,  2, 10;
      12,  4, 14,  6;
       3, 11,  1,  9;
      15,  7, 13,  5];

% Para cada orden se busca el primer nivel de gris en que se enciende cada píxel;
% el orden en que se encienden debe reproducir la matriz de Bayer
for orden = 1:3
    n = 2^orden;
    p.orden = orden;
    primer = 256 * ones(n);
    for g = 255:-1:0
        S = visionlab.algoritmos.tramado.bayer(uint8(g * ones(n)), p);
        primer(S) = g;
    end
    [~, idx] = sort(primer(:));
    rango = zeros(n);
    rango(idx) = 0:n^2 - 1;
    if orden == 1
        assert(isequal(rango, [0 2; 3 1]));
    elseif orden == 2
        assert(isequal(rango, M4));
    else
        % La 8x8 debe contener cada valor de 0 a 63 una sola vez
        assert(isequal(sort(rango(:))', 0:63));
        assert(isequal(rango(1:2, 1:2), [0 32; 48 16]));
    end
end

% Caso hecho a mano: gris 128 con 4x4 enciende los 8 umbrales con M <= 7
p.orden = 2;
S = visionlab.algoritmos.tramado.bayer(uint8(128 * ones(4)), p);
assert(islogical(S));
assert(isequal(S, M4 <= 7));

% Caso hecho a mano: gris 64 con 2x2 enciende solo el umbral de M = 0
p.orden = 1;
S = visionlab.algoritmos.tramado.bayer(uint8(64 * ones(2)), p);
assert(isequal(S, logical([1 0; 0 0])));

% Negro queda todo en 0 y blanco todo en 1
for orden = 1:3
    p.orden = orden;
    assert(~any(any(visionlab.algoritmos.tramado.bayer(uint8(zeros(9, 13)), p))));
    assert(all(all(visionlab.algoritmos.tramado.bayer(uint8(255 * ones(9, 13)), p))));
end

% Tamaño no múltiplo del patrón: la salida conserva el tamaño de la entrada
p.orden = 3;
S = visionlab.algoritmos.tramado.bayer(uint8(randi([0 255], 5, 7)), p);
assert(isequal(size(S), [5 7]));

% Comparación contra el código de la práctica 2 (Bayer 2x2 y 4x4)
I = uint8(randi([0 255], 37, 50));
Id = double(I) / 255;
[H, W] = size(Id);
T2 = ([0 2; 3 1] + 0.5) / 4;
patron_2x2 = repmat(T2, ceil(H/2), ceil(W/2));
p.orden = 1;
assert(isequal(visionlab.algoritmos.tramado.bayer(I, p), Id >= patron_2x2(1:H, 1:W)));
T4 = (M4 + 0.5) / 16;
patron_4x4 = repmat(T4, ceil(H/4), ceil(W/4));
p.orden = 2;
assert(isequal(visionlab.algoritmos.tramado.bayer(I, p), Id >= patron_4x4(1:H, 1:W)));

% La función dither del toolbox usa difusión de error, no Bayer, así que no sirve de referencia
disp('dither no es Bayer ordenado, no se compara contra el toolbox');

disp('OK test_bayer');
end
