function [salida, dy, dx] = block_matching(entrada, p)
% Estimación de movimiento por bloques (block matching) con SAD sobre el cuadro reducido a la mitad.
% entrada: imagen uint8 en gris. p.bloque: lado del bloque (8-32). p.radio: búsqueda en [-radio, radio]. p.anterior: cuadro anterior o [].
% salida: imagen RGB uint8 del tamaño original con una flecha verde por bloque. dy, dx: vectores por bloque (en el cuadro reducido).

B = round(p.bloque);
R = round(p.radio);
[M, N] = size(entrada);

% Cuadro actual reducido a la mitad (se toma un píxel de cada dos)
A = double(entrada(1:2:end, 1:2:end));
[h, w] = size(A);

% Número de bloques completos que caben y zona que ocupan
nby = floor(h / B);
nbx = floor(w / B);
A = A(1:nby*B, 1:nbx*B);

dy = zeros(nby, nbx);
dx = zeros(nby, nbx);

if ~isempty(p.anterior)
    % Cuadro anterior reducido y rodeado de Inf para que no se elijan desplazamientos fuera de la imagen
    P = double(p.anterior(1:2:end, 1:2:end));
    Pr = Inf(h + 2*R, w + 2*R);
    Pr(R+1:R+h, R+1:R+w) = P;

    % Se empieza con el desplazamiento cero para que en empates gane "sin movimiento"
    mejor = sad_bloques(A, Pr(R+1:R+nby*B, R+1:R+nbx*B), B, nby, nbx);

    % Lista de los (2R+1)^2 desplazamientos posibles
    [DX, DY] = meshgrid(-R:R, -R:R);

    % Un solo bucle sobre los desplazamientos; la SAD de todos los bloques se calcula a la vez
    for k = 1:numel(DY)
        % El bloque actual en (y, x) se compara con el anterior en (y - dy, x - dx)
        Ps = Pr(R+1-DY(k) : R+nby*B-DY(k), R+1-DX(k) : R+nbx*B-DX(k));
        sad = sad_bloques(A, Ps, B, nby, nbx);
        menor = sad < mejor;
        mejor(menor) = sad(menor);
        dy(menor) = DY(k);
        dx(menor) = DX(k);
    end
end

% Imagen gris copiada en los tres canales
Rc = entrada;
G = entrada;
Bc = entrada;

% Centro de cada bloque en coordenadas del cuadro original (un bloque reducido mide 2B píxeles)
[jj, ii] = meshgrid(1:nbx, 1:nby);
yc = (ii - 1) * 2*B + B;
xc = (jj - 1) * 2*B + B;

% Solo se dibujan los bloques con movimiento; el vector se escala x2 al tamaño original
con = (dy ~= 0) | (dx ~= 0);
y0 = yc(con);
x0 = xc(con);
y1 = y0 + 2*dy(con);
x1 = x0 + 2*dx(con);
% Como vectores columna para poder juntar todos los segmentos
y0 = y0(:); x0 = x0(:); y1 = y1(:); x1 = x1(:);

if ~isempty(y0)
    % Cabeza de la flecha: dos segmentos de 3 píxeles girados ±35 grados hacia atrás desde la punta
    largo = sqrt((x1 - x0).^2 + (y1 - y0).^2);
    ux = (x1 - x0) ./ largo;
    uy = (y1 - y0) ./ largo;
    c = cos(35*pi/180);
    s = sin(35*pi/180);
    xa = x1 - 3 * (c*ux - s*uy);
    ya = y1 - 3 * (s*ux + c*uy);
    xb = x1 - 3 * (c*ux + s*uy);
    yb = y1 - 3 * (-s*ux + c*uy);

    % Todos los segmentos juntos: cuerpo y los dos lados de la cabeza
    sx0 = [x0; x1; x1];
    sy0 = [y0; y1; y1];
    sx1 = [x1; xa; xb];
    sy1 = [y1; ya; yb];

    % Línea por interpolación lineal entre extremos, con suficientes muestras para no dejar huecos
    K = ceil(max(max(abs(sx1 - sx0), abs(sy1 - sy0)))) + 1;
    t = linspace(0, 1, K);
    X = round(sx0 + (sx1 - sx0) * t);
    Y = round(sy0 + (sy1 - sy0) * t);

    % Se descartan los puntos que caen fuera de la imagen
    dentro = X >= 1 & X <= N & Y >= 1 & Y <= M;
    idx = Y(dentro) + (X(dentro) - 1) * M;

    % Píxeles de la flecha en verde puro
    Rc(idx) = 0;
    G(idx) = 255;
    Bc(idx) = 0;
end

salida = cat(3, Rc, G, Bc);
end

function sad = sad_bloques(A, Ps, B, nby, nbx)
% Suma de diferencias absolutas de cada bloque BxB: se separan los bloques con reshape y se suma dentro de cada uno.
D = abs(A - Ps);
sad = reshape(sum(sum(reshape(D, B, nby, B, nbx), 1), 3), nby, nbx);
end
