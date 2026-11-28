# Suavizado binomial

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+filtrado/binomial.m` |
| Categoría | Filtrado y bordes (filtro lineal pasabajas) |
| Parámetros | `longitud`: mín 3, máx 15, inicial 5, paso 2 (solo impares) |
| Entrada / salida | uint8 gris M×N / uint8 gris M×N |
| Prueba | `pruebas/test_binomial.m` |

## Qué hace y para qué sirve

Suaviza la imagen: cada píxel se reemplaza por un promedio ponderado de sus vecinos, con más peso en el centro y menos en las orillas de la ventana. Reduce el ruido del sensor y el detalle fino. Con `longitud` pequeña el efecto es leve; con 15 la imagen queda claramente borrosa. Es además la pieza con la que se construyen los detectores de bordes (`bordes_binomial.md`) y el laplaciano (`laplaciano.md`).

## Fundamento matemático

El kernel 1D de longitud $N$ es la fila $N - 1$ del triángulo de Pascal, normalizada a suma 1:

$$h_N(k) = \frac{1}{2^{N-1}} \binom{N-1}{k}, \qquad k = 0, \dots, N-1$$

Por ejemplo, $h_3 = \tfrac{1}{4}[1\ 2\ 1]$ y $h_5 = \tfrac{1}{16}[1\ 4\ 6\ 4\ 1]$. Se obtiene convolucionando $[1\ 1]$ consigo mismo $N - 1$ veces:

$$h_N \propto \underbrace{[1\ 1] * [1\ 1] * \cdots * [1\ 1]}_{N - 1 \text{ veces}}$$

Tres resultados que conviene saber defender:

1. Se parece a una gaussiana. Los coeficientes son la distribución binomial con $p = 1/2$, cuya varianza es $(N-1)/4$. Por el teorema del límite central, al crecer $N$ el kernel tiende a una gaussiana con
   $$\sigma = \frac{\sqrt{N - 1}}{2}$$
   que da $\sigma = 0.71$ con $N = 3$, $\sigma = 1$ con $N = 5$ y $\sigma = 1.87$ con $N = 15$.
2. Es un pasabajas sin rizos. Su respuesta en frecuencia (quitando la fase lineal) es
   $$H_N(\omega) = \cos^{N-1}\!\left( \frac{\omega}{2} \right)$$
   que vale 1 en $\omega = 0$ (no cambia el brillo promedio), decrece de forma monótona y vale 0 en $\omega = \pi$ (elimina por completo la frecuencia más alta, el patrón de ajedrez). Como nunca es negativa, no produce rizos (ringing) alrededor de los bordes, a diferencia de un filtro ideal.
3. Es separable. El kernel 2D es el producto exterior $h_{2D} = h_N^{\top} h_N$, así que filtrar con él es igual a filtrar primero las columnas y después los renglones:
   $$g = h_N^{\top} * (h_N * f)$$
   Esto cuesta $2N$ multiplicaciones por píxel en lugar de $N^2$: con $N = 15$, 30 en lugar de 225.

## Relación con el curso

- Tarea 2 del curso (coeficientes binomiales): genera los $N$ coeficientes binomiales como la fila $N - 1$ de Pascal con `comb(N - 1, k)` y comprueba $N = 5$ contra `[1 4 6 4 1]`. El kernel de esta operación es exactamente ese vector normalizado.
- Tarea 3 (operadores de derivada con kernels binomiales): arma un filtro 2D como producto exterior de dos vectores 1D (`np.outer`) y explica que es separable. Aquí se usa la misma idea, pero se aprovecha la separabilidad para filtrar en dos pasadas 1D en lugar de armar la matriz.
- Práctica 5 (kernels separables e interpolación): el núcleo de orden cero para factor 2 es `ones(2, 2)`, es decir $[1\ 1]$ en cada eje, y el núcleo lineal es `[0.5, 1, 0.5]`, que es $2 h_3$. El binomial de longitud $N$ es convolucionar el núcleo de orden cero consigo mismo $N - 1$ veces. La guía de la práctica lo resume en "interpolar es filtrar paso bajas": el filtro binomial es la misma familia de pasabajas, aquí usada para suavizar en lugar de rellenar ceros.

## Implementación

1. `N = round(p.longitud);` y, si `N` es par, `N = N + 1`. La longitud debe ser impar para que el kernel tenga un centro.
2. El ciclo `for k = 1:N-1`, con `h = conv(h, [1 1])`, genera los coeficientes de Pascal; después `h = h / sum(h)` los normaliza a suma 1. Es un ciclo sobre el kernel (a lo más 14 vueltas), no sobre los píxeles.
3. Bordes replicados por indexación: con `r = floor(N / 2)` se forman `filas = [ones(1, r), 1:M, M * ones(1, r)]` y lo mismo para `columnas`. `f = double(entrada(filas, columnas))` es la imagen ampliada $r$ píxeles por lado, repitiendo la primera y la última fila y columna.
4. `filtrada = conv2(h(:), h(:)', f, 'valid');` es la convolución separable: la forma de tres argumentos de `conv2` filtra las columnas con `h(:)` y luego los renglones con `h(:)'`. Con `'valid'` sobre la imagen ampliada el resultado tiene otra vez el tamaño $M \times N$ original.
5. `salida = uint8(round(filtrada));` regresa a uint8. Como el kernel es positivo y suma 1, el resultado nunca sale de $[0, 255]$.
6. El parámetro es `p.longitud`, de 3 a 15 en pasos de 2 con inicial 5 (`registro.m`, entrada 7).

## Verificación

`pruebas/test_binomial.m` pasa en MATLAB R2026b (incluida la comparación con `imfilter`) y en Octave 11.3. Revisa:

- Un impulso de 255 con $N = 3$ da $255 \cdot [1\ 2\ 1;\ 2\ 4\ 2;\ 1\ 2\ 1] / 16 = [16\ 32\ 16;\ 32\ 64\ 32;\ 16\ 32\ 16]$, la respuesta al impulso esperada.
- Un impulso con $N = 5$ reproduce $255 \cdot h_5^{\top} h_5$, con 36 en el centro ($255 \cdot 36/256 = 35.86$).
- `longitud` = 4 da lo mismo que 5.
- Una imagen constante de 100 queda igual en toda la imagen, orillas y esquinas incluidas, para todos los $N$ de 3 a 15. Esto comprueba la replicación de bordes (con relleno de ceros las orillas se oscurecerían).
- Una imagen blanca sigue en 255 y una negra en 0 con $N = 15$.
- La versión separable coincide exactamente (`isequal`) con `conv2` 2D directo con $h^{\top}h$ para $N = 3, 5, \dots, 15$. El kernel de referencia se arma con `nchoosek` y la ampliación con `repmat`, por caminos distintos a los de la función. La igualdad es exacta porque los coeficientes son fracciones diádicas.
- Contra `imfilter(A, h' * h, 'replicate', 'conv', 'same')` con $N = 9$ coincide exactamente.

## Costo medido

De [`barridos.csv`](../experimentos/figuras/barridos.csv) (mediana de 10 corridas por punto, MATLAB R2026b, 640×480):

| longitud | 3 | 5 | 7 | 9 | 11 | 13 | 15 |
|----------|---|---|---|---|----|----|----|
| ms | 4.110 | 3.477 | 3.031 | 3.008 | 3.124 | 3.112 | 3.197 |

En la tabla de tiempos, con `longitud` = 5: 3.071 ms de mediana, 3.835 ms de p90 y 326 FPS máximos.

El costo teórico separable es $O(2N \cdot MN)$, lineal en $N$, pero en la medición casi no cambia (3.0 a 4.1 ms sin tendencia clara). Para $N \le 15$ domina el costo fijo de recorrer la imagen: armar la imagen ampliada con indexación, convertirla a double y redondear. El cálculo de $2N$ productos por píxel lo hace `conv2` de forma muy optimizada. Si la convolución fuera 2D directa, el costo crecería con $N^2$.

Figuras: [barrido_binomial.png](../experimentos/figuras/barrido_binomial.png) (tiempo contra `longitud`) y [mosaico_binomial_longitud_3_7_15.png](../experimentos/figuras/mosaico_binomial_longitud_3_7_15.png) (original y salidas con longitud 3, 7 y 15, sobre la imagen estándar `peppers.png` ampliada a 640×480). El PSNR contra el original es de 42.9, 37.3 y 33.8 dB.

## Limitaciones

- Suaviza todo por igual: el ruido y los bordes. No preserva bordes como lo haría un filtro de mediana o uno bilateral.
- El suavizado máximo es moderado: con $N = 15$, $\sigma \approx 1.87$ píxeles. Para un desenfoque más fuerte haría falta un kernel más largo.
- La replicación de bordes evita que las orillas se oscurezcan, pero da más peso a la última fila y columna; en una franja de $r = 7$ píxeles (con $N = 15$) el resultado no es un promedio de vecinos reales.
- La función no limita `p.longitud` al rango 3 a 15; confía en el deslizador. Un valor de 1 o 0 da el filtro identidad.
