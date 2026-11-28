# Ecualización de histograma

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+niveles_gris/ecualizacion.m` |
| Categoría | Niveles de gris (operación puntual adaptada a la imagen) |
| Parámetros | Ninguno |
| Entrada / salida | uint8 gris M×N / uint8 gris M×N |
| Prueba | `pruebas/test_ecualizacion.m` |

## Qué hace y para qué sirve

Reparte los niveles de gris de la imagen sobre todo el rango de 0 a 255 para que el histograma quede lo más plano posible. Mejora el contraste de forma automática, sin que el usuario elija un parámetro: en una escena oscura o lavada, los niveles que estaban apretados en una franja estrecha se separan y aparecen detalles en zonas oscuras o brillantes. A diferencia de la gamma, la curva no es fija: se calcula de nuevo en cada cuadro a partir del propio histograma.

## Fundamento matemático

Con $M \times N$ píxeles y $L = 256$ niveles se definen:

$$h(k) = \#\{(x, y) : f(x, y) = k\}, \qquad p(k) = \frac{h(k)}{MN}, \qquad c(k) = \sum_{j=0}^{k} p(j)$$

$h$ es el histograma, $p$ el histograma normalizado (probabilidad de cada nivel) y $c$ la función de distribución acumulada (CDF). La transformación es:

$$s_k = T(k) = \operatorname{round}\big( (L - 1)\, c(k) \big) = \operatorname{round}\big( 255\, c(k) \big)$$

La justificación viene del caso continuo. Si $r$ es una variable aleatoria con densidad $p_r$ y se usa $s = T(r) = \int_0^r p_r(w)\, dw$ (con niveles en $[0, 1]$), entonces $ds/dr = p_r(r)$ y

$$p_s(s) = p_r(r) \left| \frac{dr}{ds} \right| = p_r(r) \cdot \frac{1}{p_r(r)} = 1, \qquad 0 \le s \le 1$$

es decir, la salida es uniforme. En el caso discreto no se puede partir un nivel en varios, así que el histograma resultante solo es aproximadamente plano: los niveles con muchos píxeles se separan más de sus vecinos (la CDF sube rápido ahí) y los niveles poco poblados se juntan.

Propiedades que conviene saber defender: $T$ es monótona no decreciente (nunca invierte el orden de los niveles), el nivel más alto presente siempre va a 255, y el más oscuro presente va a $255\, p(k_{\min})$, no necesariamente a 0.

## Relación con el curso

- Práctica 3 del curso (histogramas), "Ecualización y especificación de histograma": el ejercicio 1 pide ecualizar una imagen de bajo contraste con `histeq` y desplegar su histograma con `imhist`. En VisionLab no se usa `histeq`: el histograma, la CDF y la tabla se calculan a mano con la definición de libro (Gonzalez y Woods, referencia de la práctica).
- Práctica 3, ejercicio 2: la especificación con `histeq(img, J)` es la generalización de esta operación. La ecualización es el caso particular en que el histograma objetivo $J$ es uniforme.
- Práctica 3, inciso 1c: ecualizar con 128, 64, ..., 2 niveles conecta con `cuantizacion.md`.

## Implementación

1. `h = accumarray(double(entrada(:)) + 1, 1, [256 1]);` cuenta cuántos píxeles hay de cada nivel. Cada píxel suma 1 en la casilla de su nivel (más 1 porque MATLAB indexa desde 1); el tamaño `[256 1]` asegura las 256 casillas aunque falten niveles.
2. `cdf = cumsum(h) / numel(entrada);` es la suma acumulada normalizada, es decir $c(k)$.
3. `lut = uint8(round(255 * cdf));` arma la tabla $s_k$ de 256 entradas.
4. `salida = reshape(lut(double(entrada) + 1), size(entrada));` aplica la tabla a cada píxel por indexación y conserva la forma de la entrada.
5. El argumento `p` no se usa (`sin_parametros` en `registro.m`, entrada 4). Todo es vectorizado: no hay ciclos sobre píxeles.

## Verificación

`pruebas/test_ecualizacion.m` pasa en MATLAB R2026b y en Octave 11.3. Revisa:

- Un caso de 4×4 hecho a mano con niveles 0, 1, 2 (4 píxeles cada uno), 3 (3 píxeles) y 255 (1 píxel). La CDF es $4/16, 8/16, 12/16, 15/16, 16/16$, que da $64, 128, 191, 239, 255$; se compara con `isequal` exacto.
- Una imagen constante: toda la CDF vale 1 en ese nivel y todo sale en 255.
- Dos niveles mitad y mitad: el oscuro va a $\operatorname{round}(127.5) = 128$ y el claro a 255.
- Una rampa diagonal de 120×160: la salida es uint8 del mismo tamaño, la transformación es monótona y el máximo queda en 255.
- Contra `histeq(B, 256)`: en la corrida actual de MATLAB, el 100 % de los píxeles queda a 2 niveles o menos (diferencia máxima 2). La diferencia es de definición: `histeq` usa $c(k) - p(k)/2$ en lugar de $c(k)$, y por eso puede quedar unos $128\, p(k)$ niveles abajo. En imágenes con un nivel muy poblado (más de cerca del 1.5 % de los píxeles) la diferencia pasa de 2; por eso la prueba usa una rampa sin niveles dominantes y el caso de 4×4 es la referencia dura.

## Costo medido

De [`tiempos_operaciones.csv`](../experimentos/figuras/tiempos_operaciones.csv) (MATLAB R2026b, 640×480, mediana de 20 corridas):

| ms mediana | ms p90 | FPS máx |
|-----------:|-------:|--------:|
| 4.707 | 5.361 | 213 |

El costo es $O(MN + L)$: un recorrido para el histograma (`accumarray`), 256 operaciones para la CDF y la tabla, y un recorrido para aplicar la tabla. No hay parámetro y no depende del contenido de la imagen. Cuesta un poco menos que la suma de sus dos partes, que se miden por separado en otras operaciones: el conteo del histograma (`histograma.m`, 2.36 ms) y la aplicación de una LUT (`gamma.m`, 2.79 ms); $2.36 + 2.79 = 5.15$ ms frente a 4.71 ms medidos.

## Limitaciones

- Es global: usa un solo histograma para toda la imagen. No se implementó una versión local o adaptativa (como CLAHE), que realza mejor cuando hay zonas con iluminación muy distinta.
- Amplifica el ruido en zonas planas: si una pared ocupa pocos niveles muy poblados, esos niveles se separan mucho y el ruido del sensor se vuelve visible.
- En video la curva se recalcula en cada cuadro; si un objeto grande entra o sale de la escena, el brillo de toda la imagen cambia de un cuadro a otro (parpadeo).
- El nivel más oscuro presente no sale en 0 sino en $255\, p(k_{\min})$, porque se usa la CDF de libro sin restarle el primer valor.
- No coincide exactamente con `histeq` de MATLAB (ver Verificación); es una diferencia de definición documentada, no un error.
