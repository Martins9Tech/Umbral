"""Copia los iconos generados (art/iconos/<grupo>/<id>.png) al juego a 256 px
(game/assets/ui/iconos/<id>.png). El juego busca cada icono por el id del
arma, reliquia, aumento o habilidad (UiStyle.icon).

    python tools/sprites/preparar_iconos.py
"""

import glob
import os

from PIL import Image

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ORIGEN = os.path.join(RAIZ, "art", "iconos")
DESTINO = os.path.join(RAIZ, "game", "assets", "ui", "iconos")
TAM = 256


def main():
    os.makedirs(DESTINO, exist_ok=True)
    total = 0
    for ruta in sorted(glob.glob(os.path.join(ORIGEN, "*", "*.png"))):
        nombre = os.path.basename(ruta)
        imagen = Image.open(ruta).convert("RGBA").resize((TAM, TAM), Image.LANCZOS)
        imagen.save(os.path.join(DESTINO, nombre))
        total += 1
    print(f"{total} iconos en {DESTINO}")


main()
