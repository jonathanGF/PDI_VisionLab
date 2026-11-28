function salida = ecualizacion(entrada, p)
% Ecualización de histograma con la CDF acumulada (sin parámetros).
% entrada: imagen uint8 en gris. p: struct vacío. salida: uint8 del mismo tamaño.

% Histograma de 256 niveles (cuántos píxeles hay de cada nivel)
h = accumarray(double(entrada(:)) + 1, 1, [256 1]);

% CDF normalizada: fracción de píxeles con nivel menor o igual a k
cdf = cumsum(h) / numel(entrada);

% Tabla de búsqueda s_k = round(255 * cdf(k))
lut = uint8(round(255 * cdf));

% Aplicamos la tabla a cada píxel y regresamos la forma original
salida = reshape(lut(double(entrada) + 1), size(entrada));
end
