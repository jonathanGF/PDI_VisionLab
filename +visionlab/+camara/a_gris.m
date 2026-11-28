function gris = a_gris(rgb)
% Conversión de RGB a gris con la fórmula de luminancia 0.299 R + 0.587 G + 0.114 B.
% entrada: uint8 M×N×3. salida: uint8 M×N.

% Suma ponderada de los tres canales; uint8 redondea y recorta a 0-255
gris = uint8(0.299 * double(rgb(:, :, 1)) + 0.587 * double(rgb(:, :, 2)) + 0.114 * double(rgb(:, :, 3)));
end
