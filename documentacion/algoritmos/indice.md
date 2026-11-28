# Fundamentos de las operaciones de PDI VisionLab

Documentación de las 14 operaciones del sistema para el reporte técnico y para preparar la exposición. Cada archivo explica qué hace la operación, su fundamento matemático, su relación con las prácticas y tareas del curso, cómo está implementada (con los nombres reales de los parámetros de `+visionlab/+nucleo/registro.m`), cómo se verificó, cuánto cuesta y qué limitaciones tiene.

## Operaciones

| # | Operación | Documento | Parámetros (mín a máx, inicial) | ms mediana | Relación con el curso |
|--:|-----------|-----------|---------------------------------|-----------:|-----------------------|
| 1 | Negativo | [negativo.md](negativo.md) | ninguno | 0.031 | Realce, transformaciones puntuales; P2 (escala normalizada) |
| 2 | Corrección gamma | [gamma.md](gamma.md) | `gamma` 0.1 a 5 (1), continuo | 2.793 | Realce, ley de potencia; LUT como en P3 |
| 3 | Umbral binario | [umbral.md](umbral.md) | `umbral` 0 a 255 (128) | 0.106 | P2 inciso a (cuantización a 1 bit) |
| 4 | Ecualización de histograma | [ecualizacion.md](ecualizacion.md) | ninguno | 4.707 | P3 ejercicio 1 (ecualización) y 2 (especificación) |
| 5 | Dithering Bayer | [bayer.md](bayer.md) | `orden` 1 a 3 (2) | 3.477 | P2 inciso c (Bayer 2×2 y 4×4) |
| 6 | Cuantización uniforme | [cuantizacion.md](cuantizacion.md) | `niveles` 2 a 256 (8) | 2.654 | P2 inciso a; P3 incisos 1c y 2f (128 a 2 niveles) |
| 7 | Suavizado binomial | [binomial.md](binomial.md) | `longitud` 3 a 15 (5), impares | 3.071 | Tareas 2 y 3; P5 (núcleos de orden cero y lineal) |
| 8 | Bordes (binomial orden 1) | [bordes_binomial.md](bordes_binomial.md) | `longitud` 3 a 11 (5), impares; `umbral` 0 a 255 (0) | 5.531 | Tarea 3 (derivada de orden 1) |
| 9 | Laplaciano (binomial orden 2) | [laplaciano.md](laplaciano.md) | `longitud` 3 a 11 (3), impares | 6.927 | Tarea 3 (derivada de orden 2) |
| 10 | Erosión | [erosion.md](erosion.md) | `tamano` 3 a 15 (5), impares | 2.166 | P4 (filtros espaciales no lineales) |
| 11 | Dilatación | [dilatacion.md](dilatacion.md) | `tamano` 3 a 15 (5), impares | 2.192 | P4 (filtros espaciales no lineales) |
| 12 | Diferencia de cuadros | [diferencia_cuadros.md](diferencia_cuadros.md) | `umbral` 1 a 128 (25) | 0.645 | P2 inciso a (umbral fijo) |
| 13 | Block matching (SAD) | [block_matching.md](block_matching.md) | `bloque` 8 a 32 (16), paso 8; `radio` 1 a 6 (3) | 11.343 | P3 ejercicio 2 (búsqueda exhaustiva por correlación); P5 (muestreo) |
| 14 | Histograma | [histograma.md](histograma.md) | ninguno | 2.358 | P3 (`imhist`) |

Los tiempos son la mediana de 20 corridas con los parámetros iniciales, tomada de [`tiempos_operaciones.csv`](../experimentos/figuras/tiempos_operaciones.csv). Con esos parámetros las 14 operaciones caben en 33 ms (30 FPS); la más cara es el block matching. P2 a P5 son las prácticas del curso: P2 dithering, P3 histogramas, P4 filtros espaciales y P5 kernels separables e interpolación.

Gráfica de la tabla: [tiempos_operaciones.png](../experimentos/figuras/tiempos_operaciones.png).

## Convenciones comunes

