function test_laplaciano()
% Prueba del laplaciano binomial de orden 2 con imágenes sintéticas de resultado conocido.

op = @visionlab.algoritmos.filtrado.laplaciano;

% Con N = 3 debe ser igual al laplaciano clásico [0 1 0; 1 -4 1; 0 1 0] sobre la imagen ampliada
J = uint8(randi([0 255], 15, 22));
p.longitud = 3;
S = op(J, p);
assert(isa(S, 'uint8'));
assert(isequal(size(S), size(J)));
f = double(J);
fp = [f(1, :); f; f(end, :)];
fp = [fp(:, 1), fp, fp(:, end)];
ref = abs(conv2(fp, [0 1 0; 1 -4 1; 0 1 0], 'valid'));
ref = uint8(255 * ref / max(ref(:)));
assert(isequal(S, ref));

% En el interior también coincide con el laplaciano clásico sin ampliar
lap = conv2(fp, [0 1 0; 1 -4 1; 0 1 0], 'valid');
clasico = conv2(f, [0 1 0; 1 -4 1; 0 1 0], 'same');
assert(max(max(abs(lap(2:end-1, 2:end-1) - clasico(2:end-1, 2:end-1)))) < 1e-9);

% Antes del escalado también debe coincidir el valor con signo
d2 = [1 -2 1];
lap2 = conv2(d2(:), 1, fp(:, 2:end-1), 'valid') + conv2(1, d2, fp(2:end-1, :), 'valid');
assert(max(max(abs(lap2 - lap))) < 1e-9);

% Impulso en el centro con N = 3: |-4| en el centro y 1 en los 4 vecinos
I = zeros(7, 7, 'uint8');
I(4, 4) = 255;
S = op(I, p);
esperado = zeros(7, 7, 'uint8');
esperado(4, 4) = 255;
esperado([3 5], 4) = 64;
esperado(4, [3 5]) = 64;
assert(isequal(S, esperado));

% Impulso con N = 5: d2 = conv([1 2 1], [1 -2 1]) = [1 0 -2 0 1], el centro da |-4| y los extremos 1
p.longitud = 5;
I = zeros(9, 9, 'uint8');
I(5, 5) = 255;
S = op(I, p);
esperado = zeros(9, 9, 'uint8');
esperado(5, 5) = 255;
esperado([3 7], 5) = 64;
esperado(5, [3 7]) = 64;
assert(isequal(S, esperado));

% Si llega una longitud par se usa la siguiente impar (4 -> 5)
p.longitud = 4;
assert(isequal(op(I, p), esperado));

% Los kernels de cualquier longitud suman cero y tienen N elementos
for N = 3:2:11
    b = 1;
    for k = 1:N-3
        b = conv(b, [1 1]);
    end
    d2 = conv(b, [1 -2 1]);
    assert(numel(d2) == N && sum(d2) == 0);
end

% Rampa horizontal: la segunda derivada es cero en el interior (en las orillas la réplica corta la rampa)
R = uint8(repmat(10 * (1:20), 20, 1));
for N = 3:2:11
    p.longitud = N;
    S = op(R, p);
    r = (N - 1) / 2;
    assert(all(all(S(:, r+1:end-r) == 0)));
end

% Escalón vertical con N = 3: solo responden las columnas 10 y 11, con el mismo valor (el máximo)
I = zeros(20, 20, 'uint8');
I(:, 11:20) = 200;
p.longitud = 3;
S = double(op(I, p));
filas = 1:20;
borde = S(filas, 10:11);
assert(all(borde(:) == borde(1)) && borde(1) == 255);
assert(all(all(S(filas, [1:9 12:20]) == 0)));

% Simetría: trasponer la entrada debe trasponer la salida
for N = 3:2:11
    p.longitud = N;
    assert(isequal(op(J', p), op(J, p)'));
end

% Imagen plana: cero en todas partes (orillas incluidas), y una imagen negra da cero en todo
P = 100 * ones(12, 12, 'uint8');
for N = 3:2:11
    p.longitud = N;
    S = op(P, p);
    assert(isa(S, 'uint8') && all(S(:) == 0));
end
p.longitud = 3;
Z = op(zeros(8, 8, 'uint8'), p);
assert(isa(Z, 'uint8') && all(Z(:) == 0));

% Comparación con imfilter y fspecial si existen (fspecial con alpha 0 es el mismo laplaciano 3x3)
p.longitud = 3;
S = op(J, p);
if exist('imfilter', 'file') && exist('fspecial', 'file')
    h = fspecial('laplacian', 0);
    mag = abs(imfilter(double(J), h, 'conv', 'replicate', 'same'));
    ref = uint8(255 * mag / max(mag(:)));
    assert(max(abs(double(S(:)) - double(ref(:)))) <= 1);
else
    disp('imfilter o fspecial no disponible, se omite la comparación');
end

disp('OK test_laplaciano');
end
