function test_bordes_binomial()
% Prueba de bordes por binomial de orden 1 con imágenes sintéticas de resultado conocido.

op = @visionlab.algoritmos.filtrado.bordes_binomial;

% Impulso en el centro con N = 3: s = [1 2 1]/4 y d = [1 0 -1]
% |gx| + |gy| da 0.5 en los 8 vecinos y 0 en el centro, así que los vecinos quedan en 255
I = zeros(7, 7, 'uint8');
I(4, 4) = 255;
p.longitud = 3;
p.umbral = 0;
S = op(I, p);
assert(isa(S, 'uint8'));
assert(isequal(size(S), size(I)));
esperado = zeros(7, 7, 'uint8');
esperado(3:5, 3:5) = 255;
esperado(4, 4) = 0;
assert(isequal(S, esperado));

% Escalón vertical: columnas 1-10 en 0 y columnas 11-20 en 200
% Con bordes replicados el marco ya no responde, así que se revisan todas las filas
I = zeros(20, 20, 'uint8');
I(:, 11:20) = 200;
filas = 1:20;

% Con N = 3 (d = [1 0 -1]) solo responden las columnas 10 y 11, con el mismo valor (el máximo)
S = double(op(I, p));
borde = S(filas, 10:11);
assert(all(borde(:) == borde(1)) && borde(1) == 255);
assert(all(all(S(filas, [1:9 12:20]) == 0)));

% Con N = 5 (d = [1 2 0 -2 -1]) da 600 en las columnas 10 y 11 y 200 en la 9 y la 12
p.longitud = 5;
S = double(op(I, p));
borde = S(filas, 10:11);
lado = S(filas, [9 12]);
assert(all(borde(:) == borde(1)) && borde(1) == 255);
assert(all(abs(lado(:) - borde(1) / 3) <= 1));
assert(all(all(S(filas, [1:8 13:20]) == 0)));

% La respuesta máxima de toda la imagen está en las columnas del borde
assert(max(S(:)) == borde(1));

% Si llega una longitud par se usa la siguiente impar (4 -> 5)
p.longitud = 4;
assert(isequal(double(op(I, p)), S));

% Simetría: trasponer la entrada debe trasponer la salida
assert(isequal(op(I', p), op(I, p)'));
J = uint8(randi([0 255], 15, 22));
p.longitud = 7;
assert(isequal(op(J', p), op(J, p)'));

% Con umbral igual al valor del borde solo quedan las columnas 10 y 11
p.longitud = 5;
p.umbral = borde(1);
B = op(I, p);
assert(islogical(B));
assert(all(all(B(filas, 10:11))));
assert(~any(any(B(filas, [1:9 12:20]))));

% Imagen plana: cero en todas partes (orillas incluidas), y una imagen negra no tiene bordes en ningún caso
P = 100 * ones(10, 10, 'uint8');
p.umbral = 0;
for N = 3:2:11
    p.longitud = N;
    S = op(P, p);
    assert(isa(S, 'uint8') && all(S(:) == 0));
end
p.longitud = 3;
Z = op(zeros(8, 8, 'uint8'), p);
assert(isa(Z, 'uint8') && all(Z(:) == 0));
p.umbral = 10;
Z = op(zeros(8, 8, 'uint8'), p);
assert(islogical(Z) && ~any(Z(:)));

% Comparación con conv2 2D sobre la imagen ampliada con repmat
p.longitud = 5;
p.umbral = 0;
S = op(J, p);
s = [1 4 6 4 1] / 16;
d = [1 2 0 -2 -1];
f = double(J);
f = [repmat(f(1, :), 2, 1); f; repmat(f(end, :), 2, 1)];
f = [repmat(f(:, 1), 1, 2), f, repmat(f(:, end), 1, 2)];
gx = conv2(f, s(:) * d, 'valid');
gy = conv2(f, d(:) * s, 'valid');
mag = abs(gx) + abs(gy);
ref = uint8(255 * mag / max(mag(:)));
assert(max(abs(double(S(:)) - double(ref(:)))) <= 1);

% Comparación con imfilter si existe (convolución con bordes replicados)
if exist('imfilter', 'file')
    f = double(J);
    gx = imfilter(f, s(:) * d, 'conv', 'replicate', 'same');
    gy = imfilter(f, d(:) * s, 'conv', 'replicate', 'same');
    mag = abs(gx) + abs(gy);
    ref = uint8(255 * mag / max(mag(:)));
    assert(max(abs(double(S(:)) - double(ref(:)))) <= 1);
else
    disp('imfilter no disponible, se omite la comparación');
end

disp('OK test_bordes_binomial');
end
