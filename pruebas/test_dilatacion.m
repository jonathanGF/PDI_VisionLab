function test_dilatacion()
% Prueba de la dilatación con imágenes pequeñas de resultado conocido.

%% Un punto blanco en el centro se convierte en un cuadrado de n x n
img = zeros(7, 7, 'uint8');
img(4, 4) = 200;
p.tamano = 3;
s = visionlab.algoritmos.morfologia.dilatacion(img, p);
assert(isa(s, 'uint8'), 'La salida debe ser uint8');
assert(isequal(size(s), size(img)), 'La salida debe tener el mismo tamaño');
esperado = zeros(7, 7, 'uint8');
esperado(3:5, 3:5) = 200;
assert(isequal(s, esperado), 'El punto con n = 3 debe crecer a un cuadrado de 3x3');

% Con n = 5 el cuadrado es de 5x5
p.tamano = 5;
s = visionlab.algoritmos.morfologia.dilatacion(img, p);
esperado = zeros(7, 7, 'uint8');
esperado(2:6, 2:6) = 200;
assert(isequal(s, esperado), 'El punto con n = 5 debe crecer a un cuadrado de 5x5');

%% Si llega un tamaño par se usa el siguiente impar (4 -> 5)
p.tamano = 4;
s4 = visionlab.algoritmos.morfologia.dilatacion(img, p);
assert(isequal(s4, s), 'Con tamaño 4 debe comportarse igual que con 5');

%% Dos puntos de distinto valor: donde se traslapan gana el mayor
img = zeros(5, 6, 'uint8');
img(3, 2) = 50;
img(3, 4) = 120;
p.tamano = 3;
s = visionlab.algoritmos.morfologia.dilatacion(img, p);
esperado = zeros(5, 6, 'uint8');
esperado(2:4, 1:3) = 50;
esperado(2:4, 3:5) = 120;
assert(isequal(s, esperado), 'En el traslape debe quedar el máximo (120)');

%% Una imagen constante no cambia, ni siquiera en la orilla
img = 90 * ones(6, 8, 'uint8');
p.tamano = 7;
s = visionlab.algoritmos.morfologia.dilatacion(img, p);
assert(isequal(s, img), 'Una imagen constante debe quedar igual');

%% Un escalón se recorre r píxeles hacia lo oscuro
img = zeros(4, 10, 'uint8');
img(:, 6:10) = 255;
p.tamano = 5;
s = visionlab.algoritmos.morfologia.dilatacion(img, p);
esperado = zeros(4, 10, 'uint8');
esperado(:, 4:10) = 255;
assert(isequal(s, esperado), 'El escalón debe avanzar 2 píxeles con n = 5');

%% La dilatación nunca baja el valor de un píxel
rand('seed', 2);
A = uint8(floor(rand(48, 64) * 256));
p.tamano = 9;
s = visionlab.algoritmos.morfologia.dilatacion(A, p);
assert(all(s(:) >= A(:)), 'La salida debe ser mayor o igual que la entrada');

%% Contra el máximo calculado píxel por píxel con dos ciclos, para todos los tamaños
A = uint8(floor(rand(20, 25) * 256));
[M, N] = size(A);
for n = 3:2:15
    p.tamano = n;
    s = visionlab.algoritmos.morfologia.dilatacion(A, p);
    r = (n - 1) / 2;
    directo = zeros(M, N, 'uint8');
    for y = 1:M
        for x = 1:N
            ventana = A(max(1, y-r):min(M, y+r), max(1, x-r):min(N, x+r));
            directo(y, x) = max(ventana(:));
        end
    end
    assert(isequal(s, directo), sprintf('Con n = %d no coincide con el cálculo con ciclos', n));
end

%% Una imagen más chica que la ventana toma el máximo global
img = uint8([10 40; 30 20]);
p.tamano = 15;
s = visionlab.algoritmos.morfologia.dilatacion(img, p);
assert(all(s(:) == 40), 'Con ventana más grande que la imagen todo debe valer el máximo');

%% Entrada logical: la salida también es logical
b = false(7, 7);
b(4, 4) = true;
b(1, 7) = true;
p.tamano = 3;
s = visionlab.algoritmos.morfologia.dilatacion(b, p);
assert(islogical(s), 'Con entrada logical la salida debe ser logical');
esperado = false(7, 7);
esperado(3:5, 3:5) = true;
esperado(1:2, 6:7) = true;
assert(isequal(s, esperado), 'El punto binario debe crecer a 3x3 y el de la esquina a 2x2');

%% Comparación con imdilate en el interior (solo si existe en esta instalación)
A = uint8(floor(rand(60, 80) * 256));
try
    for n = 3:2:15
        p.tamano = n;
        s = visionlab.algoritmos.morfologia.dilatacion(A, p);
        ref = imdilate(A, ones(n));
        r = (n - 1) / 2;
        assert(isequal(s(r+1:end-r, r+1:end-r), ref(r+1:end-r, r+1:end-r)), ...
            sprintf('Con n = %d no coincide con imdilate en el interior', n));
    end
    disp('Comparación con imdilate: OK');
catch err
    if exist('imdilate', 'file')
        rethrow(err);
    end
    disp('imdilate no está disponible, se omite la comparación');
end

disp('OK test_dilatacion');
end
