# Diferencia de cuadros

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+movimiento/diferencia_cuadros.m` |
| Categoría | Movimiento |
| Parámetros | `umbral`: mín 1, máx 128, inicial 25, paso 1; además recibe `p.anterior` (cuadro anterior) |
| Entrada / salida | uint8 gris M×N / RGB uint8 M×N×3 |
| Prueba | `pruebas/test_diferencia_cuadros.m` |

## Qué hace y para qué sirve

Detecta qué partes de la escena se movieron entre el cuadro anterior y el actual. Con la cámara fija, el fondo casi no cambia de un cuadro a otro y solo los objetos en movimiento producen diferencias grandes. Los píxeles cuya diferencia supera el umbral se pintan de rojo sobre la imagen en gris, así se ve qué se movió sin perder la escena. Es la técnica más simple de detección de movimiento (vigilancia, conteo de objetos, activar una grabación).

## Fundamento matemático

Con $f_t$ el cuadro actual y $f_{t-1}$ el anterior:

$$D(x, y) = |f_t(x, y) - f_{t-1}(x, y)|, \qquad m(x, y) = \begin{cases} 1, & D(x, y) > T \\ 0, & \text{en otro caso} \end{cases}$$

$T$ es el parámetro `umbral` y la comparación es estricta. La máscara $m$ es un umbral binario (como en `umbral.md`) aplicado a la imagen de diferencias en lugar de a la imagen misma.

El umbral separa movimiento de ruido. Si el ruido del sensor es aproximadamente gaussiano con desviación $\sigma$ en cada cuadro, la diferencia de dos cuadros de una escena quieta tiene desviación $\sqrt{2}\,\sigma$; un umbral bajo marca ese ruido como movimiento y uno alto solo deja los cambios fuertes.

Qué detecta en realidad: un objeto uniforme que se desplaza marca la diferencia simétrica entre su posición vieja y la nueva, $m = O_{t-1} \oplus O_t$ (XOR), no el objeto completo. El interior de un objeto liso que se traslapa consigo mismo no cambia y no se marca.

La salida se arma con la máscara como factor 0 o 1:

$$R = \max(f_t,\ 255\, m), \qquad G = B = f_t - \left( f_t - \tfrac{f_t}{2} \right) m$$

Donde $m = 1$ queda $R = 255$ y $G = B \approx f_t / 2$ (rojo que conserva algo de la textura); donde $m = 0$ los tres canales son $f_t$ (gris).

En uint8 la resta satura en 0, así que $\max(a - b,\ b - a)$ da exactamente $|a - b|$: uno de los dos términos es la diferencia verdadera y el otro es 0. Así se calcula el valor absoluto sin convertir a double.

## Relación con el curso

- Práctica 2 del curso (dithering), inciso a: la máscara es el mismo umbral fijo de la cuantización directa a 1 bit, aplicado a la diferencia de cuadros.
- `umbral.md`: misma comparación, pero aquí estricta ($>$) en lugar de $\ge$, y calculada dentro de la función (no llama a `umbral.m`).
- La detección de movimiento no tiene práctica propia en el curso; es parte de los temas adicionales del proyecto.

## Implementación

1. Si `p.anterior` está vacío, `mascara = false(size(entrada))`. En el uso normal no ocurre, porque `visionlab.nucleo.Pipeline.procesar` pasa el mismo cuadro como anterior en el primer cuadro, lo que también da una máscara vacía.
2. Si hay anterior, `mascara = max(entrada - p.anterior, p.anterior - entrada) > p.umbral;` calcula $|f_t - f_{t-1}| > T$ con la saturación de uint8.
3. `m = uint8(mascara);` convierte la máscara a 0 o 1 para mezclar con aritmética en lugar de indexar.
4. `R = max(entrada, 255 * m);` pone 255 donde hay movimiento y deja el gris en el resto.
5. `G = entrada - (entrada - entrada / 2) .* m;` deja la mitad del gris donde hay movimiento. `entrada / 2` en uint8 redondea ($101/2 = 50.5 \to 51$).
6. `salida = cat(3, R, G, G);` arma la imagen RGB (azul igual a verde).
7. El parámetro es `p.umbral`, de 1 a 128 con inicial 25 (`registro.m`, entrada 12, con `movimiento = true` para que el pipeline entregue `p.anterior`).

## Verificación

`pruebas/test_diferencia_cuadros.m` pasa en MATLAB R2026b y en Octave 11.3. Revisa:

- Dos cuadros de 20×30 con un rectángulo blanco desplazado 2 filas y 4 columnas sobre fondo negro: la máscara recuperada de la salida (los píxeles donde R difiere de G) es exactamente el XOR de las dos posiciones, y la salida coincide píxel por píxel con la superposición construida a mano. Fuera de la máscara los tres canales son el gris.
- Con `p.anterior = []` y con dos cuadros idénticos la salida es el gris replicado en los tres canales.
- Umbral estricto: con $T = 25$, una diferencia de exactamente 25 no cuenta y una de 26 sí; los valores esperados son $[100\ 255\ 255]$ en R y $[100\ 50\ 50]$ en G y B.
- Contra `imabsdiff(I1, I0) > T` sobre imágenes aleatorias de 48×64: la máscara y la salida coinciden en MATLAB.

## Costo medido

De [`tiempos_operaciones.csv`](../experimentos/figuras/tiempos_operaciones.csv) (MATLAB R2026b, 640×480, dos cuadros reales de la cámara, mediana de 20):

| Parámetro | ms mediana | ms p90 | FPS máx |
|-----------|-----------:|-------:|--------:|
| umbral = 25 | 0.645 | 0.844 | 1550 |

El costo es $O(MN)$: dos restas, un máximo, una comparación y unas pocas operaciones aritméticas por píxel, todo en uint8. El umbral no cambia el costo (no se hizo barrido).

Este resultado es una lección de implementación: no se convierte a double ni se pintan los canales con indexación lógica (`R(mascara) = 255`, etcétera). Con la saturación de uint8 y la máscara como factor aritmético, todo son operaciones enteras sobre la matriz completa, y por eso la operación mide 0.65 ms.

## Limitaciones

- Supone la cámara fija. Si la cámara se mueve, toda la imagen cambia y se marca casi todo.
- Es sensible a cambios de iluminación global: con exposición automática, el ajuste de la cámara cambia el brillo de toda la escena y aparece movimiento falso. Por eso `configuracion.m` fija la exposición manual.
- Marca la diferencia simétrica, no el objeto: no se obtiene la silueta completa, y un objeto liso y lento casi no se detecta.
- No da dirección ni velocidad; para eso está `block_matching.md`.
- Depende de la tasa de cuadros: a más FPS, menos cambia un objeto entre cuadros y menos se marca.
- Supone que `p.anterior` tiene el mismo tamaño que la entrada; si la resolución cambiara a media ejecución, la resta fallaría.
