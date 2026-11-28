function test_binomial()
% Prueba del suavizado binomial con imágenes pequeñas de resultado conocido.

%% Un impulso en el centro debe dar el kernel 2D escalado: 255*[1 2 1; 2 4 2; 1 2 1]/16
img = zeros(5, 5, 'uint8');
img(3, 3) = 255;
p.longitud = 3;
s = visionlab.algoritmos.filtrado.binomial(img, p);
assert(isa(s, 'uint8'), 'La salida debe ser uint8');
assert(isequal(size(s), size(img)), 'La salida debe tener el mismo tamaño');
% 255/16 = 15.94 -> 16, 255*2/16 = 31.88 -> 32, 255*4/16 = 63.75 -> 64
esperado = zeros(5, 5, 'uint8');
esperado(2:4, 2:4) = [16 32 16; 32 64 32; 16 32 16];
assert(isequal(s, esperado), 'El impulso con N = 3 no coincide con el cálculo a mano');

%% Con N = 5 el impulso reproduce [1 4 6 4 1]'*[1 4 6 4 1]/256
img = zeros(7, 7, 'uint8');
img(4, 4) = 255;
p.longitud = 5;
s = visionlab.algoritmos.filtrado.binomial(img, p);
h5 = [1 4 6 4 1];
esperado = zeros(7, 7, 'uint8');
esperado(2:6, 2:6) = uint8(round(255 * (h5' * h5) / 256));
assert(isequal(s, esperado), 'El impulso con N = 5 no reproduce el kernel binomial');
% El centro: 255*36/256 = 35.86 -> 36
assert(s(4, 4) == 36, 'El centro del impulso con N = 5 debe ser 36');

%% Si llega una longitud par se usa la siguiente impar (4 -> 5)
p.longitud = 4;
s4 = visionlab.algoritmos.filtrado.binomial(img, p);
assert(isequal(s4, s), 'Con longitud 4 debe comportarse igual que con 5');
p.longitud = 2;
p3.longitud = 3;
assert(isequal(visionlab.algoritmos.filtrado.binomial(img, p), visionlab.algoritmos.filtrado.binomial(img, p3)), ...
    'Con longitud 2 debe comportarse igual que con 3');

%% Imagen constante: con bordes replicados queda igual en toda la imagen, orillas y esquinas incluidas
img = 100 * ones(5, 5, 'uint8');
for N = 3:2:15
    p.longitud = N;
    s = visionlab.algoritmos.filtrado.binomial(img, p);
    assert(isequal(s, img), sprintf('Con N = %d una imagen constante debe quedar igual', N));
end

%% Imagen negra y blanca no se salen de rango (y la blanca no se oscurece en las orillas)
blanca = 255 * ones(20, 30, 'uint8');
p.longitud = 15;
s = visionlab.algoritmos.filtrado.binomial(blanca, p);
assert(all(s(:) == 255), 'Una imagen blanca debe seguir en 255 en todas partes');
s = visionlab.algoritmos.filtrado.binomial(zeros(20, 30, 'uint8'), p);
assert(all(s(:) == 0), 'Una imagen negra debe seguir negra');

%% Separable contra conv2 2D directo con h'*h sobre la imagen ampliada, para todas las longitudes
rand('seed', 1);
A = uint8(floor(rand(48, 64) * 256));
for N = 3:2:15
    p.longitud = N;
    s = visionlab.algoritmos.filtrado.binomial(A, p);
    % Kernel con la fórmula de combinaciones, distinto camino que conv([1 1])
    h = zeros(1, N);
    for k = 0:N-1
        h(k + 1) = nchoosek(N - 1, k);
    end
    h = h / sum(h);
    % Ampliación con repmat, distinto camino que la indexación de la función
    r = (N - 1) / 2;
    Ap = double(A);
    Ap = [repmat(Ap(1, :), r, 1); Ap; repmat(Ap(end, :), r, 1)];
    Ap = [repmat(Ap(:, 1), 1, r), Ap, repmat(Ap(:, end), 1, r)];
    directo = uint8(round(conv2(Ap, h' * h, 'valid')));
    assert(isequal(s, directo), sprintf('Con N = %d el separable no coincide con conv2 2D', N));
end

%% Una imagen de una sola columna conserva su forma
columna = uint8(0:10:250)';
p.longitud = 5;
s = visionlab.algoritmos.filtrado.binomial(columna, p);
assert(isequal(size(s), size(columna)), 'Una columna debe seguir siendo columna');

%% Comparación con imfilter usando bordes replicados (solo si existe en esta instalación)
try
    p.longitud = 9;
    s = visionlab.algoritmos.filtrado.binomial(A, p);
    h = [1 8 28 56 70 56 28 8 1] / 256;
    ref = imfilter(A, h' * h, 'replicate', 'conv', 'same');
    assert(isequal(s, ref), 'No coincide con imfilter');
    disp('Comparación con imfilter: OK');
catch err
    if exist('imfilter', 'file')
        rethrow(err);
    end
    disp('imfilter no está disponible, se omite la comparación');
end

disp('OK test_binomial');
end
