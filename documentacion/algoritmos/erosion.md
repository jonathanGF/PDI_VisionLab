# Erosión

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+morfologia/erosion.m` |
| Categoría | Morfología (filtro no lineal de orden) |
| Parámetros | `tamano`: mín 3, máx 15, inicial 5, paso 2 (lado del cuadrado) |
| Entrada / salida | uint8 gris o logical M×N / mismo tipo y tamaño |
| Prueba | `pruebas/test_erosion.m` |

## Qué hace y para qué sirve

Reemplaza cada píxel por el valor mínimo de su vecindad cuadrada de $n \times n$. El efecto es que las regiones claras se encogen, las oscuras crecen y desaparecen los detalles brillantes más pequeños que la ventana (reflejos, puntos de ruido claro, líneas finas claras). En una imagen binaria, un objeto blanco pierde una capa de $r = (n - 1)/2$ píxeles en todo su contorno. Sirve para eliminar ruido de tipo "sal", separar objetos que se tocan por un puente delgado y, combinada con la dilatación, para la apertura morfológica.

## Fundamento matemático

Con un elemento estructurante plano $B$ (un cuadrado de $n \times n$ centrado en el origen, con $n = 2r + 1$), la erosión en escala de grises es

$$(f \ominus B)(x, y) = \min_{(s, t) \in B} f(x + s,\ y + t), \qquad B = \{-r, \dots, r\}^2$$

En el caso binario, el mínimo de valores 0 y 1 es un AND: el píxel queda en 1 solo si toda su vecindad es 1, es decir, si el elemento estructurante cabe completo dentro del objeto.

Propiedades que conviene saber defender:

- Es antiextensiva: como el origen está en $B$, $f \ominus B \le f$ en cada píxel. Nunca aclara la imagen.
- Es creciente: si $f \le g$ entonces $f \ominus B \le g \ominus B$.
- Es dual de la dilatación: para uint8, $f \ominus B = 255 - \big( (255 - f) \oplus B \big)$ (con $B$ simétrico). Erosionar lo claro es dilatar lo oscuro.
- Es separable para el cuadrado: como $B = \{-r, \dots, r\} \times \{-r, \dots, r\}$,
  $$\min_{(s, t) \in B} f(x + s, y + t) = \min_{s} \left( \min_{t} f(x + s, y + t) \right)$$
  El mínimo en $n \times n$ es el mínimo por renglones seguido del mínimo por columnas. Esto reduce las comparaciones por píxel de $n^2 - 1$ a $2(n - 1)$: con $n = 15$, 28 en lugar de 224.

No es un filtro lineal: no se puede escribir como una convolución y no tiene respuesta en frecuencia. Es un filtro de orden (de rango), como la mediana, pero en lugar de quedarse con el valor central de la vecindad ordenada se queda con el menor.

## Relación con el curso

- Práctica 4 del curso (filtros espaciales): la erosión es un filtro espacial no lineal de estadística de orden, de la misma familia que el filtro de mediana.
- `umbral.md`: con una imagen binaria (por ejemplo, la salida del umbral) la erosión equivale al AND de la vecindad. La función acepta entrada logical y la devuelve logical, aunque el pipeline actual solo le entrega uint8 gris porque aplica una operación por cuadro.
- La separabilidad es la misma idea que hace barato al suavizado binomial (`binomial.md`, Tarea 3), aplicada a un operador no lineal.

## Implementación

1. `n = round(p.tamano);` y, si es par, `n = n + 1`, para que la ventana tenga centro. `r = (n - 1) / 2`.
2. Relleno por replicación con índices: `idx_col = min(max(1-r:N+r, 1), N)` (y lo mismo `idx_fil`) lleva cada índice fuera de la imagen a la orilla más cercana. No se construye una imagen ampliada; solo un vector de índices.
3. Mínimo por renglones: `salida = entrada(:, idx_col(1:N))` y el ciclo `for k = 2:n` hace `salida = min(salida, entrada(:, idx_col(k:k+N-1)))`, que recorre los $n$ desplazamientos horizontales de la ventana. Cada vuelta compara la imagen completa de una sola vez.
4. Mínimo por columnas sobre ese resultado: el mismo ciclo con `temp(idx_fil(k:k+M-1), :)`.
5. Si la entrada era logical, `salida = logical(salida)`.
6. Los ciclos son sobre los $n$ desplazamientos (a lo más 15), no sobre los píxeles. El parámetro es `p.tamano`, de 3 a 15 en pasos de 2 con inicial 5 (`registro.m`, entrada 10).

## Verificación

`pruebas/test_erosion.m` pasa en MATLAB R2026b (incluida la comparación con `imerode`) y en Octave 11.3. Revisa:

- Un cuadro blanco de 5×5 queda de 3×3 con $n = 3$ y de un solo píxel con $n = 5$.
- Un píxel oscuro sobre fondo blanco crece a un bloque de 3×3.
- `tamano` = 4 da lo mismo que 5.
- Una rampa de 3×3 coincide con el cálculo a mano, lo que también comprueba el relleno por replicación en las orillas.
- Una imagen constante no cambia, ni siquiera en el borde.
- Con una ventana más grande que la imagen, todo queda en el mínimo global.
- Con entrada logical la salida es logical y un cuadro binario de 5×5 queda de 3×3.
- La versión separable coincide en todos los píxeles con un mínimo 2D directo calculado con dos ciclos, para $n = 3, 5, \dots, 15$.
- Contra `imerode(A, ones(n))`, en uint8 y en logical para $n = 3$ a 15, la igualdad es exacta en el interior. El marco de $r$ píxeles se excluye porque `imerode` rellena con el valor máximo y aquí se replica la orilla; es una diferencia de definición.

## Costo medido

De [`barridos.csv`](../experimentos/figuras/barridos.csv) (mediana de 10, MATLAB R2026b, 640×480):

| tamano | 3 | 5 | 7 | 9 | 11 | 13 | 15 |
|--------|---|---|---|---|----|----|----|
| ms | 1.690 | 2.549 | 3.381 | 4.205 | 5.207 | 5.775 | 6.761 |

En la tabla de tiempos, con `tamano` = 5: 2.166 ms de mediana, 2.424 ms de p90 y 462 FPS máximos.

Junto con la dilatación, es la única operación de ventana cuyo tiempo crece claramente con el parámetro, y lo hace de forma lineal: un ajuste por mínimos cuadrados da aproximadamente $0.42\,n$ ms. Coincide con el análisis: el algoritmo separable hace $2(n - 1)$ comparaciones de imagen completa, $O(n \cdot MN)$. A diferencia de la convolución, aquí cada desplazamiento es una pasada explícita sobre la imagen en MATLAB, por eso el costo variable no queda oculto. Una implementación 2D directa crecería con $n^2$.

Figuras: [barrido_erosion.png](../experimentos/figuras/barrido_erosion.png) (tiempo contra `tamano`) y [mosaico_erosion_tamano_3_7_15.png](../experimentos/figuras/mosaico_erosion_tamano_3_7_15.png) (original y salidas con tamano 3, 7 y 15).

## Limitaciones

- En las orillas el resultado no es igual al de `imerode`: aquí se replica el borde; `imerode` rellena con el valor máximo. En el interior son idénticos.
- El elemento estructurante es siempre un cuadrado: la erosión es anisotrópica (actúa más en las diagonales que un disco del mismo radio) y no hay otras formas (disco, línea, cruz). La especificación del proyecto deja como opcional elegir la forma del elemento estructurante (disco, cruz, línea); esa opción no se implementó y queda como limitación: el único parámetro es `tamano`, el lado del cuadrado.
- Una erosión sola también reduce los objetos que sí interesan; para quitar ruido sin cambiar el tamaño se usa la apertura (erosión seguida de dilatación), que el pipeline no puede encadenar porque aplica una sola operación por cuadro.
- El costo crece linealmente con $n$. Para elementos muy grandes existe el algoritmo de van Herk / Gil-Werman, de costo constante por píxel, pero con $n \le 15$ no hizo falta.
- `p.tamano` fuera de 3 a 15 no se recorta; con 1 la salida sería igual a la entrada.
