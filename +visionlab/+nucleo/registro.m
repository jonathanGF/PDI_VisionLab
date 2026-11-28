function ops = registro()
% Registro de operaciones: es la única lista de operaciones del sistema.
% Para agregar una operación: crear su archivo .m y añadir aquí una entrada.
% Ejemplo de parámetro: struct('nombre', 'gamma', 'min', 0.1, 'max', 5, 'inicial', 1, 'paso', 0)
% (paso 0 = continuo; paso > 0 = el deslizador avanza de paso en paso desde min)

% Lista de parámetros vacía para operaciones que no tienen
sin_parametros = struct('nombre', {}, 'min', {}, 'max', {}, 'inicial', {}, 'paso', {});

% Niveles de gris
% Negativo: no tiene parámetros
ops(1).nombre = 'Negativo';
ops(1).categoria = 'Niveles de gris';
ops(1).funcion = @visionlab.algoritmos.niveles_gris.negativo;
ops(1).movimiento = false;
ops(1).parametros = sin_parametros;

% Gamma: el exponente de la curva (menor que 1 aclara, mayor que 1 oscurece)
ops(2).nombre = 'Corrección gamma';
ops(2).categoria = 'Niveles de gris';
ops(2).funcion = @visionlab.algoritmos.niveles_gris.gamma;
ops(2).movimiento = false;
ops(2).parametros = struct('nombre', 'gamma', 'min', 0.1, 'max', 5, 'inicial', 1, 'paso', 0);

% Umbral: el nivel de gris a partir del cual el píxel queda en 1
ops(3).nombre = 'Umbral binario';
ops(3).categoria = 'Niveles de gris';
ops(3).funcion = @visionlab.algoritmos.niveles_gris.umbral;
ops(3).movimiento = false;
ops(3).parametros = struct('nombre', 'umbral', 'min', 0, 'max', 255, 'inicial', 128, 'paso', 1);

% Ecualización: no tiene parámetros
ops(4).nombre = 'Ecualización de histograma';
ops(4).categoria = 'Niveles de gris';
ops(4).funcion = @visionlab.algoritmos.niveles_gris.ecualizacion;
ops(4).movimiento = false;
ops(4).parametros = sin_parametros;

% Dithering y cuantización
% Bayer: el orden de la matriz (1: 2x2, 2: 4x4, 3: 8x8)
ops(5).nombre = 'Dithering Bayer (2x2, 4x4, 8x8)';
ops(5).categoria = 'Dithering y cuantización';
ops(5).funcion = @visionlab.algoritmos.tramado.bayer;
ops(5).movimiento = false;
ops(5).parametros = struct('nombre', 'orden', 'min', 1, 'max', 3, 'inicial', 2, 'paso', 1);

% Cuantización: el número de niveles de la salida
ops(6).nombre = 'Cuantización uniforme';
ops(6).categoria = 'Dithering y cuantización';
ops(6).funcion = @visionlab.algoritmos.tramado.cuantizacion;
ops(6).movimiento = false;
ops(6).parametros = struct('nombre', 'niveles', 'min', 2, 'max', 256, 'inicial', 8, 'paso', 1);

% Filtrado y bordes
% Binomial: la longitud impar del kernel
ops(7).nombre = 'Suavizado binomial';
ops(7).categoria = 'Filtrado y bordes';
ops(7).funcion = @visionlab.algoritmos.filtrado.binomial;
ops(7).movimiento = false;
ops(7).parametros = struct('nombre', 'longitud', 'min', 3, 'max', 15, 'inicial', 5, 'paso', 2);

% Bordes: la longitud del kernel y el umbral (0 = magnitud en gris)
ops(8).nombre = 'Bordes (binomial orden 1)';
ops(8).categoria = 'Filtrado y bordes';
ops(8).funcion = @visionlab.algoritmos.filtrado.bordes_binomial;
ops(8).movimiento = false;
ops(8).parametros = struct('nombre', {'longitud', 'umbral'}, 'min', {3, 0}, ...
    'max', {11, 255}, 'inicial', {5, 0}, 'paso', {2, 1});

% Laplaciano: la longitud impar del kernel de segunda derivada
ops(9).nombre = 'Laplaciano (binomial orden 2)';
ops(9).categoria = 'Filtrado y bordes';
ops(9).funcion = @visionlab.algoritmos.filtrado.laplaciano;
ops(9).movimiento = false;
ops(9).parametros = struct('nombre', 'longitud', 'min', 3, 'max', 11, 'inicial', 3, 'paso', 2);

% Morfología
% Erosión: el lado del elemento estructurante cuadrado
ops(10).nombre = 'Erosión';
ops(10).categoria = 'Morfología';
ops(10).funcion = @visionlab.algoritmos.morfologia.erosion;
ops(10).movimiento = false;
ops(10).parametros = struct('nombre', 'tamano', 'min', 3, 'max', 15, 'inicial', 5, 'paso', 2);

% Dilatación: el lado del elemento estructurante cuadrado
ops(11).nombre = 'Dilatación';
ops(11).categoria = 'Morfología';
ops(11).funcion = @visionlab.algoritmos.morfologia.dilatacion;
ops(11).movimiento = false;
ops(11).parametros = struct('nombre', 'tamano', 'min', 3, 'max', 15, 'inicial', 5, 'paso', 2);

% Movimiento
% Diferencia de cuadros: la diferencia mínima para marcar movimiento
ops(12).nombre = 'Diferencia de cuadros';
ops(12).categoria = 'Movimiento';
ops(12).funcion = @visionlab.algoritmos.movimiento.diferencia_cuadros;
ops(12).movimiento = true;
ops(12).parametros = struct('nombre', 'umbral', 'min', 1, 'max', 128, 'inicial', 25, 'paso', 1);

% Block matching: el lado del bloque y el radio de búsqueda (máximo 6 para que no tarde)
% Empieza en radio 3: con 4 tarda unos 31 ms y el sistema baja a 18 FPS, con 3 tarda unos 11 ms
ops(13).nombre = 'Block matching (SAD)';
ops(13).categoria = 'Movimiento';
ops(13).funcion = @visionlab.algoritmos.movimiento.block_matching;
ops(13).movimiento = true;
ops(13).parametros = struct('nombre', {'bloque', 'radio'}, 'min', {8, 1}, ...
    'max', {32, 6}, 'inicial', {16, 3}, 'paso', {8, 1});

% Adicionales
% Histograma: no tiene parámetros
ops(14).nombre = 'Histograma';
ops(14).categoria = 'Adicionales';
ops(14).funcion = @visionlab.algoritmos.adicionales.histograma;
ops(14).movimiento = false;
ops(14).parametros = sin_parametros;
end
