# Arquitectura de PDI VisionLab

Este documento describe el sistema tal como está construido en MATLAB. Se redactó leyendo el código, no el diseño original; para las decisiones de diseño y la arquitectura prevista véase `propuesta-diseno-construccion.md` en esta misma carpeta.

## 1. Resumen y decisión de lenguaje

PDI VisionLab captura video de la cámara, convierte cada cuadro a gris, le aplica la operación elegida en una ventana y muestra el original junto al procesado, con los FPS de cuadros únicos y los milisegundos de cada etapa.

Todo el sistema está en MATLAB: un solo lenguaje, un solo proceso y un solo repositorio. La decisión se tomó porque la especificación deja libre el lenguaje y los algoritmos del proyecto ya se implementaron y explicaron en las prácticas del curso (histogramas, filtros espaciales, convolución, interpolación). Mezclar Python para la captura con MATLAB para los algoritmos obligaría a dos procesos y a copiar cada cuadro entre ellos, sin beneficio para el alcance del proyecto.

El papel de las prácticas es doble. Primero, son la fuente de los algoritmos: el dithering de Bayer y la cuantización a 1 bit (Práctica 2), la ecualización de histograma (Práctica 3), los filtros espaciales no lineales (Práctica 4) y los kernels binomiales, que vienen de las Tareas 2 y 3 (coeficientes binomiales y operadores de derivada) y de la Práctica 5 (kernels separables e interpolación), se reutilizan en `+visionlab/+algoritmos`. Segundo, fijan el estilo: las funciones se escriben a mano, sin depender de las de la Image Processing Toolbox, que solo se usan en las pruebas como referencia cuando existen, y cada una lleva su prueba con resultados calculados a mano.

Excepción deliberada al "todo en MATLAB": la cámara tiene un segundo backend que usa OpenCV a través del intérprete de Python embebido en MATLAB (`pyenv`). Es solo un respaldo de captura para cuando no está instalado el paquete de webcam; ningún algoritmo de procesamiento corre en Python.

## 2. Estructura del repositorio

```
PDI_VisionLab/
  principal.m             punto de entrada: lazo principal
  configuracion.m         configuración general (cámara, FPS objetivo, métricas)
  +visionlab/
    +camara/              Camara.m, a_gris.m
    +nucleo/              registro.m, Estado.m, Pipeline.m
    +interfaz/            Ventana.m
    +rendimiento/         Metricas.m
    +algoritmos/          una subcarpeta por categoría, un .m por operación
  pruebas/                correr_pruebas.m, un test_*.m por algoritmo y test_integracion.m
  experimentos/           mediciones de la fase 0 y evaluación experimental
  resultados/             carpeta de trabajo: CSV y gráficas que generan los scripts (ignorada por git)
  documentacion/          arquitectura, algoritmos, experimentos
    experimentos/figuras/ CSV y PNG del entregable
  recursos/               imágenes de prueba (cuadro_prueba.png)
```

Las carpetas vacías del esqueleto inicial (`pruebas/algoritmos`, `pruebas/camara`, `pruebas/integracion`, `pruebas/rendimiento`, `recursos/iconos` y `documentacion/fundamentos_matematicos`) se borraron: las pruebas están directamente en `pruebas/`, el fundamento de cada operación está en `documentacion/algoritmos/` y la interfaz no usa iconos.

Los paquetes `+visionlab/...` se invocan con su nombre completo (por ejemplo `visionlab.nucleo.registro()`). `principal.m` agrega la raíz del repositorio al path con `addpath(raiz)`, donde `raiz` se obtiene de `mfilename('fullpath')`.

## 3. Diagrama de flujo de datos

Cada iteración del lazo principal recorre estas etapas. Entre corchetes aparece la medición que se toma de cada una (en milisegundos, con `tic`/`toc`).

