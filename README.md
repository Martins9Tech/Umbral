# UMBRAL *(título provisional)*

Roguelike de supervivencia contra hordas en 2D con vista cenital ligeramente inclinada (estilo survivors), con campeones de kit propio, armas automáticas, aumentos, reinos conectados por portales y jefes con fases. Motor: **Godot 4.7** · Arte: **2D ilustrado** (generado con IA de imágenes, recortado y animado por código).

**Estado:** Fase 1, prototipo greybox jugable (figuras básicas, sin arte). **Plataforma:** PC (Steam).

## Menú y progresión
Al arrancar aparece el **menú principal**:
- **Jugar:** eliges campeón (Orrun; Sela llegará más adelante).
- **Armería:** mejoras permanentes que compras con **Esencia**, que se gana al terminar cada partida.
- **Logros:** dan Esencia y desbloquean armas (Minas de Brea, Orbe de Tormenta, Guadaña Umbría).
- **Ajustes:** volumen, pantalla completa, VSync, temblor de cámara e intensidad de los efectos.

El progreso se guarda solo (`%APPDATA%\Godot\app_userdata\Umbral\save.json`). Desde la pausa puedes abrir los ajustes o salir al menú. **F12 en el menú** desbloquea todo y da 5.000 de Esencia (truco de pruebas).

## Controles del prototipo
| Acción | Teclado y ratón | Mando |
|--------|----------------|-------|
| Moverse | WASD / flechas | Stick izquierdo |
| Apuntar | Ratón | Stick derecho (o dirección de movimiento) |
| Técnica (Zancada de Falla) | Clic derecho / Q (mantener para relanzar) | RB |
| Definitiva (Despertar del Monte) | R, con el Ímpetu al 100 | RT |
| Paso (esquiva) | Espacio / Shift | A |
| Elegir mejora | 1 / 2 / 3 o clic | Cruceta + A |
| Pausa y detalle de la build | Esc | Start |

Depuración: **F1** overlay de rendimiento (oculto al empezar) · **F2** +500 enemigos · **F3** modo dios · **F4** +1 nivel · **F5** +1 minuto · **F6** matar a todos · **F7** velocidad ×2 · **F8** invocar una élite · **F9** saltar al jefe · **F10** elegir un aumento ya.

**La partida:** un mapa de 10 minutos con fases (barra bajo el reloj): élites, el **Heraldo** en el minuto 6, una estampida en el 9 y **La Madre Raíz** en el 10. Sus ataques se avisan con zonas rojas en el suelo que se rellenan: sal de ellas o usa el Paso. Si la derrotas, ganas.

**Sinergias:** cada arma tiene un elemento (Físico, Fuego, Hielo, Rayo o Sombra). Con 2 o 3 armas del mismo elemento se activan bonus: quemaduras que explotan, congelar, rayos que aturden, ejecutar… Se ven en la fila «Sinergias» del HUD y en el menú de pausa.

**Oro y eventos:** algunos enemigos, las élites y los cofres sueltan oro. Por el mapa hay urnas que tus armas rompen (comida, oro, imán o bomba). En el minuto 3 aparece un **Altar de Sangre** (vida máxima a cambio de un aumento Arcano), en el 5:30 el **Mercader** (tienda) y en el 7:30 una **Piedra de Contrato** (mata 250 en 30 s para ganar un cofre y oro). Acércate a ellos para interactuar.

**Registro:** cada partida se guarda al terminar. `python tools/telemetry_report.py` muestra un resumen de todas (victorias, causas de muerte, daño por arma, elecciones…).

**Aumentos:** en los minutos 4 y 8 eliges 1 de 3 mejoras grandes (Eco, Arcano o Mítico) con un recambio gratis (T). Algunos cambian las reglas, como Coloso, Ímpetu Eterno o Todo o Nada.

Élites y cofres: cada 70 s aparece una élite (grande y dorada) que suelta un cofre con un haz de luz. Si un arma está al nivel 8 y tienes su reliquia, el cofre la **evoluciona**. Las recetas están en el menú de pausa y en el [GDD §5.4](docs/GDD.md#54-evoluciones).

Consejo: quedarse quieto con Orrun acumula Piedra (menos daño recibido) y al moverse la suelta como onda sísmica.

## Cómo abrir el proyecto
1. Instala [Git LFS](https://git-lfs.com) y ejecuta `git lfs install` una vez por equipo (los modelos, texturas y audios van por LFS).
2. Abre Godot 4.7 → **Importar** → selecciona `game/project.godot`.

## Estructura
- `game/`: proyecto de Godot (código, escenas, contenido `.tres` y assets importados).
- `art/`: fuentes de arte (`.blend`, `.kra`…), fuera del proyecto de Godot.
- `tools/`: scripts auxiliares: `ia/` genera imágenes con la API de Azure, `sprites/` recorta y prepara el arte 2D, y el informe de telemetría.
- `docs/`: documentación de diseño y técnica.

## Documentación
- [docs/GDD.md](docs/GDD.md): diseño del juego (campeones, progresión, aumentos, reinos, portales, jefes, enemigos).
- [docs/TECNICO.md](docs/TECNICO.md): arquitectura en Godot, rendimiento de hordas y pipeline de arte 2D.
- [docs/ROADMAP.md](docs/ROADMAP.md): fases de desarrollo, decisiones abiertas y riesgos.
- [docs/GUIA_ESTILO.md](docs/GUIA_ESTILO.md): estilo visual (fantasía oscura pintada), paleta y código de color.
