# Negativo

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+niveles_gris/negativo.m` |
| Categoría | Niveles de gris (operación puntual) |
| Parámetros | Ninguno |
| Entrada / salida | uint8 gris M×N / uint8 gris M×N |
| Prueba | `pruebas/test_negativo.m` |

## Qué hace y para qué sirve

Invierte los niveles de gris: lo negro queda blanco, lo blanco queda negro y los grises intermedios se reflejan respecto al gris medio. Es la transformación puntual más simple del curso y sirve como punto de partida para explicar las demás operaciones de niveles de gris.

En la práctica ayuda a ver detalles claros y pequeños que están dentro de zonas oscuras grandes (el ojo distingue mejor detalles oscuros sobre fondo claro). En la demostración también sirve como referencia de costo mínimo: es lo más barato que puede hacer el sistema con un cuadro completo.

## Fundamento matemático

Es una transformación puntual $s = T(r)$, donde $r$ es el nivel de entrada y $s$ el de salida, con $L = 256$ niveles:

$$s = T(r) = (L - 1) - r = 255 - r, \qquad r \in \{0, \dots, 255\}$$

La curva de transferencia es una recta de pendiente $-1$ que lleva $0 \to 255$ y $255 \to 0$. Tres propiedades que conviene saber defender:

- Es biyectiva: no se pierde información, cada nivel de entrada va a un nivel de salida distinto.
- Es involutiva: $T(T(r)) = 255 - (255 - r) = r$. Aplicarla dos veces regresa la imagen original.
- El histograma de la salida es el espejo del de entrada: $h_s(k) = h_r(255 - k)$. El contraste (la varianza $\sigma^2$) no cambia; solo cambia la media, que pasa de $\mu$ a $255 - \mu$.

Como $0 \le r \le 255$, el resultado siempre cae en $[0, 255]$: la resta en uint8 nunca satura, así que no hace falta pasar a double.

## Relación con el curso

- Tema de realce en el dominio espacial (transformaciones de niveles de gris, Gonzalez y Woods). Es la transformación lineal de pendiente negativa que se presenta junto a la logarítmica y la de potencia (gamma).
- Práctica 2 del curso (dithering): ahí la imagen se normaliza con `im2double` a $[0, 1]$; en esa escala el negativo sería $1 - I$. En VisionLab se trabaja en la escala original 0-255 para evitar la conversión.
- Práctica 3 (histogramas): la propiedad $h_s(k) = h_r(255 - k)$ se puede mostrar en la exposición comparando el histograma de una escena con el de su negativo.

## Implementación

El archivo tiene una sola instrucción efectiva:

1. `salida = 255 - uint8(entrada);` resta cada píxel a 255 directamente en uint8.
2. `uint8(entrada)` no cambia nada cuando la entrada ya es uint8 (es lo que entrega `visionlab.camara.a_gris`); solo garantiza el tipo si llegara otro.
3. La operación es vectorizada: MATLAB aplica la resta a la matriz completa de 640×480 sin ciclos.
4. El argumento `p` no se usa; el registro (`+visionlab/+nucleo/registro.m`, entrada 1) declara la lista de parámetros vacía (`sin_parametros`).

## Verificación

`pruebas/test_negativo.m` pasa en MATLAB R2026b (corrida de `pruebas/correr_pruebas.m`, 14 de 14 pruebas de operaciones OK) y en Octave 11.3. Revisa:

- Un caso de 2×2 hecho a mano: `[0 255; 100 128]` debe dar `[255 0; 155 127]`, con salida uint8 del mismo tamaño.
- La rampa `uint8(0:255)` debe quedar exactamente `uint8(255:-1:0)`.
- La involución: aplicar el negativo dos veces a una imagen aleatoria de 30×40 regresa la original.
- La comparación contra `imcomplement` del Image Processing Toolbox, que coincide exactamente en MATLAB (en Octave sin el paquete image se omite con un `disp`).

## Costo medido

Datos de [`tiempos_operaciones.csv`](../experimentos/figuras/tiempos_operaciones.csv) (MATLAB R2026b, cuadros reales de la cámara a 640×480, 2 corridas de calentamiento y 20 medidas):

| ms mediana | ms p90 | FPS máx (solo la operación) |
|-----------:|-------:|----------------------------:|
| 0.031 | 0.278 | 32000 |

El costo es $O(MN)$, con una resta por píxel, y no hay parámetro que lo modifique; por eso no aparece en [`barridos.csv`](../experimentos/figuras/barridos.csv). Con un tiempo tan pequeño el percentil 90 es nueve veces la mediana: a esta escala domina el ruido del temporizador y del sistema operativo, no el algoritmo.

## Limitaciones

- No realza el contraste; solo invierte. Si la imagen tiene poco contraste, el negativo también lo tiene.
- Solo trabaja con imágenes en gris uint8 (el contrato del sistema). Con otro tipo de entrada, `uint8()` saturaría los valores fuera de 0-255.
- Pregunta probable en la exposición: por qué no se convierte a double. Respuesta: $255 - r$ con $r \in [0, 255]$ nunca sale del rango, así que la aritmética entera es exacta y más barata.