```
  Camara.leer()                                   [ms_captura]
     |  rgb uint8 alto x ancho x 3, y la bandera "nuevo"
     |
     +-- nuevo = false --> metricas.registrar(ms_captura, 0, 0, 0, false, op)
     |                     (no se procesa; solo cuenta como lectura)
     |
     +-- nuevo = true
           |
           v
  camara.a_gris(rgb)                              [ms_gris]
     |  gris uint8 alto x ancho
     v
  Pipeline.procesar(gris, op, estado)             [ms_operacion]
     |  op.funcion(gris, p) con p = estado.p
     |  (movimiento: p.anterior = cuadro anterior en gris)
     |  salida: uint8 gris, uint8 RGB o logical
     v
  Pipeline.a_despliegue(salida)                   [ms_despliegue]
     |  logical -> uint8 0/255; uint8 se deja igual
     v
  ventana.mostrar(rgb, img); ventana.texto(...); drawnow limitrate
     |  (aquí se atienden también los controles de la ventana)
     v
  metricas.registrar(ms_captura, ms_gris, ms_operacion, ms_despliegue, true, nombre_op)
```

Puntos de medición exactos en `principal.m`:

| Etapa | Qué incluye el tiempo |
|-------|-----------------------|
| captura | solo `cam.leer()`, incluida la comparación para detectar cuadros repetidos |
| gris | solo `a_gris(rgb)` |
| operación | solo la llamada `op.funcion(gris, p)` dentro de `Pipeline.procesar` (la asignación de `p.anterior` y el guardado del cuadro previo quedan fuera) |
| despliegue | `a_despliegue`, `ventana.mostrar`, `ventana.texto` y `drawnow limitrate`; sin ventana solo cuenta `a_despliegue` |

La lectura de la operación activa (`op = ops(estado.op)`) se hace después de capturar, para no mezclar una operación vieja con parámetros nuevos escritos por la ventana mientras se esperaba el cuadro.

## 4. principal.m

Firma: `principal(opts)`. Se llama sin argumentos o con una estructura de opciones.

| Opción | Valor por defecto | Efecto |
|--------|-------------------|--------|
| `cuadros_max` | 0 | Número de lecturas antes de terminar; 0 significa sin límite |
| `sin_camara` | false | Fuerza `cfg.camara.backend = 'sintetica'` (cuadros 480x640 generados) |
| `sin_ventana` | false | No abre la figura; solo captura, procesa y mide |
| `recorrer` | false | Modo recorrido (ver más abajo) |
| `cuadros_por_op` | 60 | Cuadros únicos por operación en el modo recorrido |

Las opciones que faltan se completan con `isfield`. Ejemplo: `principal(struct('cuadros_max', 150, 'sin_camara', true))`.

Secuencia:

1. Opciones y path (raíz del repositorio).
2. `cfg = configuracion()`, `ops = visionlab.nucleo.registro()` y un `Estado` nuevo; se activa la operación 1 con `estado.cambiar_operacion(1, ops)`. La carpeta de resultados es `fullfile(raiz, cfg.metricas.carpeta)`.
3. Cámara: se crea `Camara`, se registra `onCleanup(@() cam.cerrar())` y se abre con `cam.abrir(cfg)`; se imprime el nombre y el tiempo de apertura. Después se crea la `Ventana` (salvo `sin_ventana`) y las `Metricas`.
4. Lazo `while estado.corriendo && (cuadros_max == 0 || k < cuadros_max)`. `estado.corriendo` pasa a false cuando se cierra la figura. En cada vuelta se captura, se lee la operación, se descarta el cuadro si es repetido (con `drawnow limitrate` para seguir atendiendo la interfaz) o se ejecuta el flujo de la sección 3.
5. Cierre: `metricas.tomar_recursos` toma la última muestra de memoria y CPU, `metricas.resumen(true)` toma toda la corrida, se hace `clear cierre cierre_camara` para disparar los `onCleanup` y se imprimen lecturas, lecturas por segundo, cuadros únicos, FPS únicos frente a `cfg.fps_objetivo`, los ms por etapa (promedios y medianas con su suma), la memoria de MATLAB al inicio y al final y el CPU medio del proceso.

onCleanup: hay dos objetos. `cierre_camara` libera la cámara y `cierre` ejecuta la función local `liberar(ventana, metricas, carpeta)`, que exporta el CSV si hubo lecturas y cierra la figura. Al ser `onCleanup`, esto ocurre también si hay un error o el usuario interrumpe con Ctrl+C, de modo que la cámara no queda ocupada y las métricas no se pierden.

