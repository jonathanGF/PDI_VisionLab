function salida = laplaciano(entrada, p)
% Laplaciano con la derivada binomial de orden 2 en y más la de orden 2 en x.
% entrada: imagen uint8 en gris. p.longitud: tamaño impar del kernel (3 a 11).
% salida: valor absoluto del laplaciano escalado linealmente a uint8 (0-255).

% La longitud debe ser impar para que el kernel tenga centro; si llega par se usa N+1
N = round(p.longitud);
if mod(N, 2) == 0
    N = N + 1;
end

% Bordes replicados: se repiten la primera y última fila y columna r veces
r = floor(N / 2);
[M, L] = size(entrada);
filas = [ones(1, r), 1:M, M * ones(1, r)];
columnas = [ones(1, r), 1:L, L * ones(1, r)];
f = double(entrada(filas, columnas));

% Coeficientes binomiales de N-2 elementos (fila N-3 del triángulo de Pascal)
b = 1;
for k = 1:N-3
    b = conv(b, [1 1]);
end

% Derivada de orden 2 como en la tarea 3: suavizado convolucionado con [1 -2 1]
d2 = conv(b, [1 -2 1]);

% Segunda derivada por columnas (y) más segunda derivada por renglones (x), sin suavizar en la otra dirección
% Cada una usa solo la ampliación en su dirección para que con 'valid' quede del tamaño original
lap = conv2(f(:, r+1:r+L), d2(:), 'valid') + conv2(f(r+1:r+M, :), d2, 'valid');

% Valor absoluto y escalado lineal para que el máximo quede en 255 (si es plana queda en cero)
magnitud = abs(lap);
m = max(magnitud(:));
if m > 0
    salida = uint8(255 * magnitud / m);
else
    salida = zeros(size(entrada), 'uint8');
end
end
