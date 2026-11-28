# PDI VisionLab

Sistema interactivo de procesamiento digital de video en tiempo real.

## 1. Descripción

PDI VisionLab es un proyecto académico desarrollado para la asignatura de
Procesamiento Digital de Imágenes (LAPI, FI-UNAM).

El sistema captura video de una cámara web, convierte cada cuadro a escala de
grises, le aplica la operación elegida por el usuario y muestra lado a lado el
video original y el procesado. Mientras corre, informa los cuadros únicos por
segundo (FPS) y los milisegundos que toma cada etapa: captura, conversión a
gris, operación y despliegue.

Incluye 14 operaciones agrupadas en 6 categorías: niveles de gris, dithering y
cuantización, filtrado y bordes, morfología, movimiento y adicionales. Los
algoritmos están implementados en MATLAB base (operaciones matriciales y
`conv2`), sin funciones de la Image Processing Toolbox.

## 2. Integrantes

- Jonathan
- Jesús
- Arely

## 3. Requisitos

- Windows.
- MATLAB R2024b o posterior (probado en R2026b).
- MATLAB Support Package for USB Webcams (gratuito). Se instala desde
  **Home > Add-Ons > Get Hardware Support Packages**, buscando "USB Webcams".
- Image Processing Toolbox: solo la usan las pruebas para comparar contra
  funciones de referencia (`imadjust`, `imerode`, etc.). Si no está instalada,
  esas comparaciones se omiten y el resto de cada prueba corre igual. El
  programa principal no la necesita.
- Opcional: GNU Octave, para correr las pruebas de los algoritmos sin MATLAB.

Respaldo si no está el paquete de webcam: `Camara.m` puede capturar con
OpenCV a través del intérprete de Python embebido en MATLAB (`pyenv`). Es solo
captura; todo el procesamiento es MATLAB. Para usarlo hace falta un entorno
`.venv` con opencv-python en la raíz del repositorio:

```bat
python -m venv .venv
.venv\Scripts\pip install opencv-python numpy
```

`cfg.camara.python` de `configuracion.m` ya apunta a `.venv\Scripts\python.exe`
relativo a la raíz, así que no hay que editar nada. Con el paquete de webcam
instalado este paso no es necesario.

## 4. Instalación

1. Clonar el repositorio:

   ```bash
   git clone https://github.com/jonathanGF/PDI_VisionLab.git
   ```

2. Abrir MATLAB y cambiar la carpeta actual a `PDI_VisionLab` (la raíz del
   repositorio, donde está `principal.m`).

No hace falta agregar carpetas al path: `principal.m` agrega la raíz y MATLAB
encuentra los paquetes `+visionlab` desde ahí.

## 5. Ejecución

Desde la ventana de comandos de MATLAB, en la raíz del repositorio:

```matlab
principal
```

Al cerrar la ventana se imprime un resumen (lecturas, cuadros únicos, FPS y ms
promedio y mediana por etapa, memoria de MATLAB y CPU medio) y se guardan las
métricas en `resultados/`, la carpeta de trabajo (ignorada por git).

### Opciones

`principal` acepta un `struct` con estas opciones (todas opcionales):

| Opción | Valor por defecto | Qué hace |
|--------|-------------------|----------|
| `sin_camara` | `false` | Usa cuadros sintéticos de 480x640 (franjas y un círculo en movimiento) en lugar de la cámara |
| `sin_ventana` | `false` | No abre la figura; solo captura, procesa y mide |
| `cuadros_max` | `0` | Número de lecturas antes de terminar (0 = sin límite) |
| `recorrer` | `false` | Pasa por las 14 operaciones del registro y al final imprime una tabla por operación |
| `cuadros_por_op` | `60` | Cuadros únicos por operación durante el recorrido |

Ejemplos:

```matlab
% Prueba rápida sin cámara: 150 lecturas
principal(struct('sin_camara', true, 'cuadros_max', 150))

% Medir todas las operaciones con la cámara, 60 cuadros únicos cada una
principal(struct('recorrer', true))

% Recorrido sin ventana, 100 cuadros únicos por operación
principal(struct('recorrer', true, 'sin_ventana', true, 'cuadros_por_op', 100))
```

Sin ventana conviene fijar `cuadros_max` o usar `recorrer`, porque no hay botón
Salir y el lazo solo se detiene con Ctrl+C.

### Configuración de la cámara

Todo se ajusta en `configuracion.m`:

