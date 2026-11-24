
"""
PDI VisionLab
Sistema interactivo de procesamiento digital
de imágenes y video en tiempo real.

Archivo principal de ejecución.
"""

from configuracion import (
    NOMBRE_PROYECTO,
    VERSION,
    RESOLUCION_ANCHO,
    RESOLUCION_ALTO,
    FPS_OBJETIVO,
    TITULO_VENTANA
)


def mostrar_informacion():
    """Muestra la información inicial del proyecto."""

    print("=" * 50)
    print(f"  {NOMBRE_PROYECTO}")
    print(f"  Versión: {VERSION}")
    print("=" * 50)

    print("\nCONFIGURACIÓN DEL SISTEMA")
    print("-" * 50)

    print(f"Nombre de la aplicación: {TITULO_VENTANA}")

    print(
        f"Resolución de referencia: "
        f"{RESOLUCION_ANCHO} x {RESOLUCION_ALTO}"
    )

    print(f"FPS objetivo: {FPS_OBJETIVO}")

    print("\nESTADO DEL PROYECTO")
    print("-" * 50)

    print("Configuración cargada correctamente.")
    print("Módulo de cámara: pendiente de implementación.")
    print("Módulos de algoritmos: pendientes de implementación.")
    print("Interfaz gráfica: pendiente de implementación.")

    print("\nPDI VisionLab inicializado correctamente.")
    print("=" * 50)


def iniciar_aplicacion():
    """Función principal de ejecución."""

    mostrar_informacion()


if __name__ == "__main__":
    iniciar_aplicacion()
