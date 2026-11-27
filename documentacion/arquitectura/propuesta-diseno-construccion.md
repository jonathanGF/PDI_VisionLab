---
title: Diseño y construcción del proyecto final (PDI VisionLab)
date: 2026-11-27
category: technology
tags: [proyecto-final, tiempo-real, matlab, webcam, arquitectura, algoritmos]
status: draft
---

# PDI VisionLab: diseño y construcción del mínimo necesario

> Documento de diseño para aprobación del equipo. Una vez aprobado, Claude construye el sistema conforme a este documento; después el equipo se reparte los algoritmos para estudiarlos y defenderlos en la exposición.

## 0. Decisiones (ya tomadas por el equipo)

| Tema | Decisión |
|---|---|
| Lenguaje de los algoritmos | **MATLAB**, con el código que ya entregamos y explicamos en las prácticas |
| Alcance | **Solo el mínimo** que exige la especificación (13 operaciones, §3). Lo opcional se pondera después de tener el sistema construido y probado |
| Hardware | Laptop con su cámara integrada. Raspberry Pi diferida |
| Vercel / web | Descartado por completo |
| Quién construye | Claude, de forma autónoma, siguiendo este documento |

## 1. Requisitos que el diseño debe cumplir

Tomados de la especificación del profesor (`PDI_in_real_time.pdf`):

- Captura continua a **640×480**, mostrar **original y procesado** a la vez, cambiar parámetros **sin interrumpir** la captura.
- **≥ 20 FPS** en la resolución de referencia, mostrando **FPS efectivos** y **ms por cuadro** por algoritmo; documentar limitaciones del hardware.
- Algoritmos de **implementación propia** (las funciones de biblioteca solo como referencia para verificar).
- **Modularidad**: agregar una operación nueva sin tocar el resto.
- Evaluación experimental: FPS y ms por algoritmo, efecto de los parámetros, tablas y gráficas.
- Entregables: código con instrucciones, reporte, video de 3–5 min, demostración presencial con cámara.

## 2. Arquitectura: todo en MATLAB

```
  cámara integrada ──► webcam / snapshot ──► a gris ──► operación seleccionada ──► figura: original | procesado
                        (Support Package           (uint8)   (función MATLAB         controles (uicontrol)
                         for USB Webcams)                     con firma común)       FPS y ms por etapa
```

Un solo lenguaje, un solo proceso, un solo repositorio. Lo que cambia respecto al esqueleto actual de Jonathan (Python) es el lenguaje; la organización por módulos se conserva.

### 2.1 Por qué todo en MATLAB y no Python + MATLAB

La especificación deja el lenguaje a libre elección (recomienda Python para captura y despliegue, no lo exige). Mezclar Python para captura con MATLAB para algoritmos obliga a dos procesos, al engine de MATLAB para Python (acoplado a la versión de Python) y a copiar cada cuadro entre procesos; para el mínimo necesario es complejidad sin beneficio. Todo en MATLAB es lo más corto de construir y lo más fácil de explicar.

### 2.2 Adquisición

- **MATLAB Support Package for USB Webcams** (complemento gratuito de MathWorks): `cam = webcam(1); cam.Resolution = '640x480'; cuadro = snapshot(cam);`. Funciona con cámaras integradas y USB en Windows; no requiere Image Acquisition Toolbox.
- Conversión a gris con la fórmula de luminancia (0.299 R + 0.587 G + 0.114 B), escrita por nosotros (es lo que hace `rgb2gray`).
- **Cuadros únicos.** Midiendo la cámara integrada de esta laptop con OpenCV, 59 de 90 lecturas fueron cuadros repetidos: la cámara entrega ~10 cuadros nuevos por segundo con poca luz aunque reporte 30. El módulo de cámara compara cada cuadro con el anterior y **solo cuenta los nuevos**; los FPS que se muestran son de cuadros únicos. La demostración debe hacerse con buena iluminación.

### 2.3 Contrato de operación (modularidad)

Cada operación es un archivo `.m` con la misma firma:

```matlab
function salida = gamma(entrada, p)
% entrada: uint8 M×N (gris). p: struct con los parámetros declarados en el registro.
% salida: uint8 M×N, logical M×N o uint8 M×N×3 (superposición en color).
    lut = uint8(255 * ((0:255) / 255) .^ p.gamma);
    salida = lut(double(entrada) + 1);
end
```

El **registro** (`+nucleo/registro.m`) es la única lista de operaciones. Cada entrada declara nombre, categoría, función y parámetros con rango y valor inicial:

```matlab
op.nombre = 'Corrección gamma';
op.categoria = 'Niveles de gris';
op.funcion = @algoritmos.niveles_gris.gamma;
op.parametros = struct('nombre', {'gamma'}, 'min', {0.1}, 'max', {5}, 'inicial', {1});
```

