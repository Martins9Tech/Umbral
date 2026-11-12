# UMBRAL — Guía de estilo visual v0.1

> Elegida el 2026-11-07: **opción C, fantasía oscura pintada**.
> Referencia: [art/moodboard/moodboard_opcion_c.png](../art/moodboard/moodboard_opcion_c.png)

![Moodboard](../art/moodboard/moodboard_opcion_c.png)

---

## 1. La idea en una frase
Un mundo antiguo y en penumbra (piedra vieja, musgo, otoño, niebla) donde **la magia es lo único que brilla**. Los tonos de base son apagados y terrosos; los colores saturados quedan para la magia, las recompensas y el peligro.

## 2. Paleta (extraída del moodboard)

| Color | Hex | Uso |
|---|---|---|
| Musgo oscuro | `#3b341a` | Vegetación, suelo del Bosque |
| Óxido otoñal | `#803214` | Hojas, follaje, acentos cálidos del escenario |
| Piedra cálida | `#6a5848` | Rocas, ruinas, cuerpo de Orrun |
| Sombra | `#231815` | Fondos, huecos, sombras profundas |
| **Ámbar** | `#e3811f` | Runas y ojos de Orrun, luces cálidas, setas |
| **Esmeralda** | `#2e7b3b` | Gemas de experiencia, magia natural, ojos de la jefa |
| **Violeta** | `#682685` | Magia arcana, portales, lobos corruptos, aumentos |
| **Rojo peligro** | `#8c1416` | **Solo** ataques enemigos telegrafiados |

Para los brillos (materiales emisivos) se usan versiones más claras del mismo tono: ámbar `#ffae3d`, esmeralda `#3fd46a`, violeta `#a24dff` y rojo `#ff3b2f`.

## 3. Código de color de gameplay (no negociable)
La legibilidad manda (pilar 1 del GDD). Cada color brillante significa siempre lo mismo:

- 🔴 **Rojo:** peligro. Zonas de ataque, explosiones enemigas. Nada amistoso es rojo.
- 🟡 **Dorado:** recompensas. Cofres, oro, el Mercader.
- 🟢 **Esmeralda:** experiencia y vida (gemas, curación).
- 🟣 **Violeta:** magia y aumentos. Portales, el Altar, cartas de aumento.
- 🔵 **Azul-cian:** el jugador y sus habilidades. Marcador de apuntado, Técnica lista, efectos propios.
- 🟠 **Ámbar:** la firma de Orrun. Runas, Rasgo, onda sísmica.

> Cambio respecto al prototipo: las gemas de experiencia pasarán de azul a **esmeralda**, como en el moodboard. El azul queda reservado para el jugador.

## 4. Iluminación
- Ambiente **oscuro y frío** (azul-gris muy apagado) con **niebla baja** a ras de suelo.
- Una luz principal cálida y suave de atardecer otoñal, con sombras largas.
- Las fuentes de luz son la magia: setas ámbar, runas, gemas, portales. Iluminan su entorno con luces puntuales de poco alcance.
- Siempre debe verse bien al jugador: un contorno o luz propia que lo separe del fondo.

## 5. Materiales y texturas
- **Pintado a mano** en campeones, jefes y élites: texturas con pinceladas, desgaste, musgo en las juntas y bordes iluminados.
- **Atlas de color sencillo** en enemigos comunes y piezas de escenario (como decidimos en el roadmap), con la misma paleta para que todo case.
- Superficies mate (rugosidad alta). El brillo especular se reserva para metal (cofres, cadenas) y gemas.
- Los emisivos (runas, ojos, gemas) son pequeños y concentrados: nunca superficies enormes que brillen.

## 6. Formas y siluetas
- Proporciones **heroicas y exageradas**: manos y hombros grandes, cabezas pequeñas en los colosos.
- Cada enemigo debe reconocerse **solo por su silueta** vista desde arriba:
  - **Seta Andante:** sombrero ancho y redondo, puntos ámbar brillantes.
  - **Lobo Corrupto:** cuerpo alargado, bajo y anguloso, con ojos violeta.
  - **Tronco Hueco:** masa alta y vertical, con la boca hueca y setas violeta.
- La cámara está inclinada 55°, así que los detalles importantes tienen que leerse **desde arriba**: hombros, cabeza y lo que hay en el suelo.

## 7. Personajes clave
- **Orrun:** gólem de piedra vieja con musgo, **cadenas oxidadas** y runas hexagonales **ámbar** que brillan en pecho, brazos y piernas, con ojos ámbar. Imponente pero sereno.
- **La Madre Raíz:** árbol colosal con rostro de anciana en la corteza, ojos y vetas **esmeralda**, copa otoñal rojiza y raíces retorcidas.

## 8. Escenario: Bosque de los Susurros
- Claro otoñal con baldosas antiguas rotas, **pilares y arcos de piedra en ruinas**, árboles retorcidos de hoja roja y setas luminosas.
- Niebla espesa en los bordes, que tapa lo que está fuera del área de combate.
- **Suelo despejado** en el centro, porque es donde se lucha. El detalle va en los bordes.

## 9. Efectos visuales
- Brillo con halo suave; nada de efectos que tapen la horda o los avisos del suelo.
- Los avisos de ataque enemigo (círculo rojo con runas) se dibujan siempre **por encima** de todo lo demás.
- Los efectos propios deben poder hacerse más transparentes desde las opciones.

