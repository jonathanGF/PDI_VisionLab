# Cuantización uniforme

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+tramado/cuantizacion.m` |
| Categoría | Dithering y cuantización |
| Parámetros | `niveles`: mín 2, máx 256, inicial 8, paso 1 |
| Entrada / salida | uint8 gris M×N / uint8 gris M×N |
| Prueba | `pruebas/test_cuantizacion.m` |

## Qué hace y para qué sirve

Reduce los 256 niveles de gris de la imagen a $L$ niveles equiespaciados (`niveles`). Sirve para mostrar el efecto de tener menos bits por píxel: con 8 niveles (3 bits) la imagen todavía se reconoce, pero en zonas de gris suave aparecen escalones con bordes artificiales, los llamados falsos contornos. Es el problema que el dithering (`bayer.md`) intenta disimular, y en la exposición conviene mostrar las dos operaciones seguidas.

## Fundamento matemático

El rango $[0, 256)$ se divide en $L$ intervalos de ancho

$$\Delta = \frac{256}{L}$$

Cada nivel $r$ cae en el intervalo $i(r) = \lfloor r / \Delta \rfloor = \lfloor rL/256 \rfloor$ y se sustituye por el centro del intervalo, truncado al entero:

$$Q(r) = \left\lfloor i(r)\, \Delta + \frac{\Delta}{2} \right\rfloor = \left\lfloor \frac{(2\, i(r) + 1) \cdot 128}{L} \right\rfloor$$

La segunda forma es la que usa el código: multiplica antes de dividir para que la aritmética sea exacta con cualquier $L$. Ejemplos: con $L = 2$ el corte está en 128 y los valores son 64 y 192; con $L = 4$ son 32, 96, 160 y 224; con $L = 256$ se cumple $Q(r) = r$.

El error de cuantización $e = r - Q(r)$ está acotado por medio intervalo, $|e| \le \Delta/2$. Si los niveles de la imagen se reparten de forma más o menos uniforme dentro de cada intervalo, el error cuadrático medio es

$$\text{MSE} \approx \frac{\Delta^2}{12}$$

y con $L = 2^b$ (b bits), la relación señal a ruido de cuantización mejora unos 6 dB por cada bit adicional. Esto explica por qué de 2 a 8 niveles el cambio es enorme y a partir de 32 casi no se nota. En la imagen estándar `peppers.png` ampliada a 640×480 el PSNR medido es 19.0, 22.7, 29.9 y 40.6 dB con 2, 4, 8 y 32 niveles.

## Relación con el curso

- Práctica 2 del curso (dithering), inciso a: la cuantización directa a 1 bit con umbral fijo es el caso $L = 2$. Allí la salida es binaria (0 o 1); aquí, con $L = 2$, los dos niveles se representan con 64 y 192, que son los centros de los intervalos.
- Práctica 3 (histogramas), incisos 1c y 2f: ecualizar y especificar el histograma con 128, 64, 32, 16, 8 y 2 niveles. Esta operación permite ver en vivo esos mismos niveles de cuantización sin el paso de especificación.
- La técnica de aplicarla con una tabla de 256 entradas es la misma de `gamma.md` y `ecualizacion.md`.

## Implementación

1. `L = min(max(round(p.niveles), 2), 256);` redondea el valor del deslizador y lo limita a $[2, 256]$, por si llega un valor no entero.
2. `r = 0:255;` y `idx = floor(r * L / 256);` calculan el intervalo de cada uno de los 256 niveles posibles.
3. `centro = floor((2 * idx + 1) * 128 / L);` calcula el centro truncado de cada intervalo.
4. `lut = uint8(min(centro, 255));` arma la tabla (el `min` es una protección; con la fórmula el centro nunca pasa de 255).
5. `salida = reshape(lut(double(entrada) + 1), size(entrada));` aplica la tabla a cada píxel y conserva la forma.
6. El parámetro es `p.niveles`, de 2 a 256 con paso 1 e inicial 8 (`registro.m`, entrada 6).

## Verificación

`pruebas/test_cuantizacion.m` pasa en MATLAB R2026b (incluida la comparación con `imquantize`) y en Octave 11.3. Revisa:

- Casos hechos a mano: $L = 2$ da 64 y 192 con corte en 128; $L = 4$ da 32, 96, 160 y 224; $L = 8$ lleva 100 a $\lfloor 100/32 \rfloor \cdot 32 + 16 = 112$; $L = 3$ da 42, 128 y 213 (los centros 42.67 y 213.33 se truncan).
- $L = 256$ es la identidad sobre la rampa 0-255.
- Para $L \in \{2, 3, 5, 6, 7, 8, 16, 100, 128, 255, 256\}$ la rampa sale con exactamente $L$ valores distintos y nunca baja.
- Una imagen de una sola columna conserva su forma.
- En una imagen aleatoria de 48×64 la salida es idéntica a la fórmula directa $\lfloor \lfloor r/\Delta \rfloor \Delta + \Delta/2 \rfloor$ para todas las potencias de 2 de 2 a 256.
- Contra `imquantize` con $L = 6$ coincide exactamente. Los umbrales de la referencia se ponen a medio nivel porque `imquantize` manda el valor igual al umbral al nivel de abajo.

## Costo medido

De [`tiempos_operaciones.csv`](../experimentos/figuras/tiempos_operaciones.csv) (mediana de 20) y [`barridos.csv`](../experimentos/figuras/barridos.csv) (mediana de 10), MATLAB R2026b, 640×480:

| niveles | 2 | 4 | 8 | 16 | 32 | 64 | 128 | 256 |
|---------|---|---|---|----|----|----|-----|-----|
| ms (barrido) | 4.153 | 4.038 | 4.025 | 3.423 | 2.853 | 3.113 | 4.647 | 4.894 |

En la tabla de tiempos, con `niveles` = 8: 2.654 ms de mediana, 2.855 ms de p90 y 377 FPS máximos.

El número de niveles no cambia el costo: la tabla se calcula con 256 operaciones sea cual sea $L$, y después cada píxel hace una sola indexación, $O(MN)$. Las variaciones del barrido (2.9 a 4.9 ms) no siguen una tendencia clara y están dentro de la variación entre corridas. El costo es parecido al de la gamma (2.79 ms) porque es la misma estructura: tabla más indexación.

Figuras: [barrido_cuantizacion.png](../experimentos/figuras/barrido_cuantizacion.png) (tiempo contra `niveles`) y [mosaico_cuantizacion_niveles_2_4_8_32.png](../experimentos/figuras/mosaico_cuantizacion_niveles_2_4_8_32.png) (original y salidas con 2, 4, 8 y 32 niveles sobre `peppers.png`; el PSNR de cada una está en [resultados.md](../experimentos/resultados.md)).

## Limitaciones

- Con pocos niveles aparecen falsos contornos en degradados suaves (cielo, paredes, sombras). La cuantización no los disimula; para eso está el dithering.
- Es cuantización uniforme: no toma en cuenta cómo se reparten los niveles de la imagen. Un cuantizador óptimo (Lloyd-Max) pondría más niveles donde hay más píxeles y daría menos error con el mismo $L$.
- Los centros se truncan con `floor` en lugar de redondearse. Es la única forma de que $L = 256$ sea la identidad (con redondeo, $r + 0.5$ subiría a $r + 1$). Con $L$ potencia de 2 el resultado es idéntico a la fórmula; con otros $L$ algunos valores quedan 1 nivel abajo del redondeo (con $L = 3$ sale 42 en vez de 43).
