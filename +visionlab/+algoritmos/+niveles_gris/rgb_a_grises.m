
function imagen_gris = rgb_a_grises(imagen_rgb)
% RGB_A_GRISES Convierte una imagen RGB a escala de grises.
%
% Entrada: imagen RGB de tipo uint8.
% Salida: imagen en escala de grises uint8.

if size(imagen_rgb, 3) ~= 3
    error('La imagen debe tener tres canales RGB.');
end

R = double(imagen_rgb(:,:,1));
G = double(imagen_rgb(:,:,2));
B = double(imagen_rgb(:,:,3));

imagen_gris = uint8( ...
    0.2989 * R + ...
    0.5870 * G + ...
    0.1140 * B);

end
