function imagen_filtrada = filtro_gaussiano(imagen_rgb)

% FILTRO_GAUSSIANO Aplica suavizado gaussiano 3x3.

if size(imagen_rgb,3) ~= 3
    error('La imagen debe tener tres canales RGB.');
end

kernel = [1 2 1;
    2 4 2;
    1 2 1] / 16;

imagen_filtrada = zeros(size(imagen_rgb),'uint8');

for canal = 1:3

    plano = double(imagen_rgb(:,:,canal));

    filtrado = conv2(plano,kernel,'same');

    imagen_filtrada(:,:,canal) = uint8(filtrado);

end

end