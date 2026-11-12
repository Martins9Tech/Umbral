"""Lote de arte 2D del Bosque: decorado, objetos de eventos y la jefa.
Escribe lote_decorado.json para tools/ia/generar_imagen.py (fondo transparente).

    python art/2d/lote_decorado.py
    python tools/ia/generar_imagen.py --lote art/2d/lote_decorado.json --paralelo 2 --quality medium --transparent
"""

import json
import os

AQUI = os.path.dirname(os.path.abspath(__file__))

ESTILO = (
    "2D game asset for a dark fantasy top-down action roguelike. Hand-painted stylized game art that matches a "
    "mossy stone golem hero: bold readable shapes, thin dark outline around the whole silhouette, soft light from "
    "the top left, warm autumn forest palette (warm grey-brown stone, moss green, rust, amber glow), painterly "
    "texture. Three-quarter view seen slightly from above. Subject: {subject}. A single isolated object, centered, "
    "fully visible with a small margin. Transparent background, no ground, no cast shadow, no text, no frame."
)

DECORADO = {
    "pilar_1": ("1024x1536", "a ruined ancient stone pillar with a broken top covered in moss, cracked carved stone blocks and a faint amber rune"),
    "pilar_2": ("1024x1024", "a short broken stone column stump with a few fallen blocks and ivy"),
    "arbol_1": ("1024x1536", "an autumn forest tree with a thick twisted trunk and a large rounded canopy of red-orange leaves"),
    "arbol_2": ("1024x1536", "a dark gnarled autumn oak with a dense crown of rust and amber leaves and visible roots"),
    "arbol_3": ("1024x1536", "a dead twisted tree with only a few orange leaves and long hanging moss"),
    "setas": ("1024x1024", "a cluster of glowing amber mushrooms of different sizes on a small mossy patch, emitting warm light"),
    "rocas": ("1024x1024", "a small pile of mossy grey-brown rocks with a few fallen autumn leaves"),
    "urna": ("1024x1024", "an old cracked clay urn with a simple painted band, a breakable pot"),
    "cofre": ("1024x1024", "an ornate closed golden treasure chest with iron bands and a glowing amber gem on the lock"),
    "mercader": ("1536x1024", "a small traveling merchant wagon with a striped canvas roof, crates, sacks and two warm lanterns, no people"),
    "altar": ("1024x1024", "a dark blood altar: a carved stone pedestal with red runes and a floating glowing red crystal orb above it"),
    "contrato": ("1024x1536", "a tall stone slab engraved with glowing cyan runes and a floating cyan orb above it"),
    "madre_raiz": ("1024x1536", "La Madre Raiz, a colossal corrupted ancient tree mother boss monster: a huge twisted living tree with a "
                   "hollow bark face and glowing green eyes, massive root legs, long branch arms ending in claws, glowing green "
                   "sap veins and purple corrupted mushrooms growing on her bark, menacing and majestic, facing right"),
}


def main():
    lote = [{"prompt": ESTILO.format(subject=sujeto), "size": tam, "transparent": True,
             "out": "art/2d/decorado/%s.png" % nombre} for nombre, (tam, sujeto) in DECORADO.items()]
    json.dump(lote, open(os.path.join(AQUI, "lote_decorado.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print(len(lote), "imágenes")


main()
