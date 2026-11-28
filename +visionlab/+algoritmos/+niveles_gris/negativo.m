function salida = negativo(entrada, p)
% Negativo de la imagen: invierte los niveles de gris (salida = 255 - entrada).
% entrada: imagen uint8 en gris. p: no se usa (no hay parámetros). salida: uint8.

% Se resta a 255 directamente en uint8, así el resultado ya queda en 0-255
salida = 255 - uint8(entrada);
end
