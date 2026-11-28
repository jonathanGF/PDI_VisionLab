function test_block_matching()
% Prueba del block matching con texturas desplazadas de movimiento conocido.

% Reinicia el generador por si otra prueba activó el generador antiguo con rand('seed')
rng('default');

% Textura aleatoria suave 128x192 (ruido promediado con una caja 5x5 dos veces) llevada a 0-255
rng(7);
T = rand(128, 192);
caja = ones(5) / 25;
T = conv2(conv2(T, caja, 'same'), caja, 'same');
T = (T - min(T(:))) / (max(T(:)) - min(T(:)));
anterior = uint8(round(255 * T));

% Cuadro actual: el anterior desplazado 4 px a la derecha (2 px en el cuadro reducido)
actual = circshift(anterior, [0 4]);
p.bloque = 8;
p.radio = 4;
p.anterior = anterior;
[S, dy, dx] = visionlab.algoritmos.movimiento.block_matching(actual, p);
assert(isa(S, 'uint8'));
assert(isequal(size(S), [128 192 3]));
assert(isequal(size(dx), [8 12]));

% Bloques interiores (sin la orilla): casi todos deben dar dx = 2 y dy = 0
dxi = dx(2:end-1, 2:end-1);
dyi = dy(2:end-1, 2:end-1);
aciertos = mean(dxi(:) == 2 & dyi(:) == 0);
assert(aciertos >= 0.9);

% Flecha del bloque (3,5): centro en (2*8*2+8, 2*8*4+8) = (40, 72) y punta 4 px a la derecha
verde = S(:, :, 1) == 0 & S(:, :, 2) == 255 & S(:, :, 3) == 0;
assert(dx(3, 5) == 2 && dy(3, 5) == 0);
assert(all(verde(40, 72:76)));
% Cabeza: dos píxeles atrás de la punta, arriba y abajo de la línea
assert(verde(38, 74) && verde(42, 74));

% Fuera de las flechas la salida es el gris en los tres canales
for c = 1:3
    canal = S(:, :, c);
    assert(isequal(canal(~verde), actual(~verde)));
end

% Desplazamiento vertical de 6 px hacia abajo: dy = 3 y dx = 0 en el cuadro reducido
actual = circshift(anterior, [6 0]);
[~, dy, dx] = visionlab.algoritmos.movimiento.block_matching(actual, p);
dxi = dx(2:end-1, 2:end-1);
dyi = dy(2:end-1, 2:end-1);
assert(mean(dyi(:) == 3 & dxi(:) == 0) >= 0.9);

% Desplazamiento diagonal hacia arriba e izquierda con bloque 16 y radio 4
p.bloque = 16;
actual = circshift(anterior, [-2 -6]);
[~, dy, dx] = visionlab.algoritmos.movimiento.block_matching(actual, p);
assert(isequal(size(dx), [4 6]));
dxi = dx(2:end-1, 2:end-1);
dyi = dy(2:end-1, 2:end-1);
assert(mean(dyi(:) == -1 & dxi(:) == -3) >= 0.9);

% Primer cuadro (anterior vacío): vectores en cero y salida igual al gris replicado
p.bloque = 8;
p.anterior = [];
[S, dy, dx] = visionlab.algoritmos.movimiento.block_matching(anterior, p);
assert(all(dy(:) == 0) && all(dx(:) == 0));
assert(isequal(S, cat(3, anterior, anterior, anterior)));

% Cuadros idénticos: tampoco hay movimiento ni flechas
p.anterior = anterior;
[S, dy, dx] = visionlab.algoritmos.movimiento.block_matching(anterior, p);
assert(all(dy(:) == 0) && all(dx(:) == 0));
assert(isequal(S, cat(3, anterior, anterior, anterior)));

% Tamaño impar: la salida conserva el tamaño original
I0 = uint8(randi([0 255], 97, 131));
I1 = circshift(I0, [0 2]);
p.anterior = I0;
S = visionlab.algoritmos.movimiento.block_matching(I1, p);
assert(isequal(size(S), [97 131 3]));

% Comparación contra una búsqueda con ciclos anidados (mismo orden de revisión y mismo empate)
I0 = double(randi([0 255], 40, 56));
I1 = double(randi([0 255], 40, 56));
p.bloque = 8;
p.radio = 2;
p.anterior = uint8(I0);
[~, dy, dx] = visionlab.algoritmos.movimiento.block_matching(uint8(I1), p);
A = I1(1:2:end, 1:2:end);
P = I0(1:2:end, 1:2:end);
[h, w] = size(A);
B = 8; R = 2;
for i = 1:floor(h / B)
    for j = 1:floor(w / B)
        filas = (i-1)*B+1 : i*B;
        cols = (j-1)*B+1 : j*B;
        mejor = sum(sum(abs(A(filas, cols) - P(filas, cols))));
        ey = 0; ex = 0;
        for ddx = -R:R
            for ddy = -R:R
                f = filas - ddy;
                c = cols - ddx;
                if min(f) < 1 || max(f) > h || min(c) < 1 || max(c) > w
                    continue;
                end
                sad = sum(sum(abs(A(filas, cols) - P(f, c))));
                if sad < mejor
                    mejor = sad; ey = ddy; ex = ddx;
                end
            end
        end
        assert(dy(i, j) == ey && dx(i, j) == ex);
    end
end

% No hay función de toolbox equivalente en Image Processing Toolbox
disp('Sin referencia de toolbox para block matching, se usa la búsqueda con ciclos');

disp('OK test_block_matching');
end
