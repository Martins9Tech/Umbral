"""Prepara sprites sueltos generados con fondo transparente (art/2d/decorado/*.png):
limpia el halo semitransparente, recorta al contenido y los copia al juego a
media resolución (game/assets/sprites/decorado/).

    python tools/sprites/preparar_decorado.py
"""

import glob
import os

import numpy as np
from PIL import Image

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ORIGEN = os.path.join(RAIZ, "art", "2d", "decorado")
DESTINO = os.path.join(RAIZ, "game", "assets", "sprites", "decorado")
UMBRAL = 40
ESCALA = 0.5


def main():
    os.makedirs(DESTINO, exist_ok=True)
    for ruta in sorted(glob.glob(os.path.join(ORIGEN, "*.png"))):
        datos = np.array(Image.open(ruta).convert("RGBA"))
        datos[..., 3] = np.where(datos[..., 3] >= UMBRAL, datos[..., 3], 0)
        imagen = Image.fromarray(datos)
        caja = imagen.getbbox()
        if caja is None:
            print("vacía:", ruta)
            continue
        imagen = imagen.crop(caja)
        imagen = imagen.resize((max(1, round(imagen.width * ESCALA)), max(1, round(imagen.height * ESCALA))), Image.LANCZOS)
        imagen.save(os.path.join(DESTINO, os.path.basename(ruta)))
        print(f"{os.path.basename(ruta)}: {imagen.width}x{imagen.height}")


main()
