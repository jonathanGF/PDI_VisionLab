function salida = diferencia_cuadros(entrada, p)
% Detección de movimiento por diferencia entre el cuadro actual y el anterior.
% entrada: imagen uint8 en gris. p.umbral: diferencia mínima (1-128). p.anterior: cuadro anterior o [].
% salida: imagen RGB uint8 con los píxeles en movimiento marcados en rojo.

% Máscara de movimiento: diferencia absoluta mayor al umbral
% En uint8 la resta satura en 0, así que el máximo de las dos restas es |actual - anterior|
if isempty(p.anterior)
    mascara = false(size(entrada));
else
    mascara = max(entrada - p.anterior, p.anterior - entrada) > p.umbral;
end

% La máscara como uint8 (0 o 1) sirve para mezclar sin indexar
m = uint8(mascara);

% Rojo: 255 donde hay movimiento y el gris en el resto
R = max(entrada, 255 * m);

% Verde y azul: la mitad del gris donde hay movimiento (uint8 redondea igual que antes)
G = entrada - (entrada - entrada / 2) .* m;

salida = cat(3, R, G, G);
end