Modo recorrido (`recorrer = true`): cuenta cuadros únicos por operación; al llegar a `cuadros_por_op` llama `metricas.tomar_recursos(op.nombre)` para cerrar el tramo de esa operación y pasa a la siguiente del registro, y al terminar la última sale del lazo con `break`. Con ventana, el cambio se hace asignando el `Value` del menú y llamando a su callback, para que también se regeneren los deslizadores; sin ventana se usa `estado.cambiar_operacion`. Al final imprime una tabla (únicos, FPS, medianas de captura, gris, operación y despliegue, memoria en MB al terminar y CPU % por operación) y escribe `recorrido_*.csv` con `metricas.exportar_recorrido`.

## 5. configuracion.m

Devuelve la estructura `cfg`. Campos y efecto:

| Campo | Valor actual | Efecto |
|-------|--------------|--------|
| `camara.backend` | `'auto'` | `'auto'` prueba `webcam` y cae a OpenCV; también `'webcam'`, `'opencv'` y `'sintetica'` (esta última la fuerza `sin_camara`) |
| `camara.indice` | 1 | Cámara a abrir; `webcam` usa 1 como la primera y OpenCV recibe `indice - 1` |
| `camara.resolucion` | `[640 480]` | `[ancho alto]` solicitado; con OpenCV se vuelve a leer el tamaño real entregado |
| `camara.python` | `fullfile(raiz, '.venv', 'Scripts', 'python.exe')`, con `raiz` = carpeta de `configuracion.m` | Intérprete que usa `pyenv` en el backend OpenCV. La ruta es relativa a la raíz del repositorio, así que funciona en cualquier equipo; el `.venv` con opencv-python solo hace falta si no está instalado el paquete de webcam |
| `camara.submuestreo_duplicados` | 8 | Se compara 1 de cada 8 píxeles (en filas y columnas) para detectar cuadros repetidos |
| `camara.exposicion` | -5 | `'auto'` o un entero; más negativo significa exposición más corta. En auto la cámara alarga la exposición con poca luz y baja a 9-15 cuadros únicos por segundo; con -5 entrega unos 30 |
| `camara.brillo` | 100 | Solo se aplica con exposición manual |
| `camara.gamma` | 100 | Solo se aplica con exposición manual y solo en el backend `webcam` |
| `fps_objetivo` | 20 | Solo se usa para imprimir el objetivo en el resumen final; no limita el lazo |
| `metricas.ventana_s` | 1 | Duración de la ventana móvil para FPS y promedios |
| `metricas.carpeta` | `'resultados'` | Carpeta (relativa a la raíz) donde se escriben los CSV |

## 6. Paquete +visionlab/+camara

### 6.1 Camara (clase handle)

Propiedad pública: `nombre` (texto con el backend y la cámara). Privadas: `backend`, `cam` (objeto webcam), `cap` (VideoCapture de OpenCV), `ancho`, `alto`, `paso`, `muestra` (versión submuestreada del cuadro anterior), y `k`, `X`, `Y` para la cámara sintética.

Métodos:

- `abrir(cfg)`: lee resolución y `submuestreo_duplicados`, y según `cfg.camara.backend`:
  - `'auto'`: asume OpenCV; si existe `webcam` en el path intenta `abrir_webcam` y, si falla (por ejemplo cámara ocupada), emite el aviso `Camara:webcam` y usa `abrir_opencv`.
  - `'webcam'` y `'opencv'`: abren directamente ese backend.
  - `'sintetica'`: genera las mallas `X`, `Y` y no toca hardware.
  - Cualquier otro valor produce el error `Camara:abrir`.

  Al final reinicia `muestra`.
- `leer()`: devuelve `[rgb, nuevo]`. Con `webcam` usa `snapshot`. Con OpenCV llama `cap.read()`, convierte el arreglo numpy BGR con `uint8(fr.tobytes())`, `reshape` a `[3 ancho alto]`, `permute` a alto x ancho x 3 y reordena BGR a RGB; si no hay cuadro lanza `Camara:leer`. Con la sintética llama `patron()`.
- `cerrar()`: para `webcam` borra el objeto (eso libera el dispositivo); para OpenCV hace `cap.release()`.