La interfaz **genera un deslizador por cada parámetro** leyendo el registro. Agregar una operación = un archivo nuevo + una entrada en el registro. Las operaciones de movimiento reciben el cuadro anterior en `p.anterior`, que el pipeline inyecta.

### 2.4 Pipeline y medición

Por cada cuadro: `tic` captura → `toc`; `tic` a gris → `toc`; `tic` operación → `toc`; `tic` despliegue (`set(imagen, 'CData', ...)`, `drawnow limitrate`) → `toc`. Se acumulan en una ventana móvil de 1 s: FPS de cuadros únicos y ms promedio por etapa, mostrados en la figura y volcados a CSV (`resultados/`) para el reporte.

### 2.5 Interfaz

`figure` clásico (no `uifigure`: su renderizado web es más lento para video) con dos ejes (`image` original e `image` procesado), un `popupmenu` de operaciones, deslizadores `uicontrol('style','slider')` generados desde el registro, y un texto con FPS y ms. El lazo principal es un `while` con `drawnow limitrate`; los controles escriben en un objeto `handle` compartido (`Estado`) que el lazo lee en cada iteración, por eso cambiar un parámetro nunca detiene la captura.

### 2.6 Estructura del repositorio

```
PDI_VisionLab/
  principal.m                      arranca la aplicación
  configuracion.m                  cámara, resolución, FPS objetivo, umbral de cuadro repetido
  +visionlab/
    +camara/      Camara.m         abrir webcam, snapshot, detección de cuadro repetido, a gris
    +nucleo/      registro.m       lista de operaciones y parámetros
                  Pipeline.m       aplica la operación activa, mide etapas
                  Estado.m         handle compartido entre interfaz y lazo
    +algoritmos/  +niveles_gris/   negativo.m  gamma.m  umbral.m  ecualizacion.m
                  +tramado/        bayer.m  cuantizacion.m
                  +filtrado/       binomial.m  bordes_binomial.m  laplaciano.m
                  +morfologia/     erosion.m  dilatacion.m
                  +movimiento/     diferencia_cuadros.m  block_matching.m
                  +adicionales/    histograma.m
    +interfaz/    Ventana.m        figura, controles generados, despliegue
    +rendimiento/ Metricas.m       FPS, ms por etapa, CSV
  pruebas/        test_*.m         cada operación contra su referencia (imágenes fijas)
  experimentos/   medir_todo.m     tabla FPS/ms por operación y barridos de parámetros
  recursos/imagenes_prueba/        pentagon256, una captura 640×480, un patrón sintético
  resultados/                      CSV y gráficas
  documentacion/                   fundamentos de cada operación (para el reporte)
```

## 3. Operaciones del mínimo (13)

Lectura estricta de la especificación: A pide "al menos cuatro", B dos, C "al menos tres", D "al menos dos", E describe las dos y dice que el sistema "deberá" dibujar los vectores (así que van las dos), F una.

Tiempos medidos el 2026-11-27 **en lenguaje MATLAB ejecutado con GNU Octave 11.3** en esta laptop, 640×480, sin toolboxes (solo `conv2`, `sort`, `fft2`). MATLAB con su JIT es normalmente igual o más rápido, así que son cotas pesimistas. Presupuesto a 20 FPS: 50 ms por cuadro; captura y despliegue se miden en la fase 0.

| Cat. | Operación | Base en el curso | Parámetros | ms/cuadro (Octave) |
|---|---|---|---|---|
| A | Negativo | Fundamentos | — | 1.2 |
| A | Corrección gamma (LUT de 256 entradas) | Fundamentos | γ ∈ [0.1, 5] | 4.3 |
| A | Umbral binario | P2 (umbral fijo) | umbral 0–255 | 0.2 |
| A | Ecualización de histograma (CDF) | **P3** | — | 12.2 |
| B | Dithering Bayer 2×2 / 4×4 / 8×8 | **P2** (8×8 por la regla recursiva M₂ₙ = [4M, 4M+2; 4M+3, 4M+1]) | tamaño | 0.3 |
| B | Cuantización uniforme | **P2, P3** | niveles 2–256 | 6.4 |
| C | Suavizado binomial separable | **T2, T3, P5** | longitud 3–15 | 7.4 (5×5), 10.1 (9×9) |
| C | Bordes por binomial de orden 1 (gradiente) | **T3** | longitud, umbral | 21.1 |
| C | Laplaciano (binomial de orden 2) | **T3** | longitud | 14.4 |
| D | Erosión (elemento cuadrado, separable) | Nuevo; filtro de rango | tamaño 3–15 | 2.3 (5×5), 4.0 (9×9) |
| D | Dilatación (ídem, con máximo) | Nuevo | tamaño 3–15 | ≈ erosión |
| E | Diferencia de cuadros con umbral y superposición | Nuevo; reutiliza el umbral | umbral | 4.9 |
| E | Block matching con SAD y flechas (sobre 320×240) | **P3** (misma búsqueda que la correlación del mosaico, con SAD) | bloque, radio | 15.1 |
| F | Histograma dinámico (original y procesado) | **P3** | — | ≈ 3 |

