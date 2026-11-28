# PDI VisionLab: diseño del sistema

Documento de diseño del proyecto final de Procesamiento Digital de Imágenes (FI-UNAM). Describe las decisiones, la arquitectura y los criterios con los que se construyó el sistema. La descripción detallada de los módulos está en `arquitectura.md`, la de cada operación en `../algoritmos/` y los resultados experimentales en `../experimentos/resultados.md`.

## 1. Decisiones de diseño

| Tema | Decisión |
|---|---|
| Lenguaje | Todo en MATLAB: adquisición, algoritmos, interfaz y métricas. Es el lenguaje de las prácticas del curso, de donde provienen los algoritmos |
| Alcance | El mínimo que exige la especificación, con la lectura estricta de los mínimos por categoría: 14 operaciones (§5) |
| Hardware | Laptop con cámara integrada (USB UVC), 640×480 |
| Adquisición | MATLAB Support Package for USB Webcams (gratuito); respaldo con OpenCV a través del intérprete de Python embebido (`pyenv`) si el paquete no está disponible |
| Interfaz | `figure` clásica con `uicontrol`: menú de operaciones, deslizadores generados automáticamente desde el registro, FPS y ms por etapa |
| Verificación | Cada operación tiene una prueba con casos calculados a mano y, cuando existe, comparación contra la función de referencia de Image Processing Toolbox; las pruebas corren en MATLAB y en GNU Octave |

## 2. Requisitos que cubre

De la especificación del profesor:

- Captura continua a 640×480, original y procesado a la vez, cambio de parámetros sin interrumpir la captura.
- Meta de 20 FPS, con FPS efectivos y ms por cuadro visibles; limitaciones del hardware documentadas.
- Algoritmos de implementación propia; las funciones de biblioteca solo como referencia en las pruebas.
- Modularidad: agregar una operación es crear un archivo y una entrada en el registro.
- Evaluación experimental: FPS y ms por operación, efecto de los parámetros en tiempo y calidad, consumo de memoria y CPU, tablas y gráficas.

## 3. Arquitectura

```
  cámara ──► Camara.leer ──► a_gris ──► operación activa ──► Ventana (original | procesado)
             (webcam /       (uint8)   (función con firma    deslizadores desde el registro
              OpenCV,                   común, p desde        FPS únicos y ms por etapa
              cuadros únicos)           los deslizadores)     CSV de métricas al cerrar
```

Un proceso, un lazo. `principal.m` captura un cuadro, descarta los repetidos, convierte a gris, aplica la operación seleccionada con los parámetros actuales, muestra ambos cuadros y registra los tiempos de cada etapa.

### 3.1 Adquisición

- Backend `webcam`: `cam = webcam(1)`, `cam.Resolution = '640x480'`, `snapshot(cam)`.
- La cámara integrada entrega solo 9–15 cuadros nuevos por segundo con poca luz en exposición automática. Con `ExposureMode = 'manual'`, `Exposure = -5`, `Brightness = 100` y `Gamma = 100` entrega 30 cuadros nuevos por segundo con brillo adecuado; son los valores por defecto de `configuracion.m` y se pueden volver a `'auto'`.
- Los cuadros repetidos (la cámara reporta 30 FPS aunque no haya cuadro nuevo) se detectan comparando una versión submuestreada con la anterior; los FPS que se muestran y se registran son de cuadros únicos.
- Conversión a gris con la fórmula de luminancia 0.299 R + 0.587 G + 0.114 B.

### 3.2 Contrato de operación y registro

Cada operación es un archivo con la misma firma:

```matlab
function salida = gamma(entrada, p)
% entrada: uint8 M×N gris. p: struct con los parámetros declarados en el registro.
% salida: uint8 M×N, logical M×N o uint8 M×N×3 (superposición en color).
```

`+visionlab/+nucleo/registro.m` es la única lista de operaciones. Cada entrada tiene `nombre`, `categoria`, `funcion` (handle), `movimiento` (si recibe el cuadro anterior en `p.anterior`) y `parametros` (struct con `nombre`, `min`, `max`, `inicial`, `paso`; `paso` 0 es continuo). La interfaz crea un deslizador por parámetro leyendo el registro.

### 3.3 Medición

Por cuadro se miden con `tic`/`toc` la captura, la conversión a gris, la operación y el despliegue. `Metricas` mantiene una ventana móvil de un segundo (FPS únicos y promedios por etapa), exporta un CSV por corrida y, en el modo recorrido, una tabla por operación con FPS únicos, medianas por etapa, memoria usada por MATLAB y porcentaje de CPU del proceso.

### 3.4 Estructura del repositorio

