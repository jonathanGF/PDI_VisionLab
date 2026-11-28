function salida = bordes_binomial(entrada, p)
% Bordes con la derivada binomial de orden 1 en x y en y (gradiente suavizado).
% entrada: imagen uint8 en gris. p.longitud: tamaño impar del kernel. p.umbral: 0 a 255.
% salida: magnitud uint8 escalada a 0-255 si p.umbral es 0, o imagen logical si p.umbral > 0.

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

% Coeficientes binomiales de N-1 elementos (fila N-2 del triángulo de Pascal)
b = 1;
for k = 1:N-2
    b = conv(b, [1 1]);
end

% Derivada de orden 1 como en la tarea 3: suavizado convolucionado con [1 -1]
d = conv(b, [1 -1]);

% Suavizado binomial de N elementos, normalizado para que sume 1
s = conv(b, [1 1]);
s = s / sum(s);

% Gradiente separable: gx deriva por renglones y suaviza por columnas, gy al revés
% Con 'valid' sobre la imagen ampliada se recupera el tamaño original
gx = conv2(s(:), d(:)', f, 'valid');
gy = conv2(d(:), s(:)', f, 'valid');

% Magnitud aproximada con valores absolutos
magnitud = abs(gx) + abs(gy);

% Escalado lineal para que el máximo quede en 255 (si la imagen es plana queda en cero)
m = max(magnitud(:));
if m > 0
    escalada = uint8(255 * magnitud / m);
else
    escalada = zeros(size(entrada), 'uint8');
end

% Con umbral 0 se regresa la magnitud, con umbral mayor se binariza
if p.umbral == 0
    salida = escalada;
else
    salida = escalada >= p.umbral;
end
end
