# Bordes con binomial de orden 1

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+filtrado/bordes_binomial.m` |
| Categoría | Filtrado y bordes (gradiente) |
| Parámetros | `longitud`: mín 3, máx 11, inicial 5, paso 2; `umbral`: mín 0, máx 255, inicial 0, paso 1 |
| Entrada / salida | uint8 gris M×N / uint8 gris M×N si `umbral` = 0, logical M×N si `umbral` > 0 |
| Prueba | `pruebas/test_bordes_binomial.m` |

## Qué hace y para qué sirve

Resalta los bordes, es decir, los lugares donde la intensidad cambia rápido. Calcula una aproximación del gradiente de la imagen en $x$ y en $y$ con kernels binomiales y combina las dos componentes en una magnitud. Con `umbral` = 0 muestra la magnitud en gris (bordes fuertes en blanco, zonas planas en negro); con `umbral` mayor que 0 muestra un mapa binario de bordes. Es la base de la detección de contornos y de la segmentación por bordes.

## Fundamento matemático

El gradiente de $f$ es $\nabla f = (\partial f/\partial x,\ \partial f/\partial y)$. Derivar directamente amplifica el ruido, así que cada derivada se combina con un suavizado. Con kernels binomiales, como en la Tarea 3, se usan dos vectores de longitud $N$:

- Suavizado: el binomial normalizado de $N$ elementos, $s = h_N$ (ver `binomial.md`).
- Derivada de orden 1: el binomial de $N - 1$ elementos convolucionado con la diferencia $[1\ {-1}]$, sin normalizar:
  $$d_N = b_{N-1} * [1\ {-1}], \qquad b_{N-1}(k) = \binom{N-2}{k}$$

  Con $N = 3$, $d = [1\ 0\ {-1}]$ (diferencia central); con $N = 5$, $d = [1\ 2\ 0\ {-2}\ {-1}]$; con $N = 7$, $d = [1\ 4\ 5\ 0\ {-5}\ {-4}\ {-1}]$. Siempre suma 0, así que no responde en zonas de intensidad constante.

Las dos componentes del gradiente son filtros separables, producto exterior de un vector columna y uno fila:

$$g_x = (s^{\top} d) * f, \qquad g_y = (d^{\top} s) * f$$

$g_x$ deriva a lo largo de los renglones y suaviza a lo largo de las columnas, así que responde a bordes verticales; $g_y$ hace lo contrario. Con $N = 3$, $s^{\top} d = \tfrac{1}{4} [1\ 2\ 1]^{\top} [1\ 0\ {-1}]$, que es el operador de Sobel dividido entre 4.

La magnitud se aproxima con la norma $L_1$ en lugar de la euclidiana, y se escala para que el máximo del cuadro quede en 255:

$$|\nabla f| \approx |g_x| + |g_y|, \qquad e(x, y) = \operatorname{round}\!\left( 255 \frac{|\nabla f|(x, y)}{\max |\nabla f|} \right)$$

Con `umbral` $= T > 0$ la salida es $e(x, y) \ge T$.

En frecuencia, la respuesta del kernel de derivada es (en magnitud)

$$|D_N(\omega)| = 2 \sin\!\left( \frac{\omega}{2} \right) \left( 2 \cos \frac{\omega}{2} \right)^{N-2}$$

Es un pasabanda: vale 0 en $\omega = 0$ (no responde a zonas planas) y también en $\omega = \pi$ (no responde al ruido de más alta frecuencia). El pico se mueve hacia frecuencias más bajas al crecer $N$: está en $\omega = 0.5\pi$ con $N = 3$, $0.33\pi$ con $N = 5$ y $0.21\pi$ con $N = 11$. Por eso un kernel más largo es menos sensible al ruido, pero da bordes más gruesos.

## Relación con el curso

- Tarea 3 del curso (operadores de derivada): construye cada vector como `convolución(suavizado, operador_derivada)` con el operador de orden 1 `[1, -1]`, y el filtro 2D como producto exterior. El vector de la dirección Y de esa tarea, `[1, 4, 5, 0, -5, -4, -1]`, es exactamente el $d_7$ de esta operación. La tarea también explica que los kernels de derivada no se normalizan porque ya suman 0; aquí tampoco se normaliza $d$.
- Tarea 2 (coeficientes binomiales): los coeficientes $b_{N-1}$.
- `binomial.md`: el vector de suavizado $s$ es el mismo kernel del suavizado binomial.

## Implementación

1. `N = p.longitud;` y bordes replicados por indexación igual que en `binomial.m`: con `r = floor(N / 2)`, `f = double(entrada(filas, columnas))` es la imagen ampliada $r$ píxeles por lado.
2. El ciclo `for k = 1:N-2`, con `b = conv(b, [1 1])`, da los $N - 1$ coeficientes binomiales.
3. `d = conv(b, [1 -1]);` es la derivada de orden 1 de $N$ elementos.
4. `s = conv(b, [1 1]); s = s / sum(s);` es el suavizado binomial de $N$ elementos normalizado.
5. `gx = conv2(s(:), d(:)', f, 'valid');` y `gy = conv2(d(:), s(:)', f, 'valid');` son las dos componentes separables. Con `'valid'` sobre la imagen ampliada el resultado tiene el tamaño original.
6. `magnitud = abs(gx) + abs(gy);` y, si el máximo `m` es mayor que 0, `escalada = uint8(255 * magnitud / m)`. Si la imagen es plana (`m` = 0) la salida es de ceros, sin dividir entre cero.
7. Con `p.umbral == 0` la salida es `escalada`; con `p.umbral > 0` es `escalada >= p.umbral` (logical).
8. Parámetros en `registro.m`, entrada 8: `longitud` de 3 a 11 en pasos de 2 (inicial 5) y `umbral` de 0 a 255 (inicial 0).

## Verificación

`pruebas/test_bordes_binomial.m` pasa en MATLAB R2026b (incluida la comparación con `imfilter`) y en Octave 11.3. Revisa:

- Un impulso de 7×7 con $N = 3$: $|g_x| + |g_y|$ vale 0.5 en los 8 vecinos y 0 en el centro, así que los vecinos quedan en 255 y el centro en 0 (calculado a mano).
- Un escalón vertical (columnas 1 a 10 en 0 y 11 a 20 en 200): con $N = 3$ solo responden las columnas 10 y 11, con el valor máximo, y las zonas planas valen 0. Con $N = 5$, las columnas 10 y 11 tienen el máximo y las 9 y 12 un tercio de él (200 frente a 600 antes de escalar). Gracias a la replicación de bordes el marco de la imagen ya no responde, y el máximo global cae en el escalón.
- Trasponer la entrada traspone la salida, con el escalón y con una imagen aleatoria con $N = 7$.
- Con `umbral` igual al valor del borde, la salida logical deja solo las columnas 10 y 11.
- Una imagen plana da cero en todas partes, orillas incluidas, para $N$ de 3 a 11; una imagen negra da ceros uint8 o todo falso, sin dividir entre cero.
- Contra `conv2` 2D con $s^{\top}d$ y $d^{\top}s$ sobre la imagen ampliada con `repmat`, y contra `imfilter` con `'replicate'`: diferencia máxima de 1 nivel (redondeo).

## Costo medido

De [`barridos.csv`](../experimentos/figuras/barridos.csv) (mediana de 10, MATLAB R2026b, 640×480, `umbral` = 0):

| longitud | 3 | 5 | 7 | 9 | 11 |
|----------|---|---|---|---|----|
| ms | 5.695 | 5.566 | 5.644 | 5.674 | 5.812 |

En la tabla de tiempos, con `longitud` = 5 y `umbral` = 0: 5.531 ms de mediana, 6.160 ms de p90 y 181 FPS máximos.

Hace dos convoluciones separables (cuatro pasadas 1D) más el valor absoluto, la suma y el escalado, así que cuesta un poco menos del doble que el suavizado binomial (3.1 ms). Como en el binomial, la longitud casi no cambia el tiempo: el costo teórico $O(4N \cdot MN)$ queda oculto por el costo fijo de recorrer la imagen varias veces. Las diferencias entre puntos del barrido (5.6 a 5.8 ms) están dentro de la variación de ±30 % entre corridas descrita en las condiciones de medición de [indice.md](indice.md). Binarizar con `umbral` > 0 agrega una comparación por píxel.

Figuras: [barrido_bordes.png](../experimentos/figuras/barrido_bordes.png) (tiempo contra `longitud`), [mosaico_bordes_u0_longitud_3_7.png](../experimentos/figuras/mosaico_bordes_u0_longitud_3_7.png) (magnitud en gris con longitud 3 y 7) y [mosaico_bordes_u60_longitud_3_7.png](../experimentos/figuras/mosaico_bordes_u60_longitud_3_7.png) (mapa binario con `umbral` = 60).

## Limitaciones

- La magnitud $|g_x| + |g_y|$ no es isotrópica: un borde diagonal da hasta $\sqrt{2}$ veces más respuesta que con la norma euclidiana $\sqrt{g_x^2 + g_y^2}$.
- El escalado es por el máximo de cada cuadro. El brillo de los bordes es relativo y puede cambiar de un cuadro a otro, y con `umbral` > 0 el número de bordes depende del contraste del cuadro: no es un umbral absoluto sobre el gradiente.
- No adelgaza los bordes ni los une: no hay supresión de no máximos ni histéresis como en Canny. Los bordes salen con un grosor que crece con $N$.
- Se pierde la dirección del gradiente; solo se muestra la magnitud.
- Si `longitud` llega par se usa `longitud + 1`, igual que en `binomial.m` y `laplaciano.m` (el deslizador ya avanza de 2 en 2 desde 3).