Todas caben en el presupuesto. La única operación lenta medida (mediana 3×3, 38 ms) **no está en el mínimo**.

## 4. Verificación

- `pruebas/test_<operacion>.m`: aplica la operación a las imágenes fijas y la compara con una referencia. Donde existe función de toolbox (`histeq`, `imfilter`, `imerode`, `imdilate`) se compara contra ella con tolerancia de 1 nivel de gris; donde no (Bayer, cuantización, block matching) se comparan contra los resultados de las prácticas P2 y P3 y contra casos construidos a mano (imágenes pequeñas con resultado conocido).
- Los algoritmos y sus pruebas se pueden **desarrollar y ejecutar hoy en Octave**; solo la cámara y la interfaz requieren MATLAB.
- La tabla "operación / referencia / error máximo" va al reporte como evidencia de "correcta implementación" (35 %).

## 5. Experimentos para el reporte

`experimentos/medir_todo.m` corre, sin interfaz, cada operación sobre una grabación corta de la cámara y registra: ms por cuadro por operación, FPS efectivos del sistema completo, y barridos de parámetros (longitud binomial 3→15, tamaño de Bayer, niveles de cuantización, tamaño del elemento estructurante, bloque y radio en block matching). Salida: CSV en `resultados/` y gráficas generadas con `plot`/`bar` para el reporte.

## 6. Plan de construcción (lo ejecuta Claude)

| Fase | Qué se construye | Criterio de aceptación |
|---|---|---|
| **0. Puerta de desempeño** (requiere MATLAB instalado) | Script que abre la cámara, toma 200 cuadros, los muestra con `image` + `drawnow limitrate` y mide ms de captura, conversión y despliegue | Captura + despliegue **≤ 25 ms** por cuadro único; si no, ver §7 |
| **1. Núcleo** | `Camara`, `Estado`, `Pipeline`, `registro`, `Ventana` con una operación (negativo), FPS y ms en pantalla | Video original y procesado a ≥ 20 FPS cambiando el parámetro sin cortes |
| **2. Operaciones** | Las 13 de §3, desarrolladas y probadas primero en Octave, integradas vía registro | Todas las pruebas pasan; cada una ≤ 30 ms en MATLAB |
| **3. Medición y experimentos** | `Metricas` con CSV, `medir_todo.m`, gráficas | CSV y gráficas generados para las 13 operaciones |
| **4. Documentación** | README (instalación: MATLAB + Support Package; ejecución: `principal`), `documentacion/` con fundamentos por operación tomados de las prácticas | Un integrante nuevo instala y corre el sistema siguiendo solo el README |

## 7. Contingencia (solo si la fase 0 falla)

Si la captura y el despliegue en MATLAB no caben en 25 ms, la alternativa es **Python (OpenCV + PyQt6) para captura y despliegue, y los mismos algoritmos MATLAB vía MATLAB Engine for Python** compartiendo el cuadro por archivo mapeado en memoria (`memmapfile` / `numpy.memmap`) para no copiarlo en cada llamada. Requiere MATLAB ≥ R2024b (soporte del engine para Python 3.12). Se decide con datos, no antes.

## 8. Estado y pendientes para empezar

- MATLAB **no está instalado** en la laptop de Jesús (quedan 217 MB de restos de R2023b sin ejecutables); la instalación requiere iniciar sesión con la cuenta de MathWorks ligada a la licencia de la UNAM (instrucciones entregadas en el chat). Productos: MATLAB, Image Processing Toolbox (solo para las referencias de §4) y el complemento gratuito *MATLAB Support Package for USB Webcams*.
- GNU Octave 11.3 ya está instalado para construir y probar los algoritmos desde ahora.
- El repositorio `PDI_VisionLab` cambia de Python a MATLAB con la estructura de §2.6; el esqueleto actual de Jonathan se conserva en el historial de Git.

Fuera de alcance por ahora (se pondera cuando el mínimo esté construido y probado): Raspberry Pi, operaciones opcionales (mediana, unsharp, Floyd–Steinberg, FFT, zoom por interpolación, apertura/cierre), interfaz web.
