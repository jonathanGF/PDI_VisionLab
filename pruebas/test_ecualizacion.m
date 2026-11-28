function test_ecualizacion()
% Prueba de la ecualización de histograma con imágenes pequeñas.
% Se corre desde la raíz del repo y al final imprime "OK test_ecualizacion".

p = struct();

% Caso a mano 4x4: niveles 0, 1 y 2 con 4 píxeles cada uno, nivel 3 con 3 y nivel 255 con 1
I = uint8([0 0 1 1;
           0 0 1 1;
           2 2 3 3;
           2 2 3 255]);
% CDF: 4/16, 8/16, 12/16, 15/16, 16/16 -> 255*cdf = 63.75, 127.5, 191.25, 239.06, 255
esperada = uint8([ 64  64 128 128;
                   64  64 128 128;
                  191 191 239 239;
                  191 191 239 255]);
S = visionlab.algoritmos.niveles_gris.ecualizacion(I, p);
assert(isa(S, 'uint8'), 'La salida debe ser uint8');
assert(isequal(size(S), size(I)), 'La salida debe tener el tamaño de la entrada');
assert(isequal(S, esperada), 'El caso 4x4 no coincide con la CDF hecha a mano');

% Imagen constante: toda la CDF vale 1 en ese nivel, así que todo sale en 255
C = uint8(77 * ones(5, 7));
S = visionlab.algoritmos.niveles_gris.ecualizacion(C, p);
assert(all(S(:) == 255), 'Una imagen constante debe salir en 255');

% Dos niveles mitad y mitad: el oscuro va a round(127.5) = 128 y el claro a 255
D = uint8([10 10 200 200]);
S = visionlab.algoritmos.niveles_gris.ecualizacion(D, p);
assert(isequal(S, uint8([128 128 255 255])), 'El caso de dos niveles no coincide');

% Rampa diagonal con una ondulación (niveles entre 30 y 230, ningún nivel con más del 1.1% de píxeles)
[x, y] = meshgrid(1:160, 1:120);
B = uint8(30 + 190 * (x + y - 2) / 278 + 10 * sin(x / 7));
S = visionlab.algoritmos.niveles_gris.ecualizacion(B, p);

% La tabla no debe invertir el orden de los niveles (función monótona)
[~, orden] = sort(double(B(:)));
assert(all(diff(double(S(orden))) >= 0), 'La ecualización debe ser monótona');

% El nivel más alto presente siempre termina en 255
assert(max(S(:)) == 255, 'El nivel máximo debe ir a 255');

% Comparación contra histeq de IPT si existe. histeq no usa cdf(k) sino cdf(k) - p(k)/2
% (la mitad del propio nivel) y toma el primer nivel de salida que la alcanza, así que se
% recorre unos 128*p(k) niveles; por eso la tolerancia y una imagen sin niveles muy poblados
if exist('histeq', 'file')
    R = histeq(B, 256);
    % En Octave histeq regresa double en [0, 1]; lo pasamos a 0-255
    if isfloat(R)
        R = round(255 * R);
    end
    dif = abs(double(S) - double(R));
    fraccion = mean(dif(:) <= 2);
    fprintf('histeq: %.2f%% de píxeles con diferencia <= 2 (máx %d)\n', 100 * fraccion, max(dif(:)));
    assert(fraccion >= 0.95, 'Menos del 95% de los píxeles está a 2 niveles de histeq');
else
    disp('histeq no está disponible: se omite la comparación');
end

disp('OK test_ecualizacion');
end