| Campo | Valor actual | Significado |
|-------|--------------|-------------|
| `cfg.camara.backend` | `'auto'` | `'auto'` usa webcam si el paquete está instalado y, si no está o falla al abrir, OpenCV; también acepta `'webcam'` u `'opencv'` |
| `cfg.camara.indice` | `1` | Cámara a usar; 1 es la primera. Con webcam la lista de cámaras se obtiene con `webcamlist` (OpenCV cuenta desde 0 y usa `indice - 1`) |
| `cfg.camara.resolucion` | `[640 480]` | `[ancho alto]` |
| `cfg.camara.exposicion` | `-5` | `'auto'` o un entero; más negativo es una exposición más corta |
| `cfg.camara.brillo` | `100` | Solo se aplica con exposición manual |
| `cfg.camara.gamma` | `100` | Solo se aplica con exposición manual |
| `cfg.camara.submuestreo_duplicados` | `8` | Se compara 1 de cada 8 píxeles para detectar cuadros repetidos |
| `cfg.camara.python` | `.venv\Scripts\python.exe` relativo a la raíz | Intérprete del entorno con OpenCV (solo para el respaldo `'opencv'`) |
| `cfg.fps_objetivo` | `20` | FPS objetivo que aparece en el resumen |
| `cfg.metricas.ventana_s` | `1` | Ventana móvil (s) para el FPS y los promedios en pantalla |
| `cfg.metricas.carpeta` | `'resultados'` | Carpeta de trabajo de los CSV de métricas |

### Iluminación y exposición

Con exposición automática y poca luz la cámara alarga el tiempo de exposición
y entrega solo de 9 a 15 cuadros únicos por segundo, aunque el procesamiento
sea mucho más rápido. Por eso la configuración trae exposición manual:

```matlab
cfg.camara.exposicion = -5;
cfg.camara.brillo = 100;
cfg.camara.gamma = 100;
```

Con estos valores la cámara entrega unos 30 cuadros únicos por segundo; el
brillo y la gamma compensan la imagen más oscura. Se recomienda trabajar con
buena iluminación (luz de frente, sin contraluz) para que la imagen no quede
oscura con la exposición corta. Si la cámara no acepta alguno de estos
valores, el programa muestra una advertencia y continúa.

## 6. Uso de la interfaz

- **Video**: a la izquierda el original en color y a la derecha el resultado
  de la operación activa.
- **Menú de operaciones**: lista desplegable con las 14 operaciones, agrupadas
  por categoría con el formato `Categoría: Nombre`. Al elegir una, sus
  parámetros vuelven al valor inicial.
- **Deslizadores**: se crean automáticamente, uno por parámetro de la
  operación activa, con su nombre y valor actual. El cambio se aplica mientras
  se arrastra; los parámetros enteros avanzan en pasos fijos (por ejemplo, la
  longitud de los kernels va de 2 en 2 para quedar impar).
- **FPS y ms**: texto con los FPS de cuadros únicos y las lecturas por segundo
  del último segundo, y los ms promedio de captura, gris, operación,
  despliegue y su suma.
- **Salir**: cierra la ventana y termina el programa (cerrar con la X hace lo
  mismo). La cámara se libera y el CSV se escribe aunque haya un error o se
  interrumpa con Ctrl+C.

## 7. Pruebas

Hay una prueba por operación (`pruebas/test_*.m`), con imágenes pequeñas de
resultado calculado a mano, casos de borde y, cuando la Image Processing
Toolbox está disponible, comparación contra la función equivalente. Además,
`test_integracion.m` corre `principal` con la cámara sintética y sin ventana
recorriendo todas las operaciones, y revisa el CSV del recorrido.

En MATLAB o en GNU Octave:

```matlab
cd pruebas
correr_pruebas
```

`correr_pruebas` busca todos los `test_*.m` de la carpeta (las 14 de
operaciones y `test_integracion`), los ejecuta, imprime una tabla con el estado
(`OK` o `FALLA`) y el mensaje de cada uno, y el total de pruebas correctas. Una
prueba nueva se incluye sola con solo nombrarla `test_<algo>.m`.

## 8. Experimentos

```matlab
cd experimentos
medir_todo
```

`medir_todo` toma dos cuadros reales de la cámara (si falla, usa sintéticos),
mide cada operación con sus parámetros iniciales (2 corridas de calentamiento
y 20 medidas) y barre los parámetros de las operaciones más costosas. Escribe
en `resultados/` (carpeta de trabajo):

- `tiempos_operaciones.csv`: mediana y percentil 90 de ms por operación, y FPS
  máximo (1000 / mediana).
- `tiempos_operaciones.png`: gráfica de barras con las líneas de 50 ms (20 FPS)
  y 33 ms (30 FPS).
- `barridos.csv` y `barrido_*.png`: tiempo en función de cada parámetro
  barrido.

Además, cada ejecución de `principal` deja en `resultados/`:

- `metricas_<fecha>.csv`: una fila por lectura con los ms de cada etapa.
- `metricas_<fecha>_promedios.csv`: promedios por operación.
- `recorrido_<fecha>.csv`: tabla por operación (solo con `recorrer`), con FPS
  únicos, medianas por etapa, memoria en MB y CPU %.

