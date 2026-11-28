function test_cuantizacion()
% Prueba de la cuantización uniforme con imágenes pequeñas de resultado conocido.

img = uint8([0 63 64 127; 128 191 192 255]);

%% L = 2 equivale a umbral en 128 con valores 64 y 192
p.niveles = 2;
s = visionlab.algoritmos.tramado.cuantizacion(img, p);
assert(isa(s, 'uint8'), 'La salida debe ser uint8');
assert(isequal(size(s), size(img)), 'La salida debe tener el mismo tamaño');
assert(isequal(s, uint8([64 64 64 64; 192 192 192 192])), 'L = 2 no coincide con el cálculo a mano');

%% L = 4: paso 64, centros 32, 96, 160, 224
p.niveles = 4;
s = visionlab.algoritmos.tramado.cuantizacion(img, p);
assert(isequal(s, uint8([32 32 96 96; 160 160 224 224])), 'L = 4 no coincide con el cálculo a mano');

%% L = 8: paso 32, 100 -> floor(100/32) = 3 -> 3*32 + 16 = 112
p.niveles = 8;
s = visionlab.algoritmos.tramado.cuantizacion(uint8([0 31 32 100 255]), p);
assert(isequal(s, uint8([16 16 48 112 240])), 'L = 8 no coincide con el cálculo a mano');

%% L = 3: paso 85.33, centros 42.67, 128 y 213.33 truncados a 42, 128, 213
p.niveles = 3;
s = visionlab.algoritmos.tramado.cuantizacion(uint8([0 85 86 170 171 255]), p);
assert(isequal(s, uint8([42 42 128 128 213 213])), 'L = 3 no coincide con el cálculo a mano');

%% L = 256 es la identidad
rampa = uint8(0:255);
p.niveles = 256;
s = visionlab.algoritmos.tramado.cuantizacion(rampa, p);
assert(isequal(s, rampa), 'Con L = 256 la imagen debe quedar igual');

%% Con cualquier L la rampa debe tener exactamente L valores distintos y ser no decreciente
for L = [2 3 5 6 7 8 16 100 128 255 256]
    p.niveles = L;
    s = visionlab.algoritmos.tramado.cuantizacion(rampa, p);
    assert(numel(unique(s)) == L, sprintf('Con L = %d no salen L niveles', L));
    assert(all(diff(double(s)) >= 0), 'La cuantización debe ser no decreciente');
end

%% Una imagen de una sola columna debe conservar su forma M x 1
p.niveles = 8;
s = visionlab.algoritmos.tramado.cuantizacion(rampa', p);
assert(isequal(size(s), [256 1]), 'Una columna debe seguir siendo columna');

%% Comparación contra la fórmula directa de la especificación en una imagen aleatoria
rand('seed', 1);
A = uint8(floor(rand(48, 64) * 256));
for L = [2 4 8 16 32 64 128 256]
    p.niveles = L;
    s = visionlab.algoritmos.tramado.cuantizacion(A, p);
    paso = 256 / L;
    directo = uint8(min(floor(floor(double(A) / paso) * paso + paso / 2), 255));
    assert(isequal(s, directo), sprintf('L = %d no coincide con la fórmula directa', L));
end

%% Comparación con imquantize (solo si existe en esta instalación)
% Los umbrales se ponen a medio nivel porque imquantize manda el valor igual al umbral al nivel de abajo
p.niveles = 6;
s = visionlab.algoritmos.tramado.cuantizacion(A, p);
paso = 256 / 6;
umbrales = ceil(paso * (1:5)) - 0.5;
valores = floor(paso * (0:5) + paso / 2);
try
    ref = imquantize(double(A), umbrales, valores);
    assert(isequal(double(s), ref), 'No coincide con imquantize');
    disp('Comparación con imquantize: OK');
catch err
    if exist('imquantize', 'file')
        rethrow(err);
    end
    disp('imquantize no está disponible, se omite la comparación');
end

disp('OK test_cuantizacion');
end
