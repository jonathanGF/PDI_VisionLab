# Laplaciano con binomial de orden 2

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+filtrado/laplaciano.m` |
| Categoría | Filtrado y bordes (segunda derivada) |
| Parámetros | `longitud`: mín 3, máx 11, inicial 3, paso 2 (solo impares) |
| Entrada / salida | uint8 gris M×N / uint8 gris M×N |
| Prueba | `pruebas/test_laplaciano.m` |

## Qué hace y para qué sirve

Calcula el laplaciano, la suma de las segundas derivadas en $x$ y en $y$, y muestra su valor absoluto. Responde a los cambios de curvatura de la intensidad: resalta bordes, líneas finas y puntos aislados sin importar su orientación, y no responde a zonas planas ni a degradados lineales. Es complementario al detector de bordes de orden 1 (`bordes_binomial.md`): aquel mide qué tan rápido cambia la intensidad; este mide dónde cambia la pendiente.

## Fundamento matemático

El laplaciano continuo es

$$\nabla^2 f = \frac{\partial^2 f}{\partial x^2} + \frac{\partial^2 f}{\partial y^2}$$

La segunda derivada discreta básica es la diferencia de la diferencia, $[1\ {-1}] * [1\ {-1}] = [1\ {-2}\ 1]$, es decir $f(x - 1) - 2f(x) + f(x + 1)$. Como en la Tarea 3, para longitudes mayores se combina con un suavizado binomial de $N - 2$ elementos:

$$d2_N = b_{N-2} * [1\ {-2}\ 1], \qquad b_{N-2}(k) = \binom{N-3}{k}$$

Con $N = 3$, $d2 = [1\ {-2}\ 1]$; con $N = 5$, $d2 = [1\ 0\ {-2}\ 0\ 1]$; con $N = 7$, $d2 = [1\ 2\ {-1}\ {-4}\ {-1}\ 2\ 1]$. Todos suman 0 (no responden a zonas planas) y son simétricos, por lo que su primer momento también es 0 (no responden a rampas lineales).

El laplaciano se arma con la misma $d2$ por columnas y por renglones, sin suavizar en la dirección ortogonal, y se suman:

$$\nabla^2 f \approx d2^{\top} * f + d2 * f$$

Con $N = 3$ esto es exactamente el laplaciano clásico de 4 vecinos:

$$\begin{bmatrix} 0 & 0 & 0 \\ 1 & -2 & 1 \\ 0 & 0 & 0 \end{bmatrix} + \begin{bmatrix} 0 & 1 & 0 \\ 0 & -2 & 0 \\ 0 & 1 & 0 \end{bmatrix} = \begin{bmatrix} 0 & 1 & 0 \\ 1 & -4 & 1 \\ 0 & 1 & 0 \end{bmatrix}$$

La salida es el valor absoluto escalado al máximo del cuadro: $e = \operatorname{round}(255\, |\nabla^2 f| / \max |\nabla^2 f|)$.

En frecuencia, la respuesta de $d2_N$ (en magnitud) es

$$|D2_N(\omega)| = 4 \sin^2\!\left( \frac{\omega}{2} \right) \left( 2 \cos \frac{\omega}{2} \right)^{N-3}$$

Con $N = 3$ es un pasaaltas puro: el máximo está en $\omega = \pi$, la frecuencia más alta, que es justo donde está el ruido del sensor. Al crecer $N$ el factor binomial lo convierte en pasabanda: el pico baja a $0.5\pi$ con $N = 5$, $0.39\pi$ con $N = 7$ y $0.30\pi$ con $N = 11$. Es la misma idea del laplaciano de la gaussiana (LoG): suavizar antes de derivar dos veces.

Ante un escalón, la segunda derivada cambia de signo: en el escalón 0 | 200, con $N = 3$, la columna oscura da $+200$ y la clara $-200$. El cruce por cero marca la posición del borde, y el valor absoluto produce un borde doble.

## Relación con el curso

- Tarea 3 del curso (operadores de derivada): define el operador de derivada de orden $d$ con coeficientes binomiales de signo alternado, `derivada(2) = [1, -2, 1]`, y construye cada vector como `convolución(suavizado, operador_derivada)` con un suavizado de $N - d$ elementos. Esta operación es el caso $d = 2$.
- Tarea 2 (coeficientes binomiales): los coeficientes $b_{N-2}$.
- `bordes_binomial.md`: el mismo esquema con $d = 1$.

## Implementación

1. `N = p.longitud;` y bordes replicados por indexación (`filas`, `columnas`, `f = double(entrada(filas, columnas))`), igual que en `binomial.m`.
2. El ciclo `for k = 1:N-3`, con `b = conv(b, [1 1])`, da los $N - 2$ coeficientes binomiales; con $N = 3$ el ciclo no se ejecuta y `b = 1`.
3. `d2 = conv(b, [1 -2 1]);` es el kernel de segunda derivada de $N$ elementos.
4. `lap = conv2(f(:, r+1:r+L), d2(:), 'valid') + conv2(f(r+1:r+M, :), d2, 'valid');` es la clave: la primera convolución deriva por columnas ($y$) y usa solo la ampliación vertical; la segunda deriva por renglones ($x$) y usa solo la horizontal. Así, con `'valid'`, cada una queda del tamaño original y se pueden sumar.
5. `magnitud = abs(lap);` y, si el máximo `m` es mayor que 0, `salida = uint8(255 * magnitud / m)`; si la imagen es plana, la salida es de ceros.
6. El parámetro es `p.longitud`, de 3 a 11 en pasos de 2 con inicial 3 (`registro.m`, entrada 9).

## Verificación

`pruebas/test_laplaciano.m` pasa en MATLAB R2026b (incluida la comparación con `imfilter` y `fspecial`) y en Octave 11.3. Revisa:

- Con $N = 3$ la salida es idéntica (`isequal`) al laplaciano clásico `conv2(fp, [0 1 0; 1 -4 1; 0 1 0], 'valid')` sobre la imagen ampliada y escalado igual; en el interior también coincide con el clásico sin ampliar, y antes de escalar el valor con signo coincide (error menor que $10^{-9}$).
- Un impulso con $N = 3$ da 255 en el centro y 64 en los 4 vecinos ($|{-4}|$ frente a 1); con $N = 5$ los 64 aparecen a distancia 2, porque $d2_5 = [1\ 0\ {-2}\ 0\ 1]$.
- Los kernels de $N = 3$ a 11 tienen $N$ elementos y suman 0.
- En una rampa horizontal el interior da 0 para todo $N$.
- En un escalón vertical con $N = 3$ solo responden las columnas 10 y 11, con el mismo valor (el borde doble).
- Trasponer la entrada traspone la salida para todo $N$; una imagen plana da 0 en todas partes, orillas incluidas, y una negra da 0.
- Contra `imfilter(double(J), fspecial('laplacian', 0), 'conv', 'replicate', 'same')`: diferencia máxima de 1 nivel.

## Costo medido

De [`barridos.csv`](../experimentos/figuras/barridos.csv) (mediana de 10, MATLAB R2026b, 640×480):

| longitud | 3 | 5 | 7 | 9 | 11 |
|----------|---|---|---|---|----|
| ms | 7.116 | 7.192 | 6.914 | 6.946 | 7.011 |

En la tabla de tiempos, con `longitud` = 3: 6.927 ms de mediana, 7.632 ms de p90 y 144 FPS máximos. La diferencia con el barrido (7.1 ms para el mismo $N$) está dentro de la variación de ±30 % entre corridas descrita en las condiciones de medición de [indice.md](indice.md).

La longitud no cambia el costo de forma apreciable: son dos convoluciones 1D, $O(2N \cdot MN)$, y para $N \le 11$ domina el recorrido de la imagen. Cuesta algo más que `bordes_binomial` a pesar de hacer menos pasadas; una explicación posible, que no se midió por separado, es que `f(:, r+1:r+L)` y `f(r+1:r+M, :)` crean dos copias de la imagen ampliada y que `conv2` recibe el kernel como matriz $N \times 1$ en lugar de usar la forma separable de tres argumentos.

Figuras: [barrido_laplaciano.png](../experimentos/figuras/barrido_laplaciano.png) (tiempo contra `longitud`) y [mosaico_laplaciano_longitud_3_7.png](../experimentos/figuras/mosaico_laplaciano_longitud_3_7.png) (original y salidas con longitud 3 y 7).

## Limitaciones

- Es muy sensible al ruido, sobre todo con $N = 3$, donde la respuesta máxima está en la frecuencia más alta.
- Al tomar el valor absoluto se pierde el signo y, con él, los cruces por cero, que son la forma clásica de localizar bordes con el laplaciano (Marr-Hildreth). Cada borde aparece doble.
- No suaviza en la dirección ortogonal a cada derivada, así que con $N$ grande el resultado es anisotrópico: realza más las estructuras alineadas con los ejes.
- Con $N = 5$ el kernel $[1\ 0\ {-2}\ 0\ 1]$ ignora los vecinos inmediatos: es una segunda diferencia con separación 2.
- El escalado por el máximo de cada cuadro hace que el brillo cambie de un cuadro a otro.
- Como en `binomial.m` y `bordes_binomial.m`, si `longitud` llega par se usa `longitud + 1`.
