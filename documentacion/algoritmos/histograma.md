# Histograma

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+adicionales/histograma.m` |
| Categoría | Adicionales (visualización) |
| Parámetros | Ninguno |
| Entrada / salida | uint8 gris M×N / uint8 M×N (fondo negro, barras blancas) |
| Prueba | `pruebas/test_histograma.m` |

## Qué hace y para qué sirve

Calcula el histograma de 256 niveles del cuadro y lo dibuja como una imagen del mismo tamaño que la entrada: 256 barras blancas sobre fondo negro que crecen desde el borde inferior. Como la salida es una imagen más, la interfaz la muestra igual que cualquier otro resultado, y el histograma se actualiza en vivo en cada cuadro. En la exposición sirve para mostrar qué pasa con la distribución de niveles al tapar la cámara, encender una luz o cambiar la exposición, y para explicar visualmente la ecualización y el umbral.

## Fundamento matemático

El histograma cuenta los píxeles de cada nivel:

$$h(k) = \#\{(x, y) : f(x, y) = k\}, \qquad k = 0, \dots, 255, \qquad \sum_k h(k) = MN$$

Dividido entre $MN$ es la estimación de la probabilidad de cada nivel, $p(k)$, de donde salen la media, la varianza (contraste) y la CDF que usan `ecualizacion.md` y `umbral.md`.

Para dibujarlo, cada conteo se normaliza al nivel más poblado y se escala a la altura $M$ de la imagen:

$$a(k) = \operatorname{round}\!\left( M \frac{h(k)}{\max_j h(j)} \right)$$

La barra más alta siempre ocupa toda la altura. Si la imagen tiene $N \ge 256$ columnas, la columna $c$ (con $c = 1, \dots, N$) muestra la barra

$$k(c) = \left\lfloor \frac{256\,(c - 1)}{N} \right\rfloor$$

y cada barra ocupa $\lfloor N/256 \rfloor$ columnas o una más (con $N = 640$, 2 o 3 columnas). Si $N < 256$, varias barras caen en la misma columna y se muestra la más alta. Un píxel en la fila $y$ (contando desde arriba) es blanco si $y > M - a(k(c))$.

## Relación con el curso

- Práctica 3 del curso (histogramas): todos los incisos piden desplegar el histograma con `imhist`. Aquí el conteo se hace a mano con `accumarray`, la misma línea que usa `ecualizacion.m`, y la prueba lo compara con `imhist`.
- El enunciado de la Práctica 3 señala que el bajo costo del histograma lo hace una de las herramientas más usadas en el procesamiento en tiempo real; esta operación lo comprueba con 2.4 ms por cuadro.

## Implementación

1. `[M, N] = size(entrada);` toma el tamaño del cuadro, que también será el de la salida.
2. `h = accumarray(double(entrada(:)) + 1, 1, [256 1]);` cuenta los píxeles de cada nivel (más 1 porque MATLAB indexa desde 1).
3. `alturas = round(M * h / max(h));` da la altura de cada barra en píxeles.
4. Si `N >= 256`: `barra = floor((0:N-1) * 256 / N) + 1;` asigna a cada columna su barra y `alt_col = alturas(barra)'` da la altura por columna.
5. Si `N < 256`: `columna = floor((0:255)' * N / 256) + 1;` asigna cada barra a una columna y `accumarray(columna, alturas, [N 1], @max)` se queda con la más alta de cada columna.
6. `salida = uint8(255) * uint8(filas > M - alt_col);` compara el vector columna de filas con el vector fila de alturas (expansión implícita) y forma la imagen completa de una sola vez: blanco dentro de la barra, negro fuera.
7. El argumento `p` no se usa (`sin_parametros` en `registro.m`, entrada 14).

## Verificación

`pruebas/test_histograma.m` pasa en MATLAB R2026b (incluida la comparación con `imhist`) y en Octave 11.3. Revisa:

- La salida es uint8 del mismo tamaño que la entrada y solo tiene valores 0 y 255.
- Una imagen constante de 40×512 con nivel 100 da una sola barra de altura completa en las columnas 201 y 202 (con 512 columnas cada nivel ocupa 2), comparada contra la imagen esperada exacta.
- Una imagen de 30×640 mitad 0 y mitad 255 da dos barras completas en los extremos (columnas 1 a 3 y 639 a 640) y ninguna otra.
- Un caso hecho a mano de 10×256 con conteos 1280, 640 y 640: alturas 10, 5 y 5, que crecen desde el borde inferior.
- Una imagen angosta de 8×64 (menos de 256 columnas) toma la barra más alta por columna.
- Contra `imhist(R, 256)` en una imagen de 120×300: las alturas por columna coinciden exactamente con $\operatorname{round}(M h / \max h)$ calculado con `imhist`.

## Costo medido

De [`tiempos_operaciones.csv`](../experimentos/figuras/tiempos_operaciones.csv) (MATLAB R2026b, 640×480, mediana de 20):

| ms mediana | ms p90 | FPS máx |
|-----------:|-------:|--------:|
| 2.358 | 2.928 | 424 |

El costo es $O(MN)$: un recorrido para contar con `accumarray` y la construcción de la imagen de salida por comparación (también $M \times N$). La parte que depende de los 256 niveles es despreciable. No hay parámetro.

## Limitaciones

- El eje vertical es lineal y normalizado al máximo: si un nivel concentra muchos píxeles (por ejemplo, una zona saturada en 255), todas las demás barras quedan muy bajas.
- Por el redondeo de $a(k)$, un nivel con pocos píxeles, pero no vacío, puede quedar con altura 0 y no verse.
- No hay ejes, escala ni números; es una vista cualitativa.
- Reemplaza la imagen en la pantalla: no se ve la escena y su histograma a la vez. Como el pipeline aplica una sola operación por cuadro, tampoco se puede ver el histograma del resultado de otra operación (por ejemplo, de la imagen ya ecualizada).
- Con menos de 256 columnas se pierde resolución, porque varias barras comparten columna (no ocurre a 640×480).
