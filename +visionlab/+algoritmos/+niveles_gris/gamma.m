function salida = gamma(entrada, p)
% Corrección gamma: s = 255*(r/255)^gamma usando una tabla LUT de 256 valores.
% entrada: imagen uint8 en gris. p.gamma: exponente (0.1 a 5). salida: uint8 del mismo tamaño.

% Tabla con el valor de salida para cada nivel de gris 0..255
r = (0:255) / 255;
lut = uint8(255 * r .^ p.gamma);

% Cada pixel toma su valor de la tabla (se suma 1 porque MATLAB indexa desde 1)
% reshape conserva el tamaño original aunque la imagen sea una sola columna
salida = reshape(lut(double(entrada) + 1), size(entrada));
end
