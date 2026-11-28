function test_gamma()
% Prueba de la corrección gamma con imágenes pequeñas de resultado conocido.

% Imagen de prueba con los extremos y algunos niveles intermedios
img = uint8([0 64 128; 192 255 100]);

%% gamma = 1 no cambia la imagen
p.gamma = 1;
s = visionlab.algoritmos.niveles_gris.gamma(img, p);
assert(isa(s, 'uint8'), 'La salida debe ser uint8');
assert(isequal(size(s), size(img)), 'La salida debe tener el mismo tamaño');
assert(isequal(s, img), 'Con gamma = 1 la imagen debe quedar igual');

%% gamma = 2 calculado a mano: 64 -> 255*(64/255)^2 = 16.06 -> 16, 128 -> 64.25 -> 64
p.gamma = 2;
s = visionlab.algoritmos.niveles_gris.gamma(img, p);
esperado = uint8([0 16 64; 145 255 39]);
assert(isequal(s, esperado), 'Gamma = 2 no coincide con el cálculo a mano');

%% gamma = 0.5 aclara: 64 -> 255*sqrt(64/255) = 127.75 -> 128
p.gamma = 0.5;
s = visionlab.algoritmos.niveles_gris.gamma(img, p);
esperado = uint8([0 128 181; 221 255 160]);
assert(isequal(s, esperado), 'Gamma = 0.5 no coincide con el cálculo a mano');

%% Los extremos 0 y 255 no cambian con ningún gamma del rango
rampa = uint8(0:255);
for g = [0.1 0.7 1.5 5]
    p.gamma = g;
    s = visionlab.algoritmos.niveles_gris.gamma(rampa, p);
    assert(s(1) == 0 && s(end) == 255, 'Los extremos deben quedarse en 0 y 255');
    % La curva debe ser creciente (nunca baja)
    assert(all(diff(double(s)) >= 0), 'La curva gamma debe ser no decreciente');
end

%% Una imagen de una sola columna debe conservar su forma M x 1
columna = uint8(0:255)';
p.gamma = 1.37;
s = visionlab.algoritmos.niveles_gris.gamma(columna, p);
assert(isequal(size(s), [256 1]), 'Una columna debe seguir siendo columna');
assert(isequal(s, uint8(255 * (double(columna) / 255) .^ 1.37)), 'La columna no coincide con la fórmula');

%% Comparación contra la fórmula directa en una imagen aleatoria
rand('seed', 1);
A = uint8(floor(rand(48, 64) * 256));
p.gamma = 2.2;
s = visionlab.algoritmos.niveles_gris.gamma(A, p);
directo = uint8(255 * (double(A) / 255) .^ 2.2);
assert(isequal(s, directo), 'La LUT no coincide con la fórmula directa');

%% Comparación con imadjust (solo si existe en esta instalación)
try
    ref = imadjust(A, [0 1], [0 1], 2.2);
    dif = max(abs(double(s(:)) - double(ref(:))));
    assert(dif <= 1, 'Diferencia mayor a 1 nivel contra imadjust');
    disp('Comparación con imadjust: OK');
catch err
    if exist('imadjust', 'file')
        rethrow(err);
    end
    disp('imadjust no está disponible, se omite la comparación');
end

disp('OK test_gamma');
end
