# Corrección gamma

| Concepto | Valor |
|----------|-------|
| Archivo | `+visionlab/+algoritmos/+niveles_gris/gamma.m` |
| Categoría | Niveles de gris (operación puntual) |
| Parámetros | `gamma`: mín 0.1, máx 5, inicial 1, paso 0 (continuo) |
| Entrada / salida | uint8 gris M×N / uint8 gris M×N |
| Prueba | `pruebas/test_gamma.m` |

## Qué hace y para qué sirve

Cambia el brillo y el contraste con una ley de potencia. Con `gamma` menor que 1 aclara la imagen y abre los tonos oscuros (sirve para escenas subexpuestas o con poca luz); con `gamma` mayor que 1 oscurece y abre los tonos claros (sirve para escenas sobreexpuestas). Con `gamma` = 1 la imagen no cambia, por eso es el valor inicial del deslizador.

## Fundamento matemático

Es la transformación de potencia de Gonzalez y Woods, escrita sobre niveles normalizados:

$$s = 255 \left( \frac{r}{255} \right)^{\gamma}, \qquad 0.1 \le \gamma \le 5$$

Los extremos son fijos para cualquier $\gamma$: $r = 0 \to s = 0$ y $r = 255 \to s = 255$. La curva es monótona creciente, así que nunca invierte el orden de los niveles.

Lo que decide si una zona gana o pierde contraste es la pendiente de la curva:

$$\frac{ds}{dr} = \gamma \left( \frac{r}{255} \right)^{\gamma - 1}$$

- Si $\gamma < 1$, la pendiente es mayor que 1 en los oscuros (cerca de $r = 0$ tiende a infinito): niveles oscuros cercanos se separan y los claros se comprimen.
- Si $\gamma > 1$, la pendiente es menor que 1 en los oscuros y mayor que 1 en los claros: pasa lo contrario.

Como la entrada es uint8, la función solo puede recibir 256 valores distintos. Por eso basta calcular la transformación una vez para los 256 niveles y guardarla en una tabla de búsqueda (LUT):

$$\text{LUT}[k] = \operatorname{round}\!\left( 255 \left( \frac{k}{255} \right)^{\gamma} \right), \qquad s(x, y) = \text{LUT}[f(x, y)]$$

## Relación con el curso

- Tema de realce espacial: es la transformación de potencia que acompaña al negativo y a la logarítmica. La ley de potencia también aparece en los fundamentos para explicar la respuesta no lineal de monitores y cámaras. La cámara del proyecto tiene su propia gamma de hardware, que `configuracion.m` deja fija en 100; esta operación es independiente de ella.
- Práctica 3 del curso (histogramas): la ecualización y la especificación de histograma también son transformaciones puntuales de 256 entradas. La técnica de la LUT es la misma que usan `ecualizacion.m` y `cuantizacion.m` en este proyecto.

## Implementación

1. `r = (0:255) / 255;` genera los 256 niveles posibles normalizados a $[0, 1]$.
2. `lut = uint8(255 * r .^ p.gamma);` calcula la tabla. `uint8()` redondea al entero más cercano y, como el resultado ya está en $[0, 255]$, no hace falta saturar.
3. `lut(double(entrada) + 1)` toma para cada píxel su valor de la tabla. Se suma 1 porque MATLAB indexa desde 1 (el nivel 0 está en `lut(1)`).
4. `reshape(..., size(entrada))` garantiza que la salida tenga el tamaño de la entrada. Hizo falta porque, al indexar un vector fila con una matriz de una sola columna, Octave devolvía la forma transpuesta; la prueba lo revisa.
5. El parámetro es `p.gamma`, con rango 0.1 a 5 y deslizador continuo (`paso` 0 en `registro.m`, entrada 2).

## Verificación

`pruebas/test_gamma.m` pasa en MATLAB R2026b (incluida la comparación con `imadjust`) y en Octave 11.3. Revisa:

- `gamma = 1` deja la imagen igual.
- Casos hechos a mano con `gamma = 2`: $64 \to 255 (64/255)^2 = 16.06 \to 16$ y $128 \to 64.25 \to 64$. Con `gamma = 0.5`: $64 \to 255\sqrt{64/255} = 127.75 \to 128$.
- Para $\gamma \in \{0.1, 0.7, 1.5, 5\}$ los extremos se quedan en 0 y 255 y la curva sobre la rampa 0-255 nunca baja.
- Una imagen de una sola columna (256×1) conserva su forma.
- En una imagen aleatoria de 48×64 con $\gamma = 2.2$, la LUT coincide exactamente con la fórmula directa aplicada píxel por píxel.
- Contra `imadjust(A, [0 1], [0 1], 2.2)` la diferencia máxima es de 1 nivel (por redondeo).

## Costo medido

De [`tiempos_operaciones.csv`](../experimentos/figuras/tiempos_operaciones.csv) (MATLAB R2026b, 640×480, mediana de 20 corridas):

| Parámetro | ms mediana | ms p90 | FPS máx |
|-----------|-----------:|-------:|--------:|
| gamma = 1 | 2.793 | 3.104 | 358 |

No hay barrido de `gamma` en [`barridos.csv`](../experimentos/figuras/barridos.csv) porque el costo no depende de él: la parte que usa $\gamma$ son 256 potencias, que es despreciable. El costo está en convertir los 307 200 píxeles a double para formar los índices y en la indexación misma. Por eso esta operación cuesta unas noventa veces más que el negativo (0.031 ms), aunque las dos son puntuales: el negativo es una sola resta entera, y la LUT obliga a pasar por un arreglo de índices en double. Escala como $O(MN)$ con el tamaño del cuadro.

Figura: [mosaico_gamma_gamma_0p5_1_2.png](../experimentos/figuras/mosaico_gamma_gamma_0p5_1_2.png) (original y salidas con gamma 0.5, 1 y 2).

## Limitaciones

- La transformación pierde niveles cuando comprime un rango. Con el redondeo a uint8, contando sobre los 256 niveles de entrada:

  | gamma | Niveles de salida distintos | Niveles de entrada que terminan en 0 |
  |------:|----------------------------:|-------------------------------------:|
  | 0.1 | 78 | 1 |
  | 0.5 | 192 | 1 |
  | 2.2 | 184 | 15 |
  | 5 | 120 | 74 (del 0 al 73) |

  Con `gamma = 5` todo lo que está por debajo de 74 queda negro, y esa información ya no se recupera aplicando después la gamma inversa.
- Es global: aplica la misma curva a toda la imagen, aunque una parte esté oscura y otra clara.
- No elige $\gamma$ automáticamente; el valor lo decide el usuario con el deslizador.
