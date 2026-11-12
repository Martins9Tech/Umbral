"""Despieza un dibujo entero en piezas de marioneta (GUIA_ESTILO §11).

Lee una definición JSON (polígonos y pivotes en % de la imagen), recorta cada
pieza del dibujo original y deja el resto como torso. Donde un brazo o una
pierna tapaba el cuerpo, rellena el torso con su propia textura (para que al
mover la pieza no quede un agujero). Escribe las piezas, `rig.json` (pivotes,
enganches y orden de dibujo, en píxeles) y `debug.png` con cada pieza coloreada.

Uso:
    python tools/sprites/despiezar.py art/2d/orrun_despiece.json
"""

import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

UMBRAL_ALFA = 64
COLORES = [(255, 80, 80), (80, 200, 255), (255, 210, 60), (120, 255, 120), (230, 120, 255),
           (255, 150, 40), (60, 120, 255), (200, 255, 200), (255, 255, 255)]


def a_px(punto, ancho, alto):
    return (punto[0] / 100.0 * ancho, punto[1] / 100.0 * alto)


def mascara_poligono(poligono, ancho, alto):
    lienzo = Image.new("L", (ancho, alto), 0)
    ImageDraw.Draw(lienzo).polygon([a_px(p, ancho, alto) for p in poligono], fill=255)
    return np.array(lienzo) > 0


def rellenar(rgba, huecos, iteraciones=120):
    """Rellena los huecos con la media de los vecinos conocidos, capa a capa."""
    conocido = (rgba[..., 3] > 0) & ~huecos
    color = rgba[..., :3].astype(np.float32)
    pendiente = huecos.copy()
    for _ in range(iteraciones):
        if not pendiente.any():
            break
        suma = np.zeros_like(color)
        cuenta = np.zeros(conocido.shape, np.float32)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dx == 0 and dy == 0:
                    continue
                vecino = np.roll(np.roll(conocido, dy, 0), dx, 1)
                suma += np.roll(np.roll(color, dy, 0), dx, 1) * vecino[..., None]
                cuenta += vecino
        nuevos = pendiente & (cuenta > 0)
        color[nuevos] = suma[nuevos] / cuenta[nuevos][:, None]
        conocido |= nuevos
        pendiente &= ~nuevos
    salida = rgba.copy()
    rellenos = huecos & conocido
    # Un poco más oscuro: es la parte del cuerpo que queda en sombra.
    salida[rellenos, :3] = np.clip(color[rellenos] * 0.78, 0, 255).astype(np.uint8)
    salida[rellenos, 3] = 255
    return salida


def main():
    ruta_def = sys.argv[1]
    base = os.path.dirname(os.path.abspath(ruta_def))
    raiz = os.path.abspath(os.path.join(base, "..", ".."))
    definicion = json.load(open(ruta_def, encoding="utf-8"))
    imagen = np.array(Image.open(os.path.join(base, definicion["imagen"])).convert("RGBA"))
    alto, ancho = imagen.shape[:2]
    imagen[..., 3] = np.where(imagen[..., 3] >= UMBRAL_ALFA, imagen[..., 3], 0)
    escala = float(definicion.get("escala", 1.0))
    salida = os.path.join(raiz, definicion["salida"])
    os.makedirs(salida, exist_ok=True)

    piezas = definicion["piezas"]
    asignado = np.zeros((alto, ancho), bool)
    capas = {}
    for nombre, pieza in piezas.items():
        mascara = mascara_poligono(pieza["poligono"], ancho, alto) & ~asignado
        asignado |= mascara
        capa = imagen.copy()
        capa[~mascara, 3] = 0
        capas[nombre] = capa
    torso = imagen.copy()
    torso[asignado, 3] = 0
    hueco = mascara_poligono(definicion["hueco_torso"], ancho, alto) & asignado & (torso[..., 3] == 0)
    capas["torso"] = rellenar(torso, hueco)

    pivotes = {"torso": a_px(definicion["torso"]["pivote"], ancho, alto)}
    padres = {"torso": ""}
    lejanas = {"torso": False}
    for nombre, pieza in piezas.items():
        pivotes[nombre] = a_px(pieza["pivote"], ancho, alto)
        padres[nombre] = pieza["padre"]
        lejanas[nombre] = bool(pieza.get("lejana", False))
    pies = a_px(definicion["pies"], ancho, alto)

    rig = {"escala_fuente": escala, "orden": definicion["orden"], "piezas": {}}
    for nombre, capa in capas.items():
        caja = Image.fromarray(capa).getbbox()
        x0, y0, x1, y1 = caja
        recorte = Image.fromarray(capa).crop(caja)
        if escala != 1.0:
            recorte = recorte.resize((max(1, round(recorte.width * escala)), max(1, round(recorte.height * escala))), Image.LANCZOS)
        recorte.save(os.path.join(salida, f"{nombre}.png"))
        px, py = pivotes[nombre]
        padre = padres[nombre]
        origen = pies if padre == "" else pivotes[padre]
        rig["piezas"][nombre] = {
            "padre": padre,
            "lejana": lejanas[nombre],
            # Pivote dentro de su textura y posición del pivote respecto al del padre
            # (o a los pies, para el torso), ya escalados.
            "pivote": [(px - x0) * escala, (py - y0) * escala],
            "enganche": [(px - origen[0]) * escala, (py - origen[1]) * escala],
        }
        print(f"{nombre}: {recorte.width}x{recorte.height}")
    rig["altura"] = (pies[1] - min(np.nonzero(imagen[..., 3])[0])) * escala
    json.dump(rig, open(os.path.join(salida, "rig.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)

    # Comprobación visual: cada pieza teñida de un color y los pivotes marcados.
    fondo = Image.new("RGBA", (ancho, alto), (40, 50, 60, 255))
    fondo.alpha_composite(Image.fromarray(imagen))
    tinte = np.zeros((alto, ancho, 4), np.uint8)
    for k, nombre in enumerate(piezas):
        mascara = capas[nombre][..., 3] > 0
        tinte[mascara] = (*COLORES[k % len(COLORES)], 110)
    tinte[hueco] = (255, 0, 255, 160)
    fondo.alpha_composite(Image.fromarray(tinte))
    dibujo = ImageDraw.Draw(fondo)
    for nombre, (px, py) in pivotes.items():
        dibujo.ellipse((px - 7, py - 7, px + 7, py + 7), outline=(255, 255, 0, 255), width=3)
    dibujo.ellipse((pies[0] - 9, pies[1] - 9, pies[0] + 9, pies[1] + 9), outline=(0, 255, 255, 255), width=3)
    fondo.save(os.path.join(base, "orrun_despiece_debug.png"))


main()
