function test_erosion()
% Prueba de la erosión con imágenes pequeñas de resultado conocido.

%% Un cuadro blanco de 5x5 erosionado con 3x3 se reduce a 3x3
img = zeros(9, 9, 'uint8');
img(3:7, 3:7) = 255;
p.tamano = 3;
s = visionlab.algoritmos.morfologia.erosion(img, p);
assert(isa(s, 'uint8'), 'La salida debe ser uint8');
assert(isequal(size(s), size(img)), 'La salida debe tener el mismo tamaño');
esperado = zeros(9, 9, 'uint8');
esperado(4:6, 4:6) = 255;
assert(isequal(s, esperado), 'El cuadro 5x5 con n = 3 debe quedar de 3x3');

%% Con n = 5 el mismo cuadro queda en un solo píxel
p.tamano = 5;
s = visionlab.algoritmos.morfologia.erosion(img, p);
esperado = zeros(9, 9, 'uint8');
esperado(5, 5) = 255;
assert(isequal(s, esperado), 'El cuadro 5x5 con n = 5 debe quedar en un píxel');

%% Un píxel oscuro en fondo blanco crece a un bloque de n x n
img = 255 * ones(9, 9, 'uint8');
img(5, 5) = 0;
p.tamano = 3;
s = visionlab.algoritmos.morfologia.erosion(img, p);
esperado = 255 * ones(9, 9, 'uint8');
esperado(4:6, 4:6) = 0;
assert(isequal(s, esperado), 'El píxel oscuro debe crecer a 3x3');

%% Si llega un tamaño par se usa el siguiente impar (4 -> 5)
p.tamano = 4;
s4 = visionlab.algoritmos.morfologia.erosion(img, p);
p.tamano = 5;
s5 = visionlab.algoritmos.morfologia.erosion(img, p);
assert(isequal(s4, s5), 'Con tamaño 4 debe comportarse igual que con 5');

%% Rampa creciente: con replicación cada píxel toma el vecino de arriba a la izquierda
img = uint8([10 20 30; 40 50 60; 70 80 90]);
p.tamano = 3;
s = visionlab.algoritmos.morfologia.erosion(img, p);
esperado = uint8([10 10 20; 10 10 20; 40 40 50]);
assert(isequal(s, esperado), 'La rampa no coincide con el cálculo a mano');

%% Imagen constante: no cambia, ni siquiera en el borde (relleno por replicación)
img = 100 * ones(6, 8, 'uint8');
p.tamano = 5;
s = visionlab.algoritmos.morfologia.erosion(img, p);
assert(isequal(s, img), 'Una imagen constante no debe cambiar');

%% Ventana más grande que la imagen: todo queda en el mínimo global
img = uint8([50 60 70; 80 40 90]);
p.tamano = 15;
s = visionlab.algoritmos.morfologia.erosion(img, p);
assert(isequal(s, 40 * ones(2, 3, 'uint8')), 'Con ventana grande todo debe valer el mínimo');

%% Entrada logical: la salida también es logical
b = false(7, 7);
b(2:6, 2:6) = true;
p.tamano = 3;
s = visionlab.algoritmos.morfologia.erosion(b, p);
assert(islogical(s), 'Con entrada logical la salida debe ser logical');
esperado = false(7, 7);
esperado(3:5, 3:5) = true;
assert(isequal(s, esperado), 'El cuadro binario 5x5 debe quedar de 3x3');

%% Separable contra el mínimo 2D directo sobre la vecindad, para todos los tamaños
rand('seed', 1);
A = uint8(floor(rand(30, 40) * 256));
[M, N] = size(A);
for n = 3:2:15
    p.tamano = n;
    s = visionlab.algoritmos.morfologia.erosion(A, p);
    r = (n - 1) / 2;
    directo = zeros(M, N, 'uint8');
    for i = 1:M
        for j = 1:N
            fi = max(i-r, 1):min(i+r, M);
            cj = max(j-r, 1):min(j+r, N);
            directo(i, j) = min(min(A(fi, cj)));
        end
    end
    assert(isequal(s, directo), sprintf('Con n = %d el separable no coincide con el mínimo directo', n));
end

%% Comparación con imerode en el interior (solo si existe en esta instalación)
try
    A = uint8(floor(rand(48, 64) * 256));
    B = rand(48, 64) > 0.3;
    for n = 3:2:15
        p.tamano = n;
        r = floor(n / 2);
        s = visionlab.algoritmos.morfologia.erosion(A, p);
        ref = imerode(A, ones(n));
        assert(isequal(s(r+1:end-r, r+1:end-r), ref(r+1:end-r, r+1:end-r)), sprintf('No coincide con imerode (uint8, n = %d)', n));
        s = visionlab.algoritmos.morfologia.erosion(B, p);
        ref = imerode(B, ones(n));
        assert(isequal(s(r+1:end-r, r+1:end-r), ref(r+1:end-r, r+1:end-r)), sprintf('No coincide con imerode (logical, n = %d)', n));
    end
    disp('Comparación con imerode: OK');
catch err
    if exist('imerode', 'file')
        rethrow(err);
    end
    disp('imerode no está disponible, se omite la comparación');
end

disp('OK test_erosion');
end