- Firma: todas las operaciones son `function salida = op(entrada, p)` (el block matching devuelve además `dy` y `dx`). `entrada` es la imagen en gris uint8 M×N y `p` es un struct con un campo por parámetro, con los nombres de `registro.m`.
- Gris de entrada: `visionlab.camara.a_gris` convierte cada cuadro RGB con la luminancia $Y = 0.299R + 0.587G + 0.114B$.
- Movimiento: las operaciones con `movimiento = true` en el registro (diferencia de cuadros y block matching) reciben también `p.anterior`. `visionlab.nucleo.Pipeline.procesar` lo llena con el cuadro anterior; en el primer cuadro pasa el mismo cuadro, así que no se marca movimiento.
- Salidas: uint8 gris, logical (umbral, Bayer, bordes con `umbral` > 0) o RGB uint8 (movimiento). `Pipeline.a_despliegue` convierte las logical a 0/255 para mostrarlas.
- Todo es vectorizado: los únicos ciclos recorren el kernel, los desplazamientos de la ventana o los candidatos de búsqueda, nunca los píxeles.
- Los filtros lineales (`binomial`, `bordes_binomial`, `laplaciano`) y las dos operaciones morfológicas (`erosion`, `dilatacion`) replican los bordes.

## Condiciones de medición

Los costos de cada documento salen de `experimentos/medir_todo.m`, descritos en [resultados.md](../experimentos/resultados.md). `medir_todo.m` escribe en `resultados/`, la carpeta de trabajo ignorada por git; los CSV y las figuras del entregable están copiados en `../experimentos/figuras/`:

- MATLAB R2026b en modo `-batch`, laptop con Windows 11 y sin otra carga (procesador, memoria y cámara en la sección de condiciones y hardware de [resultados.md](../experimentos/resultados.md)).
- Dos cuadros reales de la cámara integrada a 640×480, convertidos a gris (el segundo, cinco lecturas después del primero, para que haya algo de movimiento).
- `tic`/`toc` solo alrededor de la llamada a la operación, igual que en el pipeline. No incluye captura, conversión ni despliegue.
- Tabla de tiempos: 2 corridas de calentamiento y 20 medidas; se reportan mediana y percentil 90. Barridos ([`barridos.csv`](../experimentos/figuras/barridos.csv)): 1 de calentamiento y 10 medidas por punto, con los demás parámetros en su valor inicial (el barrido de `bloque` del block matching se hizo con `radio` = 3).
- Repetibilidad: entre corridas completas, las operaciones de pocos milisegundos variaron hasta ±30 %. Diferencias menores a eso entre dos puntos de un barrido no deben interpretarse como tendencia.

## Cómo correr las pruebas

Cada operación tiene su prueba en `pruebas/test_<operación>.m`. Para correrlas todas desde MATLAB:

```matlab
addpath('pruebas'); correr_pruebas
```

`correr_pruebas` cambia a la raíz del proyecto y agrega `pruebas/` al path. Para correr una sola, desde la raíz: `addpath('pruebas'); test_gamma`. Las comparaciones contra el Image Processing Toolbox (`imcomplement`, `imadjust`, `imbinarize`, `histeq`, `imquantize`, `imfilter`, `imerode`, `imdilate`, `imabsdiff`, `imhist`) se ejecutan solo si la función existe; en Octave sin el paquete image se omiten con un mensaje. `correr_pruebas` también ejecuta `test_integracion.m`, que corre `principal` con la cámara sintética, sin ventana y en modo recorrido, y revisa que el CSV del recorrido tenga una fila por operación con mediana de operación positiva.

Estado al 2026-11-27: 14 de 14 pruebas de operaciones OK en MATLAB R2026b (corrida de `correr_pruebas` hecha al escribir esta documentación), con todas las comparaciones contra el toolbox activas. Las pruebas también pasaron en Octave 11.3 durante la implementación.

## Referencias

- R. C. Gonzalez y R. E. Woods, *Digital Image Processing* (referencia de la Práctica 3): transformaciones de niveles de gris, histogramas, filtrado espacial y morfología.
- Prácticas del curso: Práctica 2 (dithering), Práctica 3 (histogramas), Práctica 4 (filtros espaciales) y Práctica 5 (kernels separables e interpolación).
- Tareas 2 y 3 del curso (coeficientes binomiales y operadores de derivada).
