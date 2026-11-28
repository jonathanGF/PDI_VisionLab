# Block matching (SAD)

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+movimiento/block_matching.m` |
| Categoría | Movimiento (estimación de flujo por bloques) |
| Parámetros | `bloque`: mín 8, máx 32, inicial 16, paso 8; `radio`: mín 1, máx 6, inicial 3, paso 1; además recibe `p.anterior` |
| Entrada / salida | uint8 gris M×N / RGB uint8 M×N×3 con flechas verdes (y, como segunda y tercera salida, las matrices `dy`, `dx`) |
| Prueba | `pruebas/test_block_matching.m` |

## Qué hace y para qué sirve

Estima hacia dónde se movió cada parte de la imagen entre el cuadro anterior y el actual. Divide el cuadro actual en bloques cuadrados y, para cada uno, busca en el cuadro anterior la posición cercana que más se le parece; el desplazamiento entre las dos posiciones es el vector de movimiento del bloque. El resultado se dibuja como una flecha verde por bloque sobre la imagen en gris. A diferencia de la diferencia de cuadros (`diferencia_cuadros.md`), que solo dice dónde hubo cambio, esta operación da dirección y magnitud. Es la técnica de estimación de movimiento de los codificadores de video (MPEG, H.264).

## Fundamento matemático

Primero el cuadro actual $f_t$ y el anterior $f_{t-1}$ se reducen a la mitad tomando un píxel de cada dos en cada eje: $A(i, j) = f_t(2i - 1,\ 2j - 1)$ y $P(i, j) = f_{t-1}(2i - 1,\ 2j - 1)$. Con 640×480 quedan de 320×240. Esto divide el costo entre 4.

$A$ se parte en bloques $b$ de $B \times B$ píxeles (`bloque`). Para cada bloque se evalúan todos los desplazamientos $(d_y, d_x)$ en la ventana de búsqueda $[-R, R]^2$ (`radio`) con la suma de diferencias absolutas:

$$\text{SAD}_b(d_y, d_x) = \sum_{(y, x) \in b} \big| A(y, x) - P(y - d_y,\ x - d_x) \big|$$

y se elige el que la minimiza:

$$(d_y^*, d_x^*) = \arg\min_{(d_y, d_x) \in [-R, R]^2} \text{SAD}_b(d_y, d_x)$$

El bloque actual en $(y, x)$ se compara con el anterior en $(y - d_y, x - d_x)$, así que el vector indica hacia dónde se movió el contenido: del cuadro anterior al actual. Es una búsqueda exhaustiva (full search): se prueban los $(2R + 1)^2$ candidatos, lo que garantiza el mínimo global dentro de la ventana.

Dos reglas completan la definición:

- Desempate: se parte del desplazamiento cero y solo se reemplaza el mejor si un candidato es estrictamente menor. En un empate (por ejemplo, un bloque plano donde todos los desplazamientos dan la misma SAD) gana "sin movimiento".
- Bordes: el cuadro anterior reducido se rodea de $R$ píxeles con valor $+\infty$. Un desplazamiento cuya ventana sale de la imagen da SAD infinita y nunca gana.

La SAD asume constancia del brillo: el mismo objeto conserva su nivel de gris entre dos cuadros seguidos. Por eso basta comparar diferencias absolutas, que son más baratas que la correlación.

Conversión al cuadro original: un bloque de $B \times B$ en el cuadro reducido cubre $2B \times 2B$ píxeles en el original, y un desplazamiento $(d_y, d_x)$ equivale a $2(d_y, d_x)$ píxeles. Con radio $R$ se detectan movimientos de hasta $2R$ píxeles por cuadro (6 px con el radio inicial $R = 3$, 12 px con $R = 6$), con una resolución de 2 píxeles.

## Relación con el curso

- Práctica 3 (histogramas), ejercicio 2, sección 3: para alinear el mosaico satelital se toma un patrón de la zona A y se busca exhaustivamente, columna por columna, la posición de la zona B donde la correlación cruzada normalizada (NCC) es máxima. El block matching es la misma búsqueda exhaustiva, en dos dimensiones, por bloques y con SAD en lugar de NCC. La NCC resta la media y divide entre la norma, así que es invariante a cambios de brillo y contraste (necesario entre dos tomas satelitales distintas); la SAD no lo es, pero es mucho más barata, y entre dos cuadros seguidos de la misma cámara con exposición fija el brillo casi no cambia.
- Práctica 5 (kernels separables e interpolación), inciso 1: al intercalar ceros para agrandar la imagen, el espectro aparece repetido (4 copias con factor 2), y por eso hace falta un pasabajas para interpolar. Reducir tomando uno de cada dos píxeles es la operación inversa: sin un pasabajas previo, las réplicas del espectro se traslapan (aliasing); ver Limitaciones.
- `diferencia_cuadros.md`: la otra operación de movimiento del sistema.

## Implementación

1. `B = round(p.bloque); R = round(p.radio);` y `A = double(entrada(1:2:end, 1:2:end));` reducen el cuadro actual a la mitad.
2. `nby = floor(h / B); nbx = floor(w / B);` cuentan los bloques completos y `A` se recorta a esa zona. `dy` y `dx` empiezan en ceros.
3. Si hay cuadro anterior: se reduce igual (`P`), se crea `Pr = Inf(h + 2*R, w + 2*R)` y se copia `P` en el centro.
4. `mejor = sad_bloques(A, Pr(...), B, nby, nbx);` calcula la SAD del desplazamiento cero, que queda como mejor inicial (regla de desempate).
5. `[DX, DY] = meshgrid(-R:R, -R:R);` lista los $(2R + 1)^2$ desplazamientos. Hay un solo ciclo sobre ellos: en cada vuelta se recorta `Ps` (el anterior desplazado), se calcula la SAD de todos los bloques a la vez y, donde `sad < mejor`, se actualizan `mejor`, `dy` y `dx`.
6. La subfunción `sad_bloques` calcula `D = abs(A - Ps)` y separa los bloques con `reshape(D, B, nby, B, nbx)`: la dimensión 1 es el renglón dentro del bloque y la 3 la columna dentro del bloque, así que `sum(sum(..., 1), 3)` da la SAD de cada bloque sin ciclos.
7. Dibujo: el centro de cada bloque en el original es `yc = (ii - 1) * 2*B + B` (igual `xc`) y la punta es el centro más `2*dy`, `2*dx`. Solo se dibujan los bloques con vector distinto de cero.
8. La cabeza son dos segmentos de 3 píxeles girados $\pm 35°$ hacia atrás desde la punta. Los tres segmentos de cada flecha se trazan juntos por interpolación lineal entre extremos (`linspace` con suficientes muestras para no dejar huecos), se redondean a píxeles, se descartan los que caen fuera y se pintan en verde puro (0, 255, 0). `salida = cat(3, Rc, G, Bc)`.
9. Parámetros en `registro.m`, entrada 13: `bloque` de 8 a 32 en pasos de 8 (inicial 16) y `radio` de 1 a 6 (inicial 3). El máximo de 6 se fijó para que la operación no pase de unos 33 ms. El inicial es 3 porque con 4 la operación tarda unos 31 ms dentro del lazo y el sistema queda en 18.1 FPS; con 3 tarda 11.3 ms sola y unos 19.7 ms dentro del lazo, y el sistema sube a 24.0 FPS (ver [resultados.md](../experimentos/resultados.md)).

## Verificación

`pruebas/test_block_matching.m` pasa en MATLAB R2026b y en Octave 11.3. Revisa:

- Una textura aleatoria suave de 128×192 desplazada 4 píxeles a la derecha con `circshift` (bloque 8, radio 4): al menos el 90 % de los bloques interiores da $d_x = 2$, $d_y = 0$ (4 píxeles en el original son 2 en el reducido).
- La flecha del bloque (3, 5), revisada a mano: cuerpo verde en la fila 40, columnas 72 a 76, y cabeza en (38, 74) y (42, 74). Fuera de las flechas la salida es el gris en los tres canales.
- Desplazamiento vertical de 6 píxeles: $d_y = 3$, $d_x = 0$. Desplazamiento diagonal $[-2, -6]$ con bloque 16: $d_y = -1$, $d_x = -3$.
- Con `p.anterior = []` y con cuadros idénticos: vectores en cero y salida igual al gris replicado.
- Con un tamaño impar (97×131) la salida conserva el tamaño original.
- Comparación exacta, bloque por bloque, contra una búsqueda de referencia con ciclos anidados sobre imágenes aleatorias, con el mismo orden de revisión y el mismo desempate.
- El Image Processing Toolbox no tiene una función equivalente, así que no hay comparación contra toolbox.

## Costo medido

De [`tiempos_operaciones.csv`](../experimentos/figuras/tiempos_operaciones.csv) (MATLAB R2026b, 640×480, mediana de 20), medida con `bloque` = 16 y `radio` = 3 (los parámetros iniciales): 11.343 ms de mediana, 14.797 ms de p90 y 88 FPS máximos. El barrido de radio da 14.346 ms para el mismo punto, una diferencia dentro de la variación entre corridas. Es la operación más cara del sistema.

Barridos de [`barridos.csv`](../experimentos/figuras/barridos.csv) (mediana de 10; el barrido de radio usa `bloque` = 16 y el de bloque usa `radio` = 3):

| radio | 1 | 2 | 3 | 4 | 5 | 6 |
|-------|---|---|---|---|---|---|
| desplazamientos $(2R+1)^2$ | 9 | 25 | 49 | 81 | 121 | 169 |
| ms | 3.282 | 7.691 | 14.346 | 22.233 | 37.601 | 33.519 |

| bloque | 8 | 16 | 24 | 32 |
|--------|---|----|----|----|
| vectores (640×480) | 1200 | 300 | 130 | 70 |
| ms | 14.575 | 15.865 | 11.054 | 9.859 |

El radio es el parámetro que manda. Cada desplazamiento recorre el cuadro reducido completo (unos 76 800 píxeles), así que el costo es $O\big((2R + 1)^2 \cdot MN/4\big)$. Un ajuste por mínimos cuadrados de los seis puntos da

$$t \approx 0.214\,(2R + 1)^2 + 3.59 \text{ ms}$$

con $R^2 = 0.88$, es decir, unos 0.2 ms por desplazamiento más un costo fijo de reducir, recortar y dibujar. El ajuste es peor que antes porque el punto de $R = 5$ (37.6 ms) quedó por encima del de $R = 6$ (33.5 ms), ruido de la medición. Con el radio inicial $R = 3$ el ajuste da 14.1 ms, cerca de los 14.3 ms del barrido. Con $R = 6$ se llega a más de 33 ms, el límite de 30 FPS; por eso el registro no permite más.

El tamaño del bloque casi no cambia el tiempo (9.9 a 15.9 ms), porque cada desplazamiento recorre toda la imagen sin importar cómo se divida. Lo que cambia es la resolución del campo de vectores: muchos vectores pequeños con bloque 8 y pocos grandes con bloque 32.

Figuras: [barrido_bm_radio.png](../experimentos/figuras/barrido_bm_radio.png) (tiempo contra `radio`) y [barrido_bm_bloque.png](../experimentos/figuras/barrido_bm_bloque.png) (tiempo contra `bloque`).

## Limitaciones

- Problema de apertura: en zonas planas o con bordes rectos, muchos desplazamientos dan la misma SAD y el vector no es confiable. En zonas completamente planas gana el cero por la regla de desempate; en zonas casi planas, el ruido puede dar vectores falsos, sobre todo con bloques pequeños.
- La reducción toma un píxel de cada dos sin filtrar antes. Texturas finas pueden producir aliasing y vectores erróneos; un suavizado binomial antes de submuestrear lo evitaría a cambio de más costo.
- Precisión entera en el cuadro reducido: los vectores son múltiplos de 2 píxeles en el original y no hay estimación subpíxel. Con radio 1 o 2 las flechas miden 2 a 4 píxeles y apenas se ven.
- Los bloques de la orilla no pueden dar vectores que apunten hacia afuera (esos candidatos tienen SAD infinita); ahí gana el vector cero aunque haya movimiento real.
- Los renglones y columnas que no completan un bloque no se analizan. Con 640×480 y bloque 24 se pierden 16 columnas del original a la derecha; con bloque 32, 32 renglones abajo.
- La SAD no tolera cambios de brillo entre cuadros; con exposición automática daría vectores falsos (por eso la exposición es manual en `configuracion.m`).
- Un solo vector por bloque: si en un bloque hay dos objetos con movimientos distintos, el vector es un compromiso. Movimientos de más de $2R$ píxeles por cuadro no se detectan.
