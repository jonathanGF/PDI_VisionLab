function salida = histograma(entrada, p)
% Dibuja el histograma de 256 niveles de la entrada como una imagen (sin parámetros).
% entrada: imagen uint8 en gris. p: struct vacío. salida: uint8 del mismo tamaño, fondo negro y barras blancas.

[M, N] = size(entrada);

% Histograma de 256 niveles (cuántos píxeles hay de cada nivel)
h = accumarray(double(entrada(:)) + 1, 1, [256 1]);

% Altura de cada barra en píxeles, normalizada al nivel más poblado
alturas = round(M * h / max(h));

% Repartimos las 256 barras a lo ancho de la imagen
if N >= 256
    % Cada columna toma la barra que le toca (cada barra queda con floor(N/256) o más columnas)
    barra = floor((0:N-1) * 256 / N) + 1;
    alt_col = alturas(barra)';
else
    % Si hay menos de 256 columnas, varias barras caen en una columna y nos quedamos con la más alta
    columna = floor((0:255)' * N / 256) + 1;
    alt_col = accumarray(columna, alturas, [N 1], @max)';
end

% Un píxel es blanco si está dentro de su barra, contando desde el borde inferior
filas = (1:M)';
salida = uint8(255) * uint8(filas > M - alt_col);
end