Backend webcam (`abrir_webcam`): usa el MATLAB Support Package for USB Webcams con `webcam(indice)` y fija `Resolution`. En exposición `'auto'` deja `ExposureMode = 'auto'` sin tocar brillo ni gamma; en modo manual fija `Exposure`, `Brightness` y `Gamma`. Si la cámara rechaza algún valor emite el aviso `Camara:exposicion` y continúa. Descarta 10 cuadros de calentamiento y compone `nombre` como `webcam: <nombre> @ <resolución>`.

Backend OpenCV (`abrir_opencv`): si `pyenv` no tiene versión o el ejecutable difiere de `cfg.camara.python` llama `pyenv('Version', ...)`; importa `cv2` con `py.importlib.import_module` y abre `VideoCapture(indice - 1, CAP_MSMF)`. Lanza `Camara:abrir` si no abre. Fija ancho y alto; la exposición usa la convención de OpenCV (`CAP_PROP_AUTO_EXPOSURE` 0.75 es automática y 0.25 manual, luego `CAP_PROP_EXPOSURE` y `CAP_PROP_BRIGHTNESS`). Con MSMF la exposición sí tiene efecto, el brillo no se nota y `get()` no devuelve los valores nuevos; el gamma no se usa. Relee el tamaño real, descarta 15 cuadros y nombra la cámara `OpenCV (MSMF): cámara N @ AxH`.

Detección de cuadros repetidos: la cámara integrada reporta 30 FPS pero con poca luz entrega cuadros duplicados. Después de cada lectura, sea cual sea el backend, se toma `m = rgb(1:s:end, 1:s:end, :)` con `s = submuestreo_duplicados` y `nuevo = ~isequal(m, obj.muestra)`. La primera lectura siempre es nueva porque `muestra` está vacía. Es una comparación exacta sobre una malla submuestreada: barata (con s = 8 se comparan 64 veces menos píxeles) pero puede declarar repetido un cuadro que difiere solo en píxeles no muestreados. Los FPS que se reportan son de cuadros únicos.

Cámara sintética (`patron`): franjas diagonales en R y G y un círculo azul que recorre la imagen; cada cuadro se repite una vez (`f = floor(k / 2)`) para ejercitar la detección de repetidos. Permite correr y probar todo sin cámara.

### 6.2 a_gris

`gris = a_gris(rgb)`: suma ponderada 0.299 R + 0.587 G + 0.114 B calculada en `double` y convertida a `uint8` (que redondea y satura). Entrada uint8 M x N x 3, salida uint8 M x N.

## 7. Paquete +visionlab/+nucleo

### 7.1 registro: formato exacto de una entrada

`ops = visionlab.nucleo.registro()` devuelve un arreglo de estructuras de 14 elementos; es la única lista de operaciones del sistema. Cada entrada `ops(k)` tiene exactamente estos campos:

| Campo | Tipo | Significado |
|-------|------|-------------|
| `nombre` | char | Texto que se muestra en el menú y que se guarda en los CSV |
| `categoria` | char | Agrupa el menú (`'Niveles de gris'`, `'Dithering y cuantización'`, `'Filtrado y bordes'`, `'Morfología'`, `'Movimiento'`, `'Adicionales'`) |
| `funcion` | function handle | `@visionlab.algoritmos.<categoria>.<archivo>`, con firma `salida = f(entrada, p)` |
| `movimiento` | logical | true si la operación necesita el cuadro anterior |
| `parametros` | arreglo de struct | Parámetros editables; vacío si no hay |

Cada elemento de `parametros` es `struct('nombre', ..., 'min', ..., 'max', ..., 'inicial', ..., 'paso', ...)`. El campo `paso` vale 0 para un deslizador continuo y mayor que 0 para valores discretos (múltiplos de `paso` desde `min`). Las operaciones sin parámetros usan `sin_parametros`, una estructura vacía con esos mismos cinco campos, para que todas las entradas sean homogéneas. Ejemplo real:

