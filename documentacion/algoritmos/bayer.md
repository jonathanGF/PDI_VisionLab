# Dithering ordenado de Bayer

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+tramado/bayer.m` |
| Categoría | Dithering y cuantización |
| Parámetros | `orden`: mín 1, máx 3, inicial 2, paso 1 (1: 2×2, 2: 4×4, 3: 8×8) |
| Entrada / salida | uint8 gris M×N / logical M×N |
| Prueba | `pruebas/test_bayer.m` |

## Qué hace y para qué sirve

Convierte la imagen en gris a una imagen binaria (solo blanco y negro) que, vista de lejos, todavía parece tener tonos intermedios. En lugar de comparar todos los píxeles contra un umbral fijo, como `umbral.md`, cada píxel se compara contra un umbral que depende de su posición dentro de un patrón que se repite. En una zona de gris medio se encienden la mitad de los píxeles del patrón, en una zona clara casi todos y en una oscura casi ninguno; el ojo promedia esa densidad y percibe el gris. Es la técnica de las impresoras y pantallas de 1 bit.

## Fundamento matemático

La matriz de índices de Bayer se construye por recursión a partir de la de 2×2:

$$M_2 = \begin{bmatrix} 0 & 2 \\ 3 & 1 \end{bmatrix}, \qquad M_{2n} = \begin{bmatrix} 4M_n & 4M_n + 2 \\ 4M_n + 3 & 4M_n + 1 \end{bmatrix}$$

De ahí salen, con `orden` 1, 2 y 3, las matrices de $n = 2^{\text{orden}}$, es decir 2×2, 4×4 y 8×8. Cada una contiene los índices $0, \dots, n^2 - 1$ una sola vez, ordenados de forma que píxeles con índices consecutivos queden lo más separados posible; así el patrón no forma grumos. La de 4×4 es la de la Práctica 2:

$$M_4 = \begin{bmatrix} 0 & 8 & 2 & 10 \\ 12 & 4 & 14 & 6 \\ 3 & 11 & 1 & 9 \\ 15 & 7 & 13 & 5 \end{bmatrix}$$

Los índices se convierten en umbrales repartidos de forma uniforme en $(0, 1)$, centrados en cada intervalo:

$$T(i, j) = \frac{M(i, j) + 0.5}{n^2}$$

y la salida es

$$g(x, y) = \begin{cases} 1, & \dfrac{f(x, y)}{255} \ge T(x \bmod n,\ y \bmod n) \\ 0, & \text{en otro caso} \end{cases}$$

Para una zona de gris constante $f$, el número de píxeles encendidos en cada bloque de $n \times n$ es el número de índices que cumplen $M \le n^2 f/255 - 0.5$, que es aproximadamente $n^2 f / 255$. La densidad de blancos es proporcional al gris. Como en un bloque pueden encenderse de 0 a $n^2$ píxeles, se reproducen $n^2 + 1$ niveles aparentes: 5 con 2×2, 17 con 4×4 y 65 con 8×8 (se comprobó contando sobre los 256 niveles de entrada).

## Relación con el curso

- Práctica 2 del curso (dithering), inciso c: el código de la práctica define a mano `M2` y `M4`, calcula `T = (M + 0.5) / n^2`, repite el patrón con `repmat` y compara `I >= patron(1:H, 1:W)`. Esta operación es exactamente ese código, con dos cambios: la matriz se genera por recursión (lo que añade la 8×8) y el tamaño se elige con un deslizador. La prueba lo comprueba píxel por píxel contra el código de la práctica.
- Práctica 2, incisos a, b y d: el umbral fijo (`umbral.md` con 128), el dithering aleatorio y Floyd-Steinberg. Floyd-Steinberg no se implementó porque difunde el error píxel por píxel en orden (cada píxel depende de los anteriores) y no se puede vectorizar; con dos ciclos anidados sobre 307 200 píxeles no cabría en el presupuesto de un cuadro de video. Bayer, en cambio, es una sola comparación por píxel.

## Implementación

1. `M = [0, 2; 3, 1];` es la matriz base de la Práctica 2.
2. El ciclo `for k = 2:round(p.orden)` aplica la regla recursiva `M = [4*M, 4*M + 2; 4*M + 3, 4*M + 1]`. Con `orden` = 1 el ciclo no se ejecuta y queda la 2×2. Es el único ciclo y tiene a lo más dos vueltas.
3. `n = size(M, 1);` y `T = (M + 0.5) / n^2;` calculan los umbrales normalizados.
4. `patron = repmat(T, ceil(H/n), ceil(W/n));` repite el patrón hasta cubrir la imagen, redondeando hacia arriba para que alcance aunque el tamaño no sea múltiplo de $n$.
5. `salida = double(entrada) / 255 >= patron(1:H, 1:W);` normaliza la imagen a $[0, 1]$, recorta el patrón al tamaño exacto y compara. La salida es logical.
6. El parámetro es `p.orden`, entero de 1 a 3 (`registro.m`, entrada 5).

## Verificación

`pruebas/test_bayer.m` pasa en MATLAB R2026b y en Octave 11.3. Revisa:

- Para cada orden, recupera el orden en que se encienden los píxeles al subir el gris de 0 a 255. Con orden 1 reproduce `[0 2; 3 1]` y con orden 2 reproduce la $M_4$ de la Práctica 2. En la 8×8 revisa que estén los valores 0 a 63 una sola vez y que la esquina sea `[0 32; 48 16]`.
- Casos hechos a mano: gris 128 con la 4×4 enciende exactamente los píxeles con $M \le 7$ (la mitad); gris 64 con la 2×2 enciende solo el de $M = 0$.
- Una imagen negra da todo 0 y una blanca todo 1, en los tres órdenes.
- Con un tamaño que no es múltiplo del patrón (5×7) la salida conserva el tamaño.
- Sobre una imagen aleatoria de 37×50, la salida es idéntica a la del código de la Práctica 2 para 2×2 y 4×4.
- No se compara contra el toolbox porque `dither()` del Image Processing Toolbox usa difusión de error, no Bayer ordenado.

## Costo medido

De [`tiempos_operaciones.csv`](../experimentos/figuras/tiempos_operaciones.csv) y [`barridos.csv`](../experimentos/figuras/barridos.csv) (MATLAB R2026b, 640×480):

| Medición | orden 1 (2×2) | orden 2 (4×4) | orden 3 (8×8) |
|----------|--------------:|--------------:|--------------:|
| Tabla de tiempos (mediana de 20) | | 3.477 ms (p90 3.843) | |
| Barrido (mediana de 10) | 3.067 ms | 3.035 ms | 3.088 ms |

El orden no cambia el costo: siempre es una división y una comparación por píxel, $O(MN)$, contra un patrón ya repetido. Construir la matriz cuesta a lo más 64 elementos. La diferencia entre la tabla (3.5 ms) y el barrido (3.0 ms) con el mismo orden 2 está dentro de la variación de ±30 % entre corridas descrita en las condiciones de medición de [indice.md](indice.md). Lo que sí cambia con el orden es la calidad: más niveles aparentes y una textura más fina.

Figuras: [barrido_bayer.png](../experimentos/figuras/barrido_bayer.png) (tiempo contra `orden`) y [mosaico_bayer_orden_1_2_3.png](../experimentos/figuras/mosaico_bayer_orden_1_2_3.png) (original y salidas con orden 1, 2 y 3, sobre la imagen estándar `peppers.png` ampliada a 640×480). El PSNR contra el original es de 7.03, 7.34 y 7.33 dB: bajo en los tres órdenes porque se compara una imagen binaria con una en gris (ver [resultados.md](../experimentos/resultados.md)).

## Limitaciones

- El patrón es visible: la textura en forma de cruces (cross-hatch) es característica del dithering ordenado y se nota más en zonas grandes de gris uniforme. Floyd-Steinberg da un resultado más natural, pero no es vectorizable.
- El patrón está fijo a la posición de la pantalla, no al objeto: si la cámara o el objeto se mueven, la textura parece deslizarse sobre la imagen.
- `p.orden` se redondea con `round()` pero no se valida su rango; un orden menor que 1 deja la 2×2 y uno mayor que 3 genera matrices más grandes. El deslizador solo entrega 1, 2 o 3.
- La salida tiene 1 bit por píxel; los niveles aparentes dependen de que el observador promedie, así que en una ampliación se ven solo puntos.
