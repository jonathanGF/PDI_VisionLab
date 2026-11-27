
function imagen_filtrada = filtro_mediana(imagen_rgb)

    % FILTRO_MEDIANA
    % Implementacion propia de un filtro de mediana 3x3.
    % Version optimizada mediante operaciones matriciales.

    if size(imagen_rgb,3) ~= 3
        error('La imagen debe tener tres canales RGB.');
    end

    [alto, ancho, ~] = size(imagen_rgb);

    imagen_filtrada = zeros(size(imagen_rgb),'uint8');

    % Procesamiento independiente de cada canal RGB
    for canal = 1:3

        plano = imagen_rgb(:,:,canal);

        % Matriz para almacenar las 9 posiciones de cada vecindad
        vecindades = zeros(alto,ancho,9,'uint8');

        k = 1;

        % Construccion de las vecindades 3x3
        for di = -1:1
            for dj = -1:1

                filas = max(1,min(alto,(1:alto)+di));
                columnas = max(1,min(ancho,(1:ancho)+dj));

                vecindades(:,:,k) = plano(filas,columnas);

                k = k + 1;

            end
        end

        % Ordenar los 9 valores de cada vecindad
        valores_ordenados = sort(vecindades,3);

        % El quinto valor es la mediana
        imagen_filtrada(:,:,canal) = valores_ordenados(:,:,5);

    end

end