```matlab
ops(2).nombre = 'Corrección gamma';
ops(2).categoria = 'Niveles de gris';
ops(2).funcion = @visionlab.algoritmos.niveles_gris.gamma;
ops(2).movimiento = false;
ops(2).parametros = struct('nombre', 'gamma', 'min', 0.1, 'max', 5, 'inicial', 1, 'paso', 0);
```

Con varios parámetros se usan celdas en `struct(...)` (por ejemplo bordes: `'nombre', {'longitud', 'umbral'}, 'min', {3, 0}, ...`). Las 14 operaciones actuales:

| # | Nombre | Categoría | Parámetros (min, max, inicial, paso) |
|---|--------|-----------|--------------------------------------|
| 1 | Negativo | Niveles de gris | ninguno |
| 2 | Corrección gamma | Niveles de gris | gamma (0.1, 5, 1, 0) |
| 3 | Umbral binario | Niveles de gris | umbral (0, 255, 128, 1) |
| 4 | Ecualización de histograma | Niveles de gris | ninguno |
| 5 | Dithering Bayer (2x2, 4x4, 8x8) | Dithering y cuantización | orden (1, 3, 2, 1) |
| 6 | Cuantización uniforme | Dithering y cuantización | niveles (2, 256, 8, 1) |
| 7 | Suavizado binomial | Filtrado y bordes | longitud (3, 15, 5, 2) |
| 8 | Bordes (binomial orden 1) | Filtrado y bordes | longitud (3, 11, 5, 2); umbral (0, 255, 0, 1) |
| 9 | Laplaciano (binomial orden 2) | Filtrado y bordes | longitud (3, 11, 3, 2) |
| 10 | Erosión | Morfología | tamano (3, 15, 5, 2) |
| 11 | Dilatación | Morfología | tamano (3, 15, 5, 2) |
| 12 | Diferencia de cuadros | Movimiento | umbral (1, 128, 25, 1); movimiento = true |
| 13 | Block matching (SAD) | Movimiento | bloque (8, 32, 16, 8); radio (1, 6, 3, 1); movimiento = true |
| 14 | Histograma | Adicionales | ninguno |

### 7.2 Estado (clase handle)

Es el canal entre la interfaz y el lazo: la ventana escribe y el lazo lee en cada cuadro. Propiedades: `op` (índice de la operación activa), `p` (estructura con el valor actual de cada parámetro), `corriendo` (true hasta que se cierra la ventana) y `anterior` (cuadro previo en gris). `cambiar_operacion(k, ops)` fija `op = k`, reconstruye `p` con el valor `inicial` de cada parámetro de `ops(k)` y vacía `anterior` para que una operación de movimiento no use un cuadro de otra operación.

### 7.3 Pipeline (métodos estáticos)

- `[salida, t] = procesar(gris, op, estado)`: toma `p = estado.p`. Si `op.movimiento`, agrega `p.anterior`: el cuadro guardado en `estado.anterior` o, en el primer cuadro, el propio `gris` (así la primera salida de movimiento es "sin cambio"). Mide con `tic`/`toc` solo `op.funcion(gris, p)` y devuelve el tiempo en ms. Después guarda `estado.anterior = gris`.
- `img = a_despliegue(salida)`: si `salida` es `logical` la convierte a `uint8` con 0 y 255; cualquier uint8 (gris o RGB) pasa sin cambios. Por eso las operaciones pueden devolver binarias sin ocuparse del despliegue.

## 8. Ventana (+visionlab/+interfaz/Ventana.m)

Clase handle que crea una figura clásica (`figure`, más rápida para video que `uifigure`) de 1300x680, sin barra de menú, con `DeleteFcn` conectado a `al_cerrar`.

Componentes:

