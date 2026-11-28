function test_diferencia_cuadros()
% Prueba de la diferencia de cuadros con rectángulos sintéticos de resultado conocido.

% Dos cuadros 20x30: rectángulo blanco sobre fondo negro, desplazado 4 columnas y 2 filas
A = zeros(20, 30, 'uint8');
B = zeros(20, 30, 'uint8');
A(5:12, 6:15) = 255;
B(7:14, 10:19) = 255;
p.umbral = 25;
p.anterior = A;
S = visionlab.algoritmos.movimiento.diferencia_cuadros(B, p);
assert(isa(S, 'uint8'));
assert(isequal(size(S), [20 30 3]));

% La máscara esperada es la diferencia simétrica de las dos posiciones
enA = A > 0;
enB = B > 0;
esperada = xor(enA, enB);
% Con fondo 0 y rectángulo 255, los píxeles marcados son los únicos donde R y G difieren
mascara = S(:, :, 1) ~= S(:, :, 2);
assert(isequal(mascara, esperada));

% Revisión píxel a píxel de los tres canales construidos a mano
R = B; G = B; Bc = B;
R(esperada) = 255;
G(esperada) = B(esperada) / 2;
Bc(esperada) = B(esperada) / 2;
assert(isequal(S, cat(3, R, G, Bc)));

% Fuera de la máscara la salida es la imagen gris en los tres canales
for c = 1:3
    canal = S(:, :, c);
    assert(isequal(canal(~esperada), B(~esperada)));
end

% Primer cuadro (anterior vacío): sin movimiento, salida igual al gris replicado
p.anterior = [];
S = visionlab.algoritmos.movimiento.diferencia_cuadros(B, p);
assert(isequal(S, cat(3, B, B, B)));

% Cuadros idénticos: tampoco hay movimiento
p.anterior = B;
S = visionlab.algoritmos.movimiento.diferencia_cuadros(B, p);
assert(isequal(S, cat(3, B, B, B)));

% Umbral estricto: una diferencia exacta igual al umbral no cuenta, una mayor sí
I1 = uint8([100 100 100]);
I0 = uint8([75 74 126]);
p.umbral = 25;
p.anterior = I0;
S = visionlab.algoritmos.movimiento.diferencia_cuadros(I1, p);
assert(isequal(S(:, :, 1), uint8([100 255 255])));
assert(isequal(S(:, :, 2), uint8([100 50 50])));
assert(isequal(S(:, :, 3), uint8([100 50 50])));

% Comparación con imabsdiff si existe
I0 = uint8(randi([0 255], 48, 64));
I1 = uint8(randi([0 255], 48, 64));
p.umbral = 40;
p.anterior = I0;
S = visionlab.algoritmos.movimiento.diferencia_cuadros(I1, p);
esperada = abs(double(I1) - double(I0)) > p.umbral;
if exist('imabsdiff', 'file')
    ref = imabsdiff(I1, I0) > p.umbral;
    assert(isequal(ref, esperada));
    R = I1; G = I1;
    R(ref) = 255; G(ref) = I1(ref) / 2;
    assert(isequal(S, cat(3, R, G, G)));
else
    disp('imabsdiff no disponible, se omite la comparación');
end

disp('OK test_diferencia_cuadros');
end
