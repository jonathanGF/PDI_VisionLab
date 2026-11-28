function salida = binomial(entrada, p)
% Suavizado binomial separable: kernel 1D de longitud N (fila N-1 de Pascal) aplicado por columnas y filas.
% entrada: imagen uint8 en gris. p.longitud: N impar de 3 a 15. salida: uint8 del mismo tamaño.

% La longitud debe ser impar para que el kernel tenga centro; si llega par se usa N+1
N = round(p.longitud);
if mod(N, 2) == 0
    N = N + 1;
end

% Coeficientes binomiales convolucionando [1 1] consigo mismo N-1 veces
h = 1;
for k = 1:N-1
    h = conv(h, [1 1]);
end

% Se normaliza para que sume 1 y el brillo promedio no cambie
h = h / sum(h);

% Bordes replicados: se repiten la primera y última fila y columna r veces
r = floor(N / 2);
[M, L] = size(entrada);
filas = [ones(1, r), 1:M, M * ones(1, r)];
columnas = [ones(1, r), 1:L, L * ones(1, r)];
f = double(entrada(filas, columnas));

% Filtrado separable: primero h como columna y luego como fila
% Con 'valid' sobre la imagen ampliada se recupera el tamaño original
filtrada = conv2(h(:), h(:)', f, 'valid');

% Se redondea y se regresa a uint8 (el kernel es positivo y suma 1, no se sale de 0..255)
salida = uint8(round(filtrada));
end
