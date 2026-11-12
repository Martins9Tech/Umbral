"""Prepara los marcos de interfaz (art/ui/*.png) para usarlos en 9 partes:
recorta al contenido (alfa >= 128) y los reduce a game/assets/ui/marcos/.

    python tools/sprites/preparar_ui.py
"""

import os

import numpy as np
from PIL import Image

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ORIGEN = os.path.join(RAIZ, "art", "ui")
DESTINO = os.path.join(RAIZ, "game", "assets", "ui", "marcos")
# nombre: escala final
MARCOS = {"marco_panel": 0.5, "placa_titulo": 0.4, "boton": 0.25}


def main():
    os.makedirs(DESTINO, exist_ok=True)
    for nombre, escala in MARCOS.items():
        imagen = Image.open(os.path.join(ORIGEN, nombre + ".png")).convert("RGBA")
        alfa = np.array(imagen)[..., 3]
        filas = np.nonzero((alfa >= 128).any(axis=1))[0]
        columnas = np.nonzero((alfa >= 128).any(axis=0))[0]
        imagen = imagen.crop((columnas[0], filas[0], columnas[-1] + 1, filas[-1] + 1))
        imagen = imagen.resize((round(imagen.width * escala), round(imagen.height * escala)), Image.LANCZOS)
        imagen.save(os.path.join(DESTINO, nombre + ".png"))
        print(f"{nombre}: {imagen.width}x{imagen.height}")


main()