## 10. Interfaz
- Paneles **oscuros** (`#231815` con transparencia) con bordes finos.
- Texto claro; dorado para lo valioso; los colores de la sección 3 para su significado.
- Iconos con la misma pintura apagada y un acento brillante.

---

## 11. Arte 2D: flujo de producción

Desde el 2026-11-12 el juego es 2D. Todo el arte se genera con una IA de imágenes (ChatGPT) a partir de un prompt y de las referencias (`art/referencias/`, `art/moodboard/`), y después se procesa con scripts:

1. **Generar** con fondo transparente, mirando a la DERECHA, vista 3/4 un poco desde arriba, contorno oscuro fino y estilo pintado a mano. Los originales van a `art/2d/`.
2. **Recortar:** `python tools/sprites/cortar_hoja.py HOJA.png SALIDA/ --nombres a b c --escala 0.5` quita el halo semitransparente, separa cada pieza y la nombra en orden de lectura.
3. **Campeones:** se dibujan ENTEROS y se despiezan con `python tools/sprites/despiezar.py art/2d/<campeón>_despiece.json` (polígonos y pivotes en % de la imagen; el torso se rellena donde lo tapaban brazos y piernas; genera `rig.json` y una imagen de comprobación). Así la marioneta conserva las proporciones del dibujo. Las animaciones se hacen por código (`entities/champions/orrun/marioneta_orrun.gd`) y se revisan con `res://debug/vista_animaciones.tscn`. Una hoja de piezas sueltas generada aparte no sirve: la IA no respeta las proporciones.
4. **Enemigos:** un dibujo cada uno en `game/assets/sprites/enemigos/<id>.png`; en su `.tres` se indica `sprite_height` (metros) y `anim` (`salto`, `galope` o `balanceo`).
5. **Importación:** activar mipmaps en el `.import` de cada sprite (se ven reducidos).
6. **Iconos** (armas, reliquias, aumentos y habilidades): se generan con la API de imágenes de Azure (`tools/ia/generar_imagen.py`; la clave va en la variable de entorno `AZURE_OPENAI_API_KEY` y el endpoint en `tools/ia/config.local.json`, ignorado por git). El lote está en `art/iconos/lote_iconos.py`: cuadrados, fondo oscuro pintado con resplandor del color del elemento (hielo cian, fuego naranja, rayo amarillo, sombra violeta, físico ámbar; reliquias turquesa y oro; aumentos según rareza; el kit en ámbar). `python tools/sprites/preparar_iconos.py` los copia al juego a 256 px con el id como nombre, y `UiStyle.icon(id)` los usa en cartas, HUD y pausa. Para un contenido nuevo: añadirlo al lote, generar (solo crea los que faltan) y preparar. El recurso de Azure limita las peticiones por minuto: usar `--paralelo 1` o 2.
7. **Decorado, objetos y jefa** (`art/2d/lote_decorado.py`, fondo transparente): pilares, árboles, setas, rocas, urna, cofre, mercader, altar, contrato y la Madre Raíz. `python tools/sprites/preparar_decorado.py` limpia el halo, recorta y los copia a `game/assets/sprites/decorado/`. El juego los dibuja apoyados por la base (`Draw2D.sprite`) con su sombra.
8. **Marcos de interfaz** (`art/ui/lote_ui.py`): panel, placa de título y botón de piedra y bronce. `python tools/sprites/preparar_ui.py` los recorta a `game/assets/ui/marcos/`. `UiTheme` (tema global) los usa en 9 partes para todos los paneles y botones; `UiTheme.titled()` pone la placa detrás de un título.
9. **Fuentes** (`game/assets/fonts/`, licencia SIL OFL incluida junto a cada una; se pueden usar en un juego comercial): **Cinzel** en negrita para títulos (textos de 34 px o más y títulos de carta) y **Alegreya Sans** para el resto (los botones en su versión Bold). Las aplica `UiTheme`; `UiStyle.label` elige sola según el tamaño.

Tamaños en pantalla (1 m = 56 px a 1080p): Orrun 2,7 m; Seta 1,25 m; Lobo 1,25 m; Tronco 2,7 m.

## Referencias de modelado
1. ✅ **Hoja de vistas de Orrun:** [art/referencias/orrun_vistas.png](../art/referencias/orrun_vistas.png), con las vistas recortadas por separado (`orrun_frente`, `orrun_lado`, `orrun_espalda`, `orrun_tres_cuartos`) para la IA de 3D.
2. Hojas de vistas de los 3 enemigos del Bosque (siguiente).
3. Moodboards de los otros reinos en este mismo estilo, cuando lleguemos a ellos.

## Aplicado al prototipo (2026-11-07)
- Suelo procedural del Bosque (`shaders/ground_forest.gdshader`): tierra oscura, musgo, hojas y baldosas.
- Ambiente frío con luz cálida de atardecer, niebla ligera y halo solo en lo emisivo.
- Árboles otoñales fuera de las ruinas, pilares de piedra con musgo y setas ámbar luminosas.
- Orrun en piedra cálida con runa ámbar, luz propia y **anillo cian a los pies**; enemigos y gemas con la paleta.