- Dos ejes: izquierdo con el original (`image` RGB 480x640x3) y derecho con el procesado (`image` uint8 con `CDataMapping` directo y `gray(256)`, que admite también RGB). Se actualizan con `mostrar(rgb, salida)` cambiando solo `CData`.
- Menú (`popupmenu`) con las operaciones agrupadas por categoría con el texto `Categoría: Nombre`. El orden se obtiene con `unique(..., 'stable')` y `sort` sobre las categorías; `obj.orden` traduce la posición del menú al índice del registro.
- Texto de métricas (`info`), que el lazo actualiza con `ventana.texto(metricas.texto())`.
- Botón Salir, que hace `delete(obj.fig)`.
- Deslizadores generados desde `ops(estado.op).parametros`: uno por parámetro, con etiqueta `nombre = valor`, rango `[min max]` y valor inicial. Si `paso > 0` el `SliderStep` es `[paso, max(paso, 0.1*rango)] / rango`; si es continuo, `[0.01 0.1]`. Además del `Callback` se agrega un listener de `ContinuousValueChange` para que el parámetro cambie mientras se arrastra.

Callbacks:

- `al_elegir`: llama `estado.cambiar_operacion(obj.orden(Value), ops)` y regenera los deslizadores (borra los anteriores y crea los nuevos).
- `al_mover`: lee el valor; con `paso > 0` lo redondea a un múltiplo de `paso` desde `min`, lo acota a `[min max]` y lo reescribe en el deslizador. Guarda `estado.p.(nombre) = v` y actualiza la etiqueta.
- `al_cerrar`: pone `estado.corriendo = false`; se dispara al cerrar con la X o con Salir porque ambos borran la figura.
- `cerrar()`: método público que borra la figura si sigue válida; lo llama `liberar` desde `onCleanup`.

Los controles solo escriben en `Estado`; el lazo nunca se detiene esperando a la interfaz, y los callbacks se atienden en `drawnow limitrate`. El método `abierta()` existe pero el lazo no lo usa: decide con `estado.corriendo`.

## 9. Métricas (+visionlab/+rendimiento/Metricas.m)

Clase handle. Constructor `Metricas(cfg)`: toma `ventana_s`, reserva `datos = zeros(10000, 6)` y `operacion = cell(10000, 1)`, fija `marca = datestr(now, 'yyyymmdd_HHMMSS_FFF')` (con milisegundos, para que dos corridas no se pisen), lee los núcleos lógicos con `feature('numcores')`, toma la primera muestra de recursos y arranca el reloj.

Consumo de recursos: `tomar_recursos(nombre_op)` agrega una fila a `recursos` con la memoria de MATLAB en MB (`memory`, campo `MemUsedMATLAB`; solo existe en Windows, si falla queda `NaN`), el CPU acumulado del proceso y su tiempo de vida, los dos leídos en el mismo instante con PowerShell (`Get-Process` del PID de MATLAB). Como PowerShell tarda unos 0.3 s, solo se llama al inicio, en cada cambio de operación del recorrido y al final, y ese tiempo se acumula en `descontado` y se resta de la línea de tiempo para no afectar los FPS. `cpu_pct(j0, j1)` es el CPU consumido entre dos muestras dividido entre el tiempo de vida transcurrido por el número de núcleos (100 % = todos los núcleos ocupados).

`registrar(ms_captura, ms_gris, ms_operacion, ms_despliegue, nuevo, nombre_op)` agrega una fila por lectura (si se llena el espacio, lo duplica). Columnas de `datos`: tiempo desde el inicio (s), nuevo (0/1), captura, gris, operación, despliegue. Las lecturas repetidas se registran con ceros en gris, operación y despliegue y `nuevo = 0`.

Ventana móvil: `resumen()` avanza `inicio` hasta que la primera fila quede dentro de los últimos `ventana_s` segundos y calcula sobre esas filas. `resumen(true)` usa toda la corrida. Resultado: `fps_unicos` (cuadros únicos entre la duración), `lecturas_por_s`, `lecturas`, `unicos`, `segundos`, promedios por etapa, `medianas` `[captura gris operación despliegue]` y, con `resumen(true)`, `mem_inicio`, `mem_fin` (primera y última muestra de recursos) y `cpu_pct` de toda la corrida. Los promedios y medianas se calculan solo sobre cuadros únicos, que son los que recorren todo el pipeline; las medianas no se ven afectadas por un primer cuadro lento. `texto()` formatea para la ventana: `FPS únicos`, `lecturas/s` y los ms por etapa con su suma.

Archivos que escribe `exportar(carpeta)` (crea la carpeta si no existe, UTF-8):

1. `metricas_<marca>.csv`, una fila por lectura. Columnas:
   `indice,nuevo,operacion,ms_captura,ms_gris,ms_operacion,ms_despliegue`
   El nombre de la operación va entre comillas dobles; los tiempos con 3 decimales. Ejemplo: `1,1,"Negativo",81.242,23.393,10.099,67.878`.
2. `metricas_<marca>_promedios.csv`, una fila por operación (en orden de aparición). Columnas:
   `operacion,lecturas,cuadros_unicos,ms_captura,ms_gris,ms_operacion,ms_despliegue`
   Los ms son promedios solo de cuadros únicos.

`por_operacion()` devuelve una estructura por operación con `nombre`, `unicos`, `fps_unicos` (únicos entre el tiempo acumulado de las lecturas de esa operación), `medianas`, `memoria_mb` (la muestra que cerró la operación) y `cpu_pct` (CPU medio entre la muestra anterior y esa). `exportar_recorrido(carpeta)` la escribe en `recorrido_<marca>.csv` con columnas:
`operacion,cuadros_unicos,fps_unicos,mediana_ms_captura,mediana_ms_gris,mediana_ms_operacion,mediana_ms_despliegue,memoria_mb,cpu_pct`
(FPS con 2 decimales, medianas con 3, memoria y CPU con 1).

## 10. Pruebas

`pruebas/correr_pruebas.m` hace `cd` a la raíz del repositorio, agrega la carpeta de pruebas al path, busca `test_*.m`, ejecuta cada uno con `feval` dentro de `try/catch` e imprime una tabla (prueba, OK o FALLA, mensaje recortado a 70 caracteres) y el total. Devuelve una estructura con `nombres`, `estado` y `mensajes`.

Hay un archivo por operación (`test_gamma.m`, `test_bayer.m`, `test_block_matching.m`, etcétera; 14 en total) directamente en `pruebas/`. Usan `assert` con imágenes pequeñas de resultado calculado a mano, verifican tipo y tamaño de salida, casos extremos y, cuando la función existe en la instalación, comparan contra la referencia de la toolbox (por ejemplo `imadjust` en `test_gamma`), omitiendo la comparación si no está disponible. Cada prueba termina con `disp('OK test_<nombre>')`. Además, `test_integracion.m` corre `principal` con la cámara sintética, sin ventana y en modo recorrido (5 cuadros por operación), comprueba que aparezca exactamente un `recorrido_*.csv` nuevo en `resultados/` y revisa que tenga 14 filas (una por operación) con `mediana_ms_operacion` positiva; busca la columna por nombre, así que no se rompe si el CSV gana columnas. Como su nombre empieza con `test_`, `correr_pruebas` la ejecuta junto con las demás.

## 11. Experimentos

`experimentos/` contiene dos grupos.

Fase 0 (puerta de desempeño y cámara), scripts independientes del sistema principal:

- `fase0_puerta.m`: con la webcam a 640x480 mide captura, conversión a gris y despliegue por cuadro único; criterio de diseño: suma menor o igual a 25 ms.
- `fase0_puerta_cv.m`: la misma medición con captura OpenCV por `pyenv` (backend MSMF o DSHOW).
- `fase0_exposicion.m` y `fase0_brillo.m`: efecto de la exposición manual, el brillo y el gamma sobre la tasa de cuadros únicos.

Evaluación experimental:

- `medir_todo.m` toma dos cuadros reales de la cámara (o sintéticos si falla), mide el tiempo de cada operación con parámetros iniciales (2 corridas de calentamiento y 20 medidas; mediana y percentil 90) y hace barridos de parámetros (1 de calentamiento y 10 medidas por punto). Escribe `tiempos_operaciones.csv`, `barridos.csv` y gráficas PNG en `resultados/`.
- `calidad_visual.m` aplica cada operación a la imagen estándar peppers.png (ampliada a 640×480) con varios valores del parámetro, guarda un mosaico PNG por operación y calcula MSE y PSNR para cuantización, Bayer y binomial. Escribe directamente en `documentacion/experimentos/figuras/` (`mosaico_*.png`, `calidad.csv`) y guarda la imagen en `recursos/imagenes_prueba/cuadro_prueba.png`.
- `grafica_fps_sistema.m` lee `documentacion/experimentos/figuras/recorrido_camara.csv` y dibuja los FPS únicos del sistema completo por operación (`fps_sistema.png`).

