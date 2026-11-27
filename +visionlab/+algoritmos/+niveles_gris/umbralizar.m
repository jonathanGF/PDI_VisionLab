function imagen_binaria = umbralizar(imagen_gris, umbral)

if nargin < 2
    umbral = 128;
end

if ndims(imagen_gris) ~= 2
    error('La entrada debe ser una imagen en escala de grises.');
end

imagen_binaria = imagen_gris >= umbral;

end