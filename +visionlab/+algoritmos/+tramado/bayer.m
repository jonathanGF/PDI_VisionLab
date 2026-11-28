function salida = bayer(entrada, p)
% Dithering ordenado con matriz de Bayer de tamaño n = 2^p.orden (1: 2x2, 2: 4x4, 3: 8x8).
% entrada: imagen uint8 en gris. p.orden: entero de 1 a 3. salida: imagen logical.

% Matriz base 2x2 de la práctica 2
M = [0, 2;
     3, 1];

% Tamaños mayores con la regla recursiva M_2n = [4M, 4M+2; 4M+3, 4M+1]
for k = 2:round(p.orden)
    M = [4*M, 4*M + 2;
         4*M + 3, 4*M + 1];
end
n = size(M, 1);

% Umbrales normalizados entre 0 y 1
T = (M + 0.5) / n^2;

% Se repite el patrón sobre toda la imagen y se recorta a su tamaño
[H, W] = size(entrada);
patron = repmat(T, ceil(H/n), ceil(W/n));

% Comparación de cada píxel (escala 0-1) contra su umbral
salida = double(entrada) / 255 >= patron(1:H, 1:W);
end