Otros dos scripts escriben directamente en `documentacion/experimentos/figuras/`:

- `calidad_visual`: aplica cada operación a la imagen estándar peppers.png
  (ampliada a 640×480) con varios valores
  del parámetro, guarda un mosaico PNG por operación y calcula MSE y PSNR
  (`mosaico_*.png`, `calidad.csv`).
- `grafica_fps_sistema`: gráfica de FPS únicos del sistema completo por
  operación a partir de `recorrido_camara.csv` (`fps_sistema.png`).

`resultados/` es la carpeta de trabajo y no se sube al repositorio (está en
`.gitignore`). Los resultados y figuras del entregable están en
`documentacion/experimentos/figuras/`, y su análisis en
`documentacion/experimentos/resultados.md`.

Los scripts `fase0_*.m` son las mediciones iniciales de la cámara (costo de
captura, conversión y despliegue, y efecto de la exposición, el brillo y la
gamma) que sirvieron para elegir la configuración.

## 9. Estructura del repositorio

```
PDI_VisionLab/
├── principal.m                    # Programa principal: captura, procesa, muestra y mide
├── configuracion.m                # Cámara, exposición, FPS objetivo y métricas
├── +visionlab/
│   ├── +camara/
│   │   ├── Camara.m               # Captura con webcam, OpenCV o cuadros sintéticos; detecta repetidos
│   │   └── a_gris.m               # RGB a gris (0.299 R + 0.587 G + 0.114 B)
│   ├── +nucleo/
│   │   ├── registro.m             # Lista única de operaciones y sus parámetros
│   │   ├── Estado.m               # Operación activa y parámetros compartidos con la interfaz
│   │   └── Pipeline.m             # Aplica la operación y mide su tiempo
│   ├── +interfaz/
│   │   └── Ventana.m              # Figura, menú, deslizadores, texto de FPS y botón Salir
│   ├── +rendimiento/
│   │   └── Metricas.m             # FPS, ms por etapa y exportación a CSV
│   └── +algoritmos/
│       ├── +niveles_gris/         # negativo, gamma, umbral, ecualizacion
│       ├── +tramado/              # bayer, cuantizacion
│       ├── +filtrado/             # binomial, bordes_binomial, laplaciano
│       ├── +morfologia/           # erosion, dilatacion
│       ├── +movimiento/           # diferencia_cuadros, block_matching
│       └── +adicionales/          # histograma
├── pruebas/
│   ├── correr_pruebas.m           # Ejecuta todos los test_*.m
│   ├── test_*.m                   # Una prueba por operación (14)
│   └── test_integracion.m         # Corre principal sin cámara ni ventana y revisa el CSV
├── experimentos/
│   ├── medir_todo.m               # Tiempos por operación y barridos de parámetros
│   ├── calidad_visual.m           # Mosaicos y PSNR por operación
│   ├── grafica_fps_sistema.m      # Gráfica de FPS del sistema completo
│   └── fase0_*.m                  # Mediciones iniciales de la cámara
├── documentacion/
│   ├── arquitectura/              # Arquitectura y propuesta de diseño y construcción
│   ├── experimentos/              # resultados.md y figuras/ (CSV y PNG del entregable)
│   └── algoritmos/                # Un documento por operación e indice.md
├── recursos/                      # Imágenes de prueba (cuadro_prueba.png)
└── resultados/                    # Carpeta de trabajo: CSV y PNG generados (ignorada por git)
```

## 10. Cómo agregar una operación

1. Crear el archivo de la operación en la subcarpeta de su categoría dentro de
   `+visionlab/+algoritmos/`, con la firma:

   ```matlab
   function salida = mi_operacion(entrada, p)
   % entrada: imagen uint8 en gris. p: struct con un campo por parámetro.
   ```

   - `entrada` es el cuadro en gris (uint8, 480x640).
   - `p` tiene un campo por cada parámetro registrado, con el nombre que se le
     dio en el registro (`p.umbral`, `p.longitud`, ...). Si la operación es de
     movimiento, `p.anterior` trae el cuadro anterior en gris.
   - `salida` puede ser uint8 en gris, `logical` (se muestra como 0/255) o una
     imagen RGB uint8.

