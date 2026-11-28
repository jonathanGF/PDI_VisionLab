# Umbral binario

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+niveles_gris/umbral.m` |
| Categoría | Niveles de gris (operación puntual) |
| Parámetros | `umbral`: mín 0, máx 255, inicial 128, paso 1 |
| Entrada / salida | uint8 gris M×N / logical M×N |
| Prueba | `pruebas/test_umbral.m` |

## Qué hace y para qué sirve

Convierte la imagen en gris en una imagen de dos niveles: los píxeles con nivel mayor o igual al umbral quedan en 1 (blanco) y el resto en 0 (negro). Es la forma más simple de segmentar: separa objetos claros de un fondo oscuro (o al revés) cuando sus niveles de gris no se traslapan. En la demostración, mover el deslizador muestra en vivo cómo cambia la región segmentada.

## Fundamento matemático

Para un umbral $T \in \{0, \dots, 255\}$:

$$g(x, y) = \begin{cases} 1, & f(x, y) \ge T \\ 0, & f(x, y) < T \end{cases}$$

Visto como transformación puntual, es una función escalón en $r = T$: el caso extremo de una curva de contraste con pendiente infinita. También es una cuantización a 1 bit con frontera de decisión en $T$.

La fracción de píxeles que quedan en 1 se lee directamente del histograma normalizado $p(k)$:

$$\frac{\#\{g = 1\}}{MN} = \sum_{k = T}^{255} p(k) = 1 - c(T - 1)$$

donde $c$ es la función de distribución acumulada (la misma CDF de la ecualización). Esto da el criterio clásico para elegir $T$: si el histograma es bimodal (objeto y fondo), el umbral debe ir en el valle entre los dos modos.

## Relación con el curso

- Práctica 2 del curso (dithering), inciso a: la "cuantización directa a 1 bit" es `dith_umbral = I >= 0.5` sobre la imagen normalizada. Con `umbral = 128` esta operación da exactamente el mismo resultado: $r/255 \ge 0.5 \iff r \ge 127.5 \iff r \ge 128$ para $r$ entero. La diferencia es que aquí el umbral se mueve en tiempo real.
- Práctica 2, incisos b a d: el dithering aleatorio, el de Bayer y Floyd-Steinberg nacen para corregir el defecto de esta operación (pierde todos los tonos intermedios). Ver `bayer.md`.
- Práctica 3 (histogramas): la relación entre la fracción de píxeles en 1 y la CDF.

## Implementación

1. `salida = entrada >= p.umbral;` hace la comparación para toda la matriz de una sola vez, sin ciclos ni funciones de toolbox.
2. El resultado de una comparación en MATLAB es de tipo logical, así que la salida es logical del mismo tamaño que la entrada.
3. Para mostrarla, `visionlab.nucleo.Pipeline.a_despliegue` la convierte a uint8 con valores 0 y 255.
4. El parámetro es `p.umbral`, entero de 0 a 255 con paso 1 e inicial 128 (`registro.m`, entrada 3). Con 0 todo queda en 1 y con 255 solo el blanco puro.

## Verificación

`pruebas/test_umbral.m` pasa en MATLAB R2026b y en Octave 11.3. Revisa:

- Caso hecho a mano de 2×3 con umbral 128: `[0 127 128; 200 255 50]` da `[0 0 1; 1 1 0]`, logical y del mismo tamaño.
- Con umbral 0 todos los píxeles quedan en 1; con umbral 255 solo queda el 255.
- Sobre la rampa 0-255 con umbral 100 quedan exactamente 156 píxeles en 1 ($256 - 100$) y el corte cae entre 99 y 100.
- Contra `imbinarize` en una imagen aleatoria de 48×64 coincide exactamente. `imbinarize` usa $>$ en lugar de $\ge$ y trabaja en $[0, 1]$, por eso la referencia usa el umbral $(T - 0.5)/255$; es una diferencia de definición, no un error.

## Costo medido

De [`tiempos_operaciones.csv`](../experimentos/figuras/tiempos_operaciones.csv) (MATLAB R2026b, 640×480, mediana de 20 corridas):

| Parámetro | ms mediana | ms p90 | FPS máx |
|-----------|-----------:|-------:|--------:|
| umbral = 128 | 0.106 | 0.212 | 9412 |

Es una comparación por píxel, $O(MN)$, y el valor del umbral no cambia el costo (no se hizo barrido). Es la segunda operación más rápida del sistema, después del negativo. Comparada con la gamma (2.79 ms), muestra que una operación puntual escrita como comparación directa en uint8 es mucho más barata que una escrita con LUT.

Figura: [mosaico_umbral_umbral_64_128_192.png](../experimentos/figuras/mosaico_umbral_umbral_64_128_192.png) (original y salidas con umbral 64, 128 y 192).

## Limitaciones

- El umbral es global y fijo: si la iluminación cambia en una parte de la escena (sombras, reflejos), el mismo $T$ no sirve para toda la imagen. No hay umbral adaptativo ni local.
- El umbral no se elige solo; no se implementó un método automático como Otsu, que buscaría el $T$ que maximiza la varianza entre clases.
- Pierde todos los tonos intermedios y el contorno de los objetos sale ruidoso cuando su nivel está cerca de $T$. Una erosión o dilatación después ayudaría, pero el pipeline aplica una sola operación por cuadro.
- Con la exposición automática de la cámara, el brillo de la escena cambia y la segmentación también; por eso `configuracion.m` fija la exposición manual.
