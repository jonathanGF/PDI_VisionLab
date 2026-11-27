function imagen_filtrada = filtro_media(imagen_rgb)

% FILTRO_MEDIA Aplica un filtro promedio 3x3.
% Entrada: imagen RGB uint8.
% Salida: imagen RGB filtrada uint8.

if size(imagen_rgb,3) ~= 3
    error('La imagen debe tener tres canales RGB.');
end

kernel = ones(3,3) / 9;

imagen_filtrada = zeros(size(imagen_rgb),'uint8');

for canal = 1:3

    plano = double(imagen_rgb(:,:,canal));

    filtrado = conv2(plano,kernel,'same');

    imagen_filtrada(:,:,canal) = uint8(filtrado);

end

end