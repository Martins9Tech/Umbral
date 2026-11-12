"""Recorta las piezas de una hoja de sprites con fondo transparente (GUIA_ESTILO, arte 2D).

- Quita el halo semitransparente que dejan las IAs de imagen (alfa por debajo del umbral).
- Detecta cada pieza como una mancha separada y la recorta con un pequeño margen.
- Las nombra en orden de lectura (filas de arriba abajo, de izquierda a derecha).
- Opcionalmente reduce las piezas a una escala común.

Uso:
    python tools/sprites/cortar_hoja.py HOJA.png SALIDA/ --nombres cabeza torso ... [--escala 0.5]
Si hay más piezas que nombres, las sobrantes se llaman pieza_N. Escribe también
SALIDA/piezas.json con el tamaño y la posición de cada pieza en la hoja.
"""

import argparse
import json
import os
from collections import deque

import numpy as np
from PIL import Image

REDUCCION = 4  # la detección se hace a 1/4 de resolución (une huecos pequeños)


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("hoja")
    p.add_argument("salida")
    p.add_argument("--nombres", nargs="*", default=[])
    p.add_argument("--umbral", type=int, default=64, help="alfa mínimo que cuenta como pieza")
    p.add_argument("--margen", type=int, default=6)
    p.add_argument("--area-min", type=int, default=400, help="área mínima (en píxeles reducidos)")
    p.add_argument("--escala", type=float, default=1.0)
    return p.parse_args()


def etiquetar(mascara):
    """Componentes conexas (8 vecinos) sin depender de scipy."""
    alto, ancho = mascara.shape
    etiquetas = np.zeros((alto, ancho), dtype=np.int32)
    actual = 0
    for y in range(alto):
        for x in range(ancho):
            if not mascara[y, x] or etiquetas[y, x]:
                continue
            actual += 1
            cola = deque([(y, x)])
            etiquetas[y, x] = actual
            while cola:
                cy, cx = cola.popleft()
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < alto and 0 <= nx < ancho and mascara[ny, nx] and not etiquetas[ny, nx]:
                            etiquetas[ny, nx] = actual
                            cola.append((ny, nx))
    return etiquetas, actual


def orden_de_lectura(cajas):
    """Agrupa en filas por la altura del centro y ordena cada fila de izquierda a derecha."""
    if not cajas:
        return []
    alto_medio = sum(c["y1"] - c["y0"] for c in cajas) / len(cajas)
    por_y = sorted(cajas, key=lambda c: (c["y0"] + c["y1"]) / 2)
    filas, fila = [], [por_y[0]]
    for caja in por_y[1:]:
        centro = (caja["y0"] + caja["y1"]) / 2
        centro_fila = (fila[0]["y0"] + fila[0]["y1"]) / 2
        if centro - centro_fila > alto_medio * 0.5:
            filas.append(fila)
            fila = [caja]
        else:
            fila.append(caja)
    filas.append(fila)
    return [c for f in filas for c in sorted(f, key=lambda c: c["x0"])]


def main():
    args = parse_args()
    imagen = np.array(Image.open(args.hoja).convert("RGBA"))
    alfa = imagen[..., 3]
    alfa_limpio = np.where(alfa >= args.umbral, alfa, 0).astype(np.uint8)

    # Máscara reducida (máximo de cada bloque): une trocitos sueltos de la misma pieza.
    h, w = alfa.shape
    hr, wr = h // REDUCCION, w // REDUCCION
    bloques = alfa_limpio[: hr * REDUCCION, : wr * REDUCCION].reshape(hr, REDUCCION, wr, REDUCCION)
    mascara = bloques.max(axis=(1, 3)) > 0
    etiquetas, total = etiquetar(mascara)

    cajas = []
    for n in range(1, total + 1):
        ys, xs = np.nonzero(etiquetas == n)
        if len(ys) < args.area_min:
            continue
        cajas.append({
            "etiqueta": n,
            "x0": int(xs.min()) * REDUCCION, "x1": int(xs.max() + 1) * REDUCCION,
            "y0": int(ys.min()) * REDUCCION, "y1": int(ys.max() + 1) * REDUCCION,
        })
    cajas = orden_de_lectura(cajas)

    os.makedirs(args.salida, exist_ok=True)
    etiquetas_full = np.kron(etiquetas, np.ones((REDUCCION, REDUCCION), dtype=np.int32))
    etiquetas_full = np.pad(etiquetas_full, ((0, h - etiquetas_full.shape[0]), (0, w - etiquetas_full.shape[1])))
    resumen = {}
    for i, caja in enumerate(cajas):
        nombre = args.nombres[i] if i < len(args.nombres) else f"pieza_{i + 1}"
        m = args.margen
        x0, y0 = max(0, caja["x0"] - m), max(0, caja["y0"] - m)
        x1, y1 = min(w, caja["x1"] + m), min(h, caja["y1"] + m)
        recorte = imagen[y0:y1, x0:x1].copy()
        # Solo los píxeles de esta pieza (nada de piezas vecinas dentro de la caja).
        propia = etiquetas_full[y0:y1, x0:x1]
        recorte[..., 3] = np.where((propia == caja["etiqueta"]) | (propia == 0), alfa_limpio[y0:y1, x0:x1], 0)
        pieza = Image.fromarray(recorte)
        if args.escala != 1.0:
            pieza = pieza.resize((max(1, round(pieza.width * args.escala)), max(1, round(pieza.height * args.escala))), Image.LANCZOS)
        pieza.save(os.path.join(args.salida, f"{nombre}.png"))
        resumen[nombre] = {"hoja": [x0, y0, x1, y1], "tam": [pieza.width, pieza.height]}
        print(f"{nombre}: {pieza.width}x{pieza.height} (en la hoja {x0},{y0} - {x1},{y1})")
    with open(os.path.join(args.salida, "piezas.json"), "w", encoding="utf-8") as f:
        json.dump(resumen, f, indent=2, ensure_ascii=False)


main()