2. Añadir una entrada al final de `+visionlab/+nucleo/registro.m`, con el
   siguiente índice libre:

   ```matlab
   % Mi operación: qué controla su parámetro
   ops(15).nombre = 'Mi operación';
   ops(15).categoria = 'Filtrado y bordes';
   ops(15).funcion = @visionlab.algoritmos.filtrado.mi_operacion;
   ops(15).movimiento = false;
   ops(15).parametros = struct('nombre', 'umbral', 'min', 0, 'max', 255, 'inicial', 128, 'paso', 1);
   ```

   - `categoria`: el menú agrupa por este texto; una categoría nueva aparece
     como grupo nuevo.
   - `movimiento`: `true` si la operación necesita el cuadro anterior.
   - `parametros`: un `struct` por parámetro con `nombre`, `min`, `max`,
     `inicial` y `paso` (`paso` 0 = continuo; mayor que 0 = el deslizador
     avanza de `paso` en `paso` desde `min`). Para varios parámetros se usan
     celdas:

     ```matlab
     ops(15).parametros = struct('nombre', {'bloque', 'radio'}, 'min', {8, 1}, ...
         'max', {32, 6}, 'inicial', {16, 3}, 'paso', {8, 1});
     ```

     Sin parámetros se usa `ops(15).parametros = sin_parametros;`.

3. (Recomendado) Agregar `pruebas/test_mi_operacion.m`; `correr_pruebas` lo
   encuentra solo.

No hay que tocar la interfaz, el pipeline ni los experimentos: el menú, los
deslizadores, el recorrido y la tabla de tiempos de `medir_todo` se generan a
partir del registro.

## 11. Hardware de pruebas

Todas las mediciones se hicieron en este equipo (detalle en
`documentacion/experimentos/resultados.md`):

| Concepto | Valor |
|----------|-------|
| Equipo | Laptop HUAWEI NBM-WXX9 |
| Procesador | AMD Ryzen 5 5500U with Radeon Graphics, 6 núcleos, 12 procesadores lógicos |
| RAM | 7.3 GB |
| Sistema operativo | Windows 11 Home Single Language, versión 10.0.26200 |
| Software | MATLAB R2026b en modo `-batch`, una sola instancia, sin otra carga |
| Cámara | `HD Camera` integrada, backend `webcam`, a 640x480 |
| Exposición | Manual -5, brillo 100, gamma 100 |

## 12. Operaciones

Tiempos de `documentacion/experimentos/figuras/tiempos_operaciones.csv`:
mediana y percentil 90 de 20 medidas de la operación sola (sin captura,
conversión ni despliegue) sobre un cuadro real de 640x480, con los parámetros
iniciales, en el equipo de la sección anterior. FPS máx = 1000 / mediana.

| # | Operación | Categoría | Parámetros (rango, inicial) | ms mediana | ms p90 | FPS máx |
|---|-----------|-----------|-----------------------------|-----------:|-------:|--------:|
| 1 | Negativo | Niveles de gris | ninguno | 0.031 | 0.278 | 32000.0 |
| 2 | Corrección gamma | Niveles de gris | `gamma` 0.1-5 (continuo), 1 | 2.793 | 3.104 | 358.1 |
| 3 | Umbral binario | Niveles de gris | `umbral` 0-255, 128 | 0.106 | 0.212 | 9411.8 |
| 4 | Ecualización de histograma | Niveles de gris | ninguno | 4.707 | 5.361 | 212.5 |
| 5 | Dithering Bayer (2x2, 4x4, 8x8) | Dithering y cuantización | `orden` 1-3 (2x2, 4x4, 8x8), 2 | 3.477 | 3.843 | 287.6 |
| 6 | Cuantización uniforme | Dithering y cuantización | `niveles` 2-256, 8 | 2.654 | 2.855 | 376.7 |
| 7 | Suavizado binomial | Filtrado y bordes | `longitud` 3-15 impar, 5 | 3.071 | 3.835 | 325.6 |
| 8 | Bordes (binomial orden 1) | Filtrado y bordes | `longitud` 3-11 impar, 5; `umbral` 0-255 (0 = magnitud en gris), 0 | 5.531 | 6.160 | 180.8 |
| 9 | Laplaciano (binomial orden 2) | Filtrado y bordes | `longitud` 3-11 impar, 3 | 6.927 | 7.632 | 144.4 |
| 10 | Erosión | Morfología | `tamano` 3-15 impar, 5 | 2.166 | 2.424 | 461.7 |
| 11 | Dilatación | Morfología | `tamano` 3-15 impar, 5 | 2.192 | 2.559 | 456.2 |
| 12 | Diferencia de cuadros | Movimiento | `umbral` 1-128, 25 | 0.645 | 0.844 | 1550.4 |
| 13 | Block matching (SAD) | Movimiento | `bloque` 8-32 de 8 en 8, 16; `radio` 1-6, 3 | 11.343 | 14.797 | 88.2 |
| 14 | Histograma | Adicionales | ninguno | 2.358 | 2.928 | 424.1 |

Con sus parámetros iniciales todas las operaciones quedan por debajo de 33 ms
(30 FPS). El FPS real también depende de la captura, la conversión a gris y el
despliegue, que la interfaz mide en cada cuadro: en el recorrido con la cámara
(`documentacion/experimentos/figuras/recorrido_camara.csv`) el sistema completo
dio entre 24.0 y 32.3 FPS únicos según la operación, y 29.3 en toda la corrida.
