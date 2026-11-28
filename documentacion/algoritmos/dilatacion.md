# Dilatación

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+morfologia/dilatacion.m` |
| Categoría | Morfología (filtro no lineal de orden) |
| Parámetros | `tamano`: mín 3, máx 15, inicial 5, paso 2 (lado del cuadrado) |
| Entrada / salida | uint8 gris o logical M×N / del mismo tipo, M×N |
| Prueba | `pruebas/test_dilatacion.m` |

## Qué hace y para qué sirve

Reemplaza cada píxel por el valor máximo de su vecindad cuadrada de $n \times n$. Es la operación dual de la erosión: las regiones claras crecen, las oscuras se encogen y desaparecen los huecos y detalles oscuros más pequeños que la ventana. Un punto brillante se convierte en un cuadrado de $n \times n$; un objeto blanco gana una capa de $r = (n - 1)/2$ píxeles en todo su contorno. Sirve para rellenar huecos, unir fragmentos cercanos de un mismo objeto y, combinada con la erosión, para el cierre morfológico.

## Fundamento matemático

Con el mismo elemento estructurante plano $B = \{-r, \dots, r\}^2$, $n = 2r + 1$:

$$(f \oplus B)(x, y) = \max_{(s, t) \in B} f(x - s,\ y - t)$$

Como $B$ es simétrico, el signo de $s$ y $t$ no importa y la fórmula es el máximo sobre la ventana centrada en $(x, y)$. En el caso binario el máximo es un OR: el píxel queda en 1 si algún vecino es 1.

Propiedades que conviene saber defender:

- Es extensiva: $f \oplus B \ge f$ en cada píxel. Nunca oscurece la imagen.
- Es creciente y conmuta con el máximo: dilatar el máximo de dos imágenes es el máximo de las dilataciones. Por eso, donde se traslapan dos puntos dilatados, gana el mayor.
- Es dual de la erosión: $f \oplus B = 255 - \big( (255 - f) \ominus B \big)$.
- Es separable para el cuadrado: el máximo en $n \times n$ es el máximo por columnas seguido del máximo por renglones, con $2(n - 1)$ comparaciones por píxel en lugar de $n^2 - 1$.

Fuera de la imagen se rellena replicando la orilla más cercana, igual que en la erosión. Como el valor replicado ya está dentro de la ventana, el relleno no altera el resultado: es equivalente a tomar el máximo solo sobre los vecinos que existen. Es lo mismo que hace `imdilate`.

## Relación con el curso

- Práctica 4 del curso (filtros espaciales): filtro no lineal de estadística de orden, pariente de la mediana, que se queda con el mayor valor de la vecindad.
- `erosion.md`: la operación dual. Explicar las dos juntas es la forma más clara de defenderlas.
- La separabilidad es la misma idea del filtro binomial de la Tarea 3, aplicada al máximo en lugar de a una suma ponderada.

## Implementación

1. `n = round(p.tamano);` y, si es par, `n = n + 1`; `r = (n - 1) / 2`.
2. Índices con relleno por replicación: `idx_col = min(max(1-r:N+r, 1), N)` e `idx_fil = min(max(1-r:M+r, 1), M)`; lo que cae fuera apunta a la orilla más cercana.
3. Máximo por renglones: `salida = entrada(:, idx_col(1:N))` y el ciclo `for k = 2:n` hace `salida = max(salida, entrada(:, idx_col(k:k+N-1)))`, una ventana deslizante horizontal de $n$ columnas.
4. Máximo por columnas sobre ese resultado, con el mismo ciclo y `idx_fil`.
5. Cada vuelta compara la imagen completa de una sola vez; los ciclos son sobre los $n$ desplazamientos, no sobre los píxeles.
6. Si la entrada es logical, la salida se regresa como logical.
7. El parámetro es `p.tamano`, de 3 a 15 en pasos de 2 con inicial 5 (`registro.m`, entrada 11).

La implementación es la misma de `erosion.m` cambiando `min` por `max`.

## Verificación

`pruebas/test_dilatacion.m` pasa en MATLAB R2026b (incluida la comparación con `imdilate`) y en Octave 11.3. Revisa:

- Un punto de 200 crece a un cuadrado de 3×3 con $n = 3$ y de 5×5 con $n = 5$.
- `tamano` = 4 da lo mismo que 5.
- Dos puntos de 50 y 120 cuyas dilataciones se traslapan: en el traslape queda 120.
- Una imagen constante no cambia, tampoco en la orilla.
- Un escalón avanza $r$ píxeles hacia lo oscuro (2 píxeles con $n = 5$).
- La salida nunca es menor que la entrada (extensividad) en una imagen aleatoria con $n = 9$.
- Coincide en toda la imagen con un máximo calculado píxel por píxel con dos ciclos, para $n = 3, 5, \dots, 15$.
- Una imagen más chica que la ventana toma el máximo global.
- Con entrada logical la salida es logical (un punto crece a 3×3 y uno en la esquina a 2×2).
- Contra `imdilate(A, ones(n))` coincide exactamente en el interior para $n = 3$ a 15. Con el relleno por replicación también coincide en las orillas, porque el máximo no cambia al repetir la orilla.

## Costo medido

De [`barridos.csv`](../experimentos/figuras/barridos.csv) (mediana de 10, MATLAB R2026b, 640×480):

| tamano | 3 | 5 | 7 | 9 | 11 | 13 | 15 |
|--------|---|---|---|---|----|----|----|
| ms | 1.275 | 2.265 | 3.100 | 3.963 | 4.916 | 5.753 | 6.709 |

En la tabla de tiempos, con `tamano` = 5: 2.192 ms de mediana, 2.559 ms de p90 y 456 FPS máximos.

Crece de forma aproximadamente lineal con $n$ (un ajuste por mínimos cuadrados da unos $0.45\,n$ ms), igual que la erosión, porque hace $2(n - 1)$ comparaciones de imagen completa: $O(n \cdot MN)$. Con el mismo $n$ tarda lo mismo que la erosión o un poco menos (entre 75 y 100 % de su tiempo según el punto del barrido), porque usa los mismos índices replicados.

Figuras: [barrido_dilatacion.png](../experimentos/figuras/barrido_dilatacion.png) (tiempo contra `tamano`) y [mosaico_dilatacion_tamano_3_7_15.png](../experimentos/figuras/mosaico_dilatacion_tamano_3_7_15.png) (original y salidas con tamano 3, 7 y 15).

## Limitaciones

- El elemento estructurante es siempre cuadrado, con la misma anisotropía que en la erosión. La especificación del proyecto deja como opcional elegir la forma del elemento estructurante (disco, cruz, línea); esa opción no se implementó y queda como limitación: el único parámetro es `tamano`, el lado del cuadrado.
- Una dilatación sola engorda todos los objetos claros, incluido el ruido; para rellenar huecos sin cambiar el tamaño se usa el cierre (dilatación seguida de erosión), que el pipeline no puede encadenar.
- El costo crece linealmente con $n$; con $n = 15$ son unos 7 ms, dentro del presupuesto del cuadro.
