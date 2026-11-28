function salida = erosion(entrada, p)
% Erosión con elemento estructurante cuadrado n x n: cada píxel toma el mínimo de su vecindad.
% entrada: imagen uint8 en gris o logical. p.tamano: n impar de 3 a 15. salida: del mismo tipo y tamaño.

% El tamaño debe ser impar para que la ventana tenga centro; si llega par se usa n+1
n = round(p.tamano);
if mod(n, 2) == 0
    n = n + 1;
end
r = (n - 1) / 2;
[M, N] = size(entrada);

% Índices con relleno por replicación: lo que cae fuera se cambia por la orilla más cercana
idx_col = min(max(1-r:N+r, 1), N);
idx_fil = min(max(1-r:M+r, 1), M);

% Mínimo por filas: se recorre la ventana de n desplazamientos horizontales
salida = entrada(:, idx_col(1:N));
for k = 2:n
    salida = min(salida, entrada(:, idx_col(k:k+N-1)));
end

% Mínimo por columnas sobre el resultado anterior (el cuadrado es separable)
temp = salida;
salida = temp(idx_fil(1:M), :);
for k = 2:n
    salida = min(salida, temp(idx_fil(k:k+M-1), :));
end

% Si la entrada era binaria se regresa como logical
if islogical(entrada)
    salida = logical(salida);
end
end
