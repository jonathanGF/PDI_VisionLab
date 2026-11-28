function salida = umbral(entrada, p)
% Umbral binario: los píxeles con valor >= p.umbral quedan en 1 y el resto en 0.
% entrada: imagen uint8 en gris. p.umbral: valor entre 0 y 255. salida: imagen logical.

% Comparación directa como en la práctica 2, pero en escala 0-255 en lugar de 0-1
salida = entrada >= p.umbral;
end
