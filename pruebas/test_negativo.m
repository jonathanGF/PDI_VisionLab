function test_negativo()
% Prueba del negativo con imágenes pequeñas de resultado conocido.

p = struct();

% Caso a mano: los extremos y algunos valores intermedios
A = uint8([0 255; 100 128]);
esperado = uint8([255 0; 155 127]);
S = visionlab.algoritmos.niveles_gris.negativo(A, p);
assert(isa(S, 'uint8'));
assert(isequal(size(S), size(A)));
assert(isequal(S, esperado));

% Rampa con todos los niveles 0-255: debe quedar invertida
rampa = uint8(0:255);
S = visionlab.algoritmos.niveles_gris.negativo(rampa, p);
assert(isequal(S, uint8(255:-1:0)));

% Aplicar el negativo dos veces regresa a la imagen original
I = uint8(randi([0 255], 30, 40));
S = visionlab.algoritmos.niveles_gris.negativo(I, p);
S2 = visionlab.algoritmos.niveles_gris.negativo(S, p);
assert(isequal(S2, I));

% Comparación con imcomplement si está disponible
if exist('imcomplement', 'file')
    assert(isequal(S, imcomplement(I)));
else
    disp('imcomplement no disponible, se omite la comparación');
end

disp('OK test_negativo');
end
