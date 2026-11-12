"""Lote de marcos de interfaz (paneles, placa de título y botón) para usarlos
como texturas de 9 partes (StyleBoxTexture / NinePatchRect).

    python art/ui/lote_ui.py
    python tools/ia/generar_imagen.py --lote art/ui/lote_ui.json --paralelo 1 --quality medium
"""

import json
import os

AQUI = os.path.dirname(os.path.abspath(__file__))

ESTILO = (
    "Game UI element for a dark fantasy action roguelike, hand-painted premium style, perfectly symmetrical, "
    "straight-on front view, flat and centered. {subject} The center area must be completely empty and flat "
    "(no ornaments, no text), so it can be stretched. Palette: carved dark stone, aged bronze, small glowing amber "
    "rune gems. No text, no letters."
)

UI = {
    "marco_panel": ("1024x1024", False, "A square menu panel: a thin ornate frame of carved dark stone with an aged bronze "
                    "inner rim and a small amber rune gem in each corner; the frame is about 7 percent of the width; "
                    "the center is a flat, solid very dark warm brown."),
    "placa_titulo": ("1536x1024", True, "A wide horizontal title plaque: a dark stone and bronze banner with pointed "
                     "ends decorated with amber rune gems, flat dark center, transparent background outside the plaque."),
    "boton": ("1536x1024", True, "A wide rounded rectangular button plate: dark stone with a thin aged bronze rim and "
              "tiny amber gems on the left and right ends, flat dark center, transparent background outside the button."),
}


def main():
    lote = [{"prompt": ESTILO.format(subject=sujeto), "size": tam, "transparent": transparente,
             "out": "art/ui/%s.png" % nombre} for nombre, (tam, transparente, sujeto) in UI.items()]
    json.dump(lote, open(os.path.join(AQUI, "lote_ui.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print(len(lote), "imágenes")


main()