```
principal.m                      lazo principal; opciones sin_camara, sin_ventana, cuadros_max, recorrer
configuracion.m                  cámara (backend, índice, resolución, exposición, brillo, gamma), FPS objetivo, métricas
+visionlab/+camara/              Camara.m (webcam y OpenCV, cuadros únicos), a_gris.m
+visionlab/+nucleo/              registro.m, Estado.m, Pipeline.m
+visionlab/+algoritmos/          +niveles_gris +tramado +filtrado +morfologia +movimiento +adicionales
+visionlab/+interfaz/            Ventana.m
+visionlab/+rendimiento/         Metricas.m
pruebas/                         test_<operacion>.m, test_integracion.m, correr_pruebas.m
experimentos/                    medir_todo.m, calidad_visual.m, fase0_*.m (mediciones de la cámara)
documentacion/                   algoritmos/, arquitectura/, experimentos/ (con figuras y CSV finales)
recursos/imagenes_prueba/        cuadro de cámara usado en los experimentos
resultados/                      carpeta de trabajo de las corridas (ignorada por git)
```

## 4. Interfaz

Figura clásica (no `uifigure`, cuyo renderizado es más lento para video) con dos ejes, un `popupmenu` con las operaciones agrupadas por categoría, deslizadores generados desde el registro y un texto con FPS y ms por etapa. Los controles solo escriben en un objeto `Estado` compartido que el lazo lee en cada iteración, por eso cambiar un parámetro nunca detiene la captura. La figura se cierra con el botón Salir o con la X; la cámara se libera siempre mediante `onCleanup`.

## 5. Operaciones

Lectura estricta de la especificación: A pide al menos cuatro, B dos, C al menos tres, D al menos dos, E describe las dos y exige dibujar los vectores, F una. Tiempos de la operación aislada a 640×480 en MATLAB R2026b (mediana de 20 corridas, cuadros reales de la cámara); los del sistema completo están en `../experimentos/resultados.md`.

| Cat. | Operación | Base en el curso | Parámetros | ms |
|---|---|---|---|---|
| A | Negativo | Fundamentos | — | 0.03 |
| A | Corrección gamma (LUT) | Fundamentos | gamma 0.1–5 | 2.8 |
| A | Umbral binario | Práctica 2 | umbral 0–255 | 0.1 |
| A | Ecualización de histograma (CDF) | Práctica 3 | — | 4.7 |
| B | Dithering Bayer 2×2, 4×4, 8×8 | Práctica 2 | orden 1–3 | 3.5 |
| B | Cuantización uniforme | Prácticas 2 y 3 | niveles 2–256 | 2.7 |
| C | Suavizado binomial separable | Tareas 2 y 3, Práctica 5 | longitud 3–15 | 3.1 |
| C | Bordes por binomial de orden 1 | Tarea 3 | longitud 3–11, umbral 0–255 | 5.5 |
| C | Laplaciano (binomial de orden 2) | Tarea 3 | longitud 3–11 | 6.9 |
| D | Erosión (cuadrado, separable) | Filtros de rango | tamaño 3–15 | 2.2 |
| D | Dilatación (cuadrado, separable) | Filtros de rango | tamaño 3–15 | 2.2 |
| E | Diferencia de cuadros con superposición | Umbral | umbral 1–128 | 0.7 |
| E | Block matching (SAD) con flechas, sobre 320×240 | Práctica 3 (búsqueda por correlación) | bloque 8–32, radio 1–6 | 11.3 (radio 3), 22 (radio 4) |
| F | Histograma dinámico | Práctica 3 | — | 2.4 |

Todas caben en el presupuesto de 50 ms por cuadro. Los filtros replican el borde de la imagen antes de convolucionar para no producir un marco oscuro o brillante en las orillas. Block matching usa radio inicial 3 para mantener el sistema completo por encima de 20 FPS; con radio 4 queda en 18 FPS.

## 6. Verificación

- `pruebas/test_<operacion>.m`: casos pequeños calculados a mano (matrices de Bayer, CDF, respuesta a un escalón, mínimo y máximo en ventana, desplazamiento conocido) y comparación contra `histeq`, `imadjust`, `imquantize`, `imerode`, `imdilate` e `imhist` cuando están disponibles.
- `pruebas/test_integracion.m`: recorrido completo sin cámara ni ventana y verificación del CSV.
- `pruebas/correr_pruebas.m` ejecuta todo en MATLAB o en Octave.

## 7. Evaluación experimental

- `experimentos/medir_todo.m`: tiempo por operación con los parámetros iniciales y barridos de cada parámetro; CSV y gráficas.
- `principal(struct('recorrer', true))`: FPS únicos del sistema completo por operación, con ms por etapa, memoria y CPU.
- `experimentos/calidad_visual.m`: mosaicos de la imagen estándar peppers.png con varios valores de parámetro y PSNR contra el original para cuantización, Bayer y binomial.
- `experimentos/fase0_*.m`: mediciones de la cámara (backend, exposición, brillo) que motivaron la configuración por defecto.

## 8. Limitaciones y fuera de alcance

- La tasa de cuadros depende de la cámara y de la luz: en exposición automática baja a 9–15 cuadros nuevos por segundo; la demostración usa exposición manual o buena iluminación.
- El elemento estructurante de la morfología es solo cuadrado (la forma es opcional en la especificación).
- Fuera de alcance por ahora: Raspberry Pi, operaciones opcionales (mediana, máscara de enfoque, Floyd–Steinberg, filtrado en frecuencia, zoom por interpolación, apertura y cierre) e interfaz web.
