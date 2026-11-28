function salida = cuantizacion(entrada, p)
% Cuantización uniforme: reduce la imagen a p.niveles niveles equiespaciados (2 a 256).
% entrada: imagen uint8 en gris. p.niveles: número de niveles L. salida: uint8 del mismo tamaño.

% El deslizador puede dar valores no enteros, se redondea y se limita al rango
L = min(max(round(p.niveles), 2), 256);

% Intervalo de cada nivel 0..255: idx = floor(r/paso) con paso = 256/L
% Se calcula como floor(r*L/256) para que la división sea exacta (256 es potencia de 2)
r = 0:255;
idx = floor(r * L / 256);

% Cada intervalo se representa con su centro idx*paso + paso/2, truncado al entero
% Con L = 2 quedan 64 y 192, con L = 256 la imagen no cambia
centro = floor((2 * idx + 1) * 128 / L);
lut = uint8(min(centro, 255));

% Cada pixel toma su valor de la tabla (se suma 1 porque MATLAB indexa desde 1)
salida = reshape(lut(double(entrada) + 1), size(entrada));
end
