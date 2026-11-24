
# PDI VisionLab

Sistema interactivo de procesamiento digital de
imágenes y video en tiempo real.

## 1. Descripción

PDI VisionLab es un proyecto académico desarrollado
para la asignatura de Procesamiento Digital de Imágenes.

Su propósito es implementar diferentes algoritmos
de procesamiento digital y aplicarlos sobre video
adquirido mediante una cámara en tiempo real.

## 2. Integrantes

- Jonathan
- Jesús
- Arely

## 3. Tecnologías

- Python 3.12.5
- NumPy
- OpenCV
- Matplotlib
- PyQt6
- Psutil
- GitHub

## 4. Hardware disponible

- PC AMD Ryzen 5 5600G con 32 GB de RAM.
- Raspberry Pi 4 con 8 GB de RAM.
- Cámara Logitech C920 HD Pro.
- Laptop auxiliar para pruebas.

## 5. Estructura del proyecto

- `visionlab/camara/`: adquisición de video.
- `visionlab/nucleo/`: flujo de procesamiento.
- `visionlab/algoritmos/`: implementaciones de PDI.
- `visionlab/interfaz/`: interfaz gráfica.
- `visionlab/rendimiento/`: medición de rendimiento.
- `pruebas/`: pruebas del software.
- `documentacion/`: documentación técnica.
- `recursos/`: imágenes y recursos gráficos.
- `resultados/`: resultados experimentales.

## 6. Requisitos de instalación

- Python 3.12.5 recomendado.
- Visual Studio Code.
- GitHub Desktop.
- Git.

## 7. Instalación

Clonar el repositorio:

```bash
git clone DIRECCION_DEL_REPOSITORIO
```

Entrar en la carpeta:

```bash
cd PDI_VisionLab
```

Crear el entorno virtual:

```bash
python -m venv .venv
```

Activar el entorno en Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
```

Actualizar pip:

```bash
python -m pip install --upgrade pip
```

Instalar las dependencias:

```bash
python -m pip install -r requirements.txt
```

## 8. Ejecución

Ejecutar el programa principal:

```bash
python principal.py
```

## 9. Metodología de colaboración

El equipo utilizará un único repositorio de GitHub
y trabajará exclusivamente sobre la rama `main`.

Flujo de trabajo:

1. Fetch origin.
2. Pull origin.
3. Realizar las modificaciones asignadas.
4. Crear un commit descriptivo.
5. Publicar los cambios mediante Push origin.

## 10. Reglas de desarrollo

- Respetar la distribución de módulos.
- Evitar modificar archivos asignados a otros integrantes.
- No subir la carpeta `.venv`.
- Documentar las funciones implementadas.
- Probar individualmente cada algoritmo.
- Coordinar los cambios antes de subirlos.
- No utilizar Force Push.

## 11. Objetivo de rendimiento

La referencia académica es alcanzar al menos
20 FPS a una resolución de 640 x 480.

El rendimiento real será medido y documentado
en las diferentes plataformas de hardware.

## 12. Estado del proyecto

Proyecto en fase inicial de arquitectura y
preparación de los módulos de software.