`resultados/` es la carpeta de trabajo y está en `.gitignore`: ahí escriben `principal.m` (`metricas_*.csv`, `recorrido_*.csv`) y `medir_todo.m`. Los archivos del entregable se copiaron a `documentacion/experimentos/figuras/`: `tiempos_operaciones.csv`, `barridos.csv` y sus PNG, `recorrido_camara.csv` (recorrido con la cámara y radio 3) y `recorrido_camara_radio4.csv` (el mismo recorrido con el radio inicial anterior). Los resultados y sus condiciones están en `documentacion/experimentos/resultados.md`.

## 12. Cómo agregar una operación

Ejemplo: una operación `solarizar` en la categoría Niveles de gris con un parámetro `corte`.

1. Crear el archivo en la carpeta de paquete de su categoría, `+visionlab/+algoritmos/+niveles_gris/solarizar.m`, con la firma común:

   ```matlab
   function salida = solarizar(entrada, p)
   % entrada: uint8 M x N en gris. p.corte: nivel a partir del cual se invierte.
   salida = entrada;
   m = entrada >= p.corte;
   salida(m) = 255 - entrada(m);
   end
   ```

   Reglas del contrato: la entrada es `uint8` en gris; `p` es una estructura con los parámetros declarados (y `p.anterior` si la operación es de movimiento); la salida puede ser `uint8` gris, `uint8` RGB o `logical` (el despliegue convierte esta última). Al vivir dentro de un paquete, el nombre del archivo no choca con funciones de MATLAB (por eso `gamma` está dentro de `+niveles_gris`).
2. Añadir una entrada al final de `registro.m` con el siguiente índice (aquí 15):

   ```matlab
   ops(15).nombre = 'Solarización';
   ops(15).categoria = 'Niveles de gris';
   ops(15).funcion = @visionlab.algoritmos.niveles_gris.solarizar;
   ops(15).movimiento = false;
   ops(15).parametros = struct('nombre', 'corte', 'min', 0, 'max', 255, 'inicial', 128, 'paso', 1);
   ```

   Sin parámetros se asigna `sin_parametros`; con varios se usan celdas. Si necesita el cuadro anterior se pone `movimiento = true`. Para una categoría nueva basta escribir una `categoria` distinta: el menú la agrupa solo.
3. Escribir `pruebas/test_solarizar.m` (función sin argumentos, con `assert` y `disp('OK test_solarizar')`); `correr_pruebas` la detecta por el prefijo `test_`.
4. No se toca nada más: la ventana genera el menú y los deslizadores desde el registro, `Pipeline` la ejecuta, las métricas la registran por nombre y el modo recorrido la incluye automáticamente.

Verificación: `correr_pruebas`, y luego `principal(struct('sin_camara', true, 'recorrer', true, 'cuadros_por_op', 10))` para ver que aparece en la tabla del recorrido.

## 13. Limitaciones conocidas

- La cámara integrada entrega cuadros duplicados con poca luz; por eso los FPS son de cuadros únicos y la demostración requiere buena iluminación o exposición manual.
- El backend OpenCV necesita crear en cada equipo el entorno `.venv` con opencv-python en la raíz del repositorio; `camara.python` ya apunta ahí de forma relativa.
- No hay pruebas automáticas con la cámara real ni de rendimiento: `test_integracion.m` usa la cámara sintética, y el rendimiento se mide con los scripts de `experimentos/`.
- Erosión y dilatación solo usan un elemento estructurante cuadrado; elegir su forma, opcional en la especificación, no se implementó.
- `fps_objetivo` solo se informa; el sistema no regula la velocidad del lazo.
