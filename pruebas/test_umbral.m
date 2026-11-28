function test_umbral()
% Prueba del umbral binario con imágenes pequeñas de resultado conocido.

% Caso hecho a mano con umbral 128
I = uint8([0 127 128; 200 255 50]);
p.umbral = 128;
S = visionlab.algoritmos.niveles_gris.umbral(I, p);
assert(islogical(S));
assert(isequal(size(S), size(I)));
assert(isequal(S, logical([0 0 1; 1 1 0])));

% Umbral 0: todos los píxeles pasan
p.umbral = 0;
S = visionlab.algoritmos.niveles_gris.umbral(I, p);
assert(all(S(:)));

% Umbral 255: solo pasa el blanco puro
p.umbral = 255;
S = visionlab.algoritmos.niveles_gris.umbral(I, p);
assert(isequal(S, logical([0 0 0; 0 1 0])));

% Rampa 0-255: deben quedar en 1 exactamente los valores desde el umbral
rampa = uint8(0:255);
p.umbral = 100;
S = visionlab.algoritmos.niveles_gris.umbral(rampa, p);
assert(sum(S) == 156);
assert(~S(100) && S(101));

% Comparación con imbinarize si existe (usa > en lugar de >=, por eso se resta 0.5)
I = uint8(randi([0 255], 48, 64));
p.umbral = 128;
S = visionlab.algoritmos.niveles_gris.umbral(I, p);
if exist('imbinarize', 'file')
    ref = imbinarize(I, (p.umbral - 0.5) / 255);
    assert(isequal(S, ref));
else
    disp('imbinarize no disponible, se omite la comparación');
end

disp('OK test_umbral');
end
