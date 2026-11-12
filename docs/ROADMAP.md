# UMBRAL — Roadmap, decisiones y riesgos v0.1

> Principio rector: **encontrar la diversión antes que el contenido.** Cada fase tiene un *criterio de salida*: no se pasa a la siguiente hasta cumplirlo.

---

## Fases de desarrollo

### Fase 0 · Preproducción
- ✅ Cerrar las [decisiones](#decisiones) de base (2026-11-07).
- ✅ Moodboard (opción C, fantasía oscura pintada) y [guía de estilo](GUIA_ESTILO.md) (2026-11-07).
- ✅ Repositorio Git + LFS, `.gitignore` de Godot y proyecto Godot 4.7 vacío en `game/` con la estructura de carpetas ([TECNICO §4.8](TECNICO.md#48-estructura-de-carpetas-propuesta)) (2026-11-07).

**Criterio de salida:** moodboard listo y proyecto Godot creado con la estructura de carpetas.

### Fase 1 · Prototipo greybox — *¿es divertido? ¿aguanta el rendimiento?*
Todo con cápsulas, cubos o placeholders de KayKit/Quaternius.
- Cámara 2.5D + movimiento WASD y mando.
- 1 campeón (Orrun o Sela) con el kit completo: Rasgo, arma de firma, Técnica, Definitiva y Paso.
- 3-4 armas automáticas, 4 reliquias y subida de nivel con 1 de 3 opciones.
- `EnemySwarm` orientado a datos con MultiMesh, 2-3 tipos de enemigo y un Director sencillo.
- Gemas de XP, imán, vida, muerte, reinicio y pantalla de resumen.
- Escena de stress test y consola de trucos básica.

**Estado (2026-11-07):** primera versión jugable en `game/` con todo lo anterior: Orrun con su kit completo, 4 armas (la de firma + 3), 6 reliquias, 3 enemigos del Bosque, director, gemas, subida de nivel, resumen al morir, overlay de depuración (F1), trucos (F2-F7) y prueba de rendimiento automática. Mediciones en [TECNICO §3.1](TECNICO.md#31-mediciones-del-prototipo).

**Criterio de salida:**
- 60 FPS con 500+ enemigos en pantalla.
- Una partida de 10 min es divertida incluso con placeholders.
- Datos de rendimiento suficientes para decidir si el núcleo se queda en GDScript o pasa a GDExtension.
- Decisión tomada sobre el co-op (condiciona la arquitectura de la Fase 2).

### Fase 2 · Sistemas núcleo
**Hecho (2026-11-07):** código preparado para varios campeones (co-op); élites con afijos (Veloz, Blindado, Explosivo); cofres; evoluciones de las 4 armas; build visible en el HUD con niveles; menú de pausa visual; avisos y flechas a objetivos; **línea de tiempo del mapa (10 min), Heraldo, estampida y La Madre Raíz con 3 fases + último aliento, ataques telegrafiados y victoria**. El jefe aparece por tiempo (minuto 10); la variante del altar queda pendiente.

- Probar las dos formas de que aparezca el jefe (por tiempo y por altar) y quedarse con una.
- Stats y modificadores, efectos y disparadores, etiquetas.
- ✅ Evoluciones y cofres de élite.
- ✅ Aumentos (17, en las 3 rarezas) con críticos.
- ✅ Sinergias de 5 elementos (2 y 3 armas), estados alterados y 7 armas elementales nuevas (11 en total + la de firma).
- ✅ Élites con afijos, Heraldo y **1 jefe con 3 fases** (La Madre Raíz).
- ✅ Línea de tiempo completa de un reino y estampida.
- ✅ Oro, objetos rompibles (comida, imán, bomba, oro), Altar de Sangre, Mercader Errante y Contrato.
- ✅ Registro de partidas (`user://telemetry`) y resumen con `tools/telemetry_report.py`.

**La Fase 2 queda completa (2026-11-07).**
- Telemetría de balance.

**Criterio de salida:** un reino completo de 12 min con jefe, que apetece rejugar 10 veces con builds distintas.

### Fase 3 · Vertical slice — *calidad final, en pequeño*
**En curso (2026-11-07):**
- ✅ Estilo del moodboard aplicado al prototipo (suelo, luz, niebla, decorado y paleta).
- ✅ Menú principal, selección de campeón, ajustes, guardado, Esencia, Armería (9 mejoras) y 8 logros que desbloquean 3 armas.
- ✅ Orrun 3D probado (2026-11-08) con Hyper3D y Blender; **descartado al pasar a 2D** (el pipeline queda archivado en `tools/blender/`).
- ✅ **Paso a 2D (2026-11-12):** Orrun como marioneta de 10 piezas animada por código (andar, puñetazo, zancada, golpe de tierra, paso, muerte), los 3 enemigos del Bosque con su dibujo y animación procedural (salto, galope, balanceo), suelo, efectos, telegrafías, jefa, cofres y eventos en 2D. Rendimiento: 1.500 enemigos con 5 ms de simulación y 2,2 ms de dibujado.
- ✅ Mejoras tras la primera prueba (2026-11-12): marioneta recortada del dibujo entero (proporciones fieles), animaciones nuevas (paso pesado, directo y martillazo con congelación de impacto, embestida con estela, salto de esquiva, golpe de tierra), arreglado que la horda dejara de dibujarse al alejarse del centro y aparición justo fuera de la vista con más densidad, y cartas de elección con color e icono por categoría (arma, reliquia, kit, aumento, evolución, curación).
- Provisional (dibujado por código, falta su arte): pilares, árboles, setas, urnas, cofres, mercader, altar, contrato y la Madre Raíz (usa el Tronco Hueco teñido).
- Pendiente: arte del decorado y de la jefa, segundo campeón (Sela), VFX y audio.

- Bosque de los Susurros con arte, iluminación, VFX y audio finales.
- 2 campeones con arte y animaciones finales.
- 10-12 armas, 8 reliquias, 25 aumentos y 4 evoluciones.
- UI final (HUD, subida de nivel, pausa, resumen), ajustes y guardado.
- Hub en menú + meta-progresión básica (Esencia, Armería y 5-10 desbloqueos).

**Criterio de salida:** se puede enseñar a desconocidos y grabar GIFs o un tráiler.

### Fase 4 · Expedición y portales
- Reinos 2 y 3 con sus jefes.
- Portales en partida (elección de ruta con recompensa visible) y portales del hub.
- Escalado por profundidad y jefe final (primera versión).
- 4 campeones, Códice, desbloqueos por logros y Pactos.

**Criterio de salida:** una expedición completa jugable de principio a fin.

### Fase 5 · Contenido de lanzamiento, Caos y pulido
- Completar el contenido mínimo de lanzamiento (ver [Alcance](#alcance-y-calendario-orientativo)): ~16 armas, ~40 aumentos y el modo Supervivencia.
- Mutadores y modo Caos.
- Balance guiado por telemetría, accesibilidad y soporte de mando.
- Demo pública (Steam Next Fest) y página de Steam para acumular wishlists.
- Lanzamiento en **Acceso Anticipado** en Steam.

### Fase 6+ · Actualizaciones tras el lanzamiento
Hasta 6 campeones y 5-6 reinos, ~25 armas y ~60 aumentos; co-op (si se decide), desafío diario con semilla, modo Infinito, reacciones elementales, fusiones, mods, otras plataformas y localización (ver [GDD §13](GDD.md#13-ideas-futuras-backlog)).

---

## Alcance y calendario orientativo

Calculado para **una persona a tiempo parcial (~10-15 h/semana)**. Es una estimación inicial: se revisa al terminar la Fase 1 con la velocidad real.

| Fase | Duración orientativa |
|------|---------------------|
| 0 · Preproducción | 2-4 semanas |
| 1 · Prototipo greybox | 2-3 meses |
| 2 · Sistemas núcleo | 3-4 meses |
| 3 · Vertical slice | 4-6 meses |
| 4 · Expedición y portales | 4-6 meses |
| 5 · Contenido de lanzamiento y pulido | 6+ meses |

**Total hasta el Acceso Anticipado:** unos 2-3 años. Para no alargarlo más:
- **Lanzar con un contenido mínimo** y ampliar con actualizaciones: 4 campeones, 3 reinos + el final, ~16 armas, ~40 aumentos y los modos Expedición y Supervivencia.
- **El cuello de botella es el arte, no el código:** usar assets CC0 el mayor tiempo posible, atlas de color siempre que se pueda y bases generadas con IA para retocar. Si hay presupuesto, encargar fuera los modelos de los campeones.
- **Recortar antes que retrasar:** si una fase se alarga más de un 50 % sobre lo previsto, se quita contenido de esa fase en lugar de seguir añadiendo.

---

## Decisiones

### Tomadas (2026-11-07)

| # | Tema | Decisión |
|---|------|----------|
| 1 | Movimiento | WASD/stick para moverse + ratón para apuntar |
| 2 | Habilidades | Manuales, con opción de autolanzamiento en ajustes |
| 3 | Esquiva | Paso común a todos los campeones |
| 4 | Estructura de la run | Expedición (modo principal) + Supervivencia clásica |
| 5 | Mapas | Grandes con límites + puntos de interés semialeatorios |
| 6 | Cámara | 2D cenital ligeramente inclinada (cambiado el 2026-11-12; antes perspectiva 3D a ~55°) |
| 7 | Lenguaje | GDScript con tipado estático; núcleo de hordas aislado por si hubiera que pasarlo a C++ |
| 8 | Texturas | Mixto: pintado a mano en campeones y jefes, atlas de color en el resto |
| 9 | Equipo | Una persona a tiempo parcial, con apoyo de Claude Code |
| 10 | Plataformas | PC (Steam), con soporte de mando |
| 11 | Nombre | **Umbral** como nombre de trabajo |
| 12 | Co-op | **Online, 2-4 jugadores** (decidido el 2026-11-07). El código se prepara desde la Fase 2; la red llega más tarde (ver [TECNICO §7](TECNICO.md#7-multijugador-online)) |

### Pendientes

| Tema | Cuándo | Notas |
|------|--------|-------|
| Aparición del jefe (por tiempo o por altar) | Durante la Fase 2 | Montar ambas y elegir jugando |
| Co-op: subida de nivel compartida, reanimar, escalado por jugadores | Al implementar la red | Propuesta inicial en TECNICO §7 |
| Nombre definitivo | Antes de crear la página de Steam | Comprobar disponibilidad en Steam, dominio y marca |
| Otras plataformas (Steam Deck, consolas) | Tras el lanzamiento en PC | El soporte de mando ya lo deja preparado |

---

## Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Rendimiento de hordas | Alto | Diseño orientado a datos + MultiMesh 2D con animación por código; stress test periódico |
| Alcance (una persona a tiempo parcial; el arte es caro) | Muy alto | Placeholders CC0, atlas de color, vertical slice antes de producir contenido, Acceso Anticipado con contenido mínimo y recortar antes que retrasar ([ver Alcance](#alcance-y-calendario-orientativo)) |
| Legibilidad caótica | Alto | Código de color reservado, opacidad de VFX regulable, contornos, telegrafías por encima de todo |
| Co-op añadido tarde | Alto | Decidirlo antes de la Fase 2 |
| Parecido a LoL / propiedad intelectual | Medio | Nombres, kits, terminología y estética propios; Riot ya tiene un modo similar (*Swarm*) del que hay que diferenciarse |
| Balance con muchos sistemas cruzados | Medio | Telemetría, consola de trucos y hojas de cálculo como fuente de verdad |

---

## Consejos generales

- **Haz la Fase 1 fea a propósito.** Si es divertido con cápsulas, con arte será mejor; si no lo es, el arte no lo salvará.
- **Juega cada día lo que construyes** y grábate de vez en cuando: verás problemas de legibilidad que en directo se te escapan.
- **Pruebas con otras personas desde la Fase 2.** Míralas jugar sin explicarles nada.
- **Mide antes de optimizar:** el profiler de Godot y el stress test deciden, no la intuición.
- **Marketing temprano:** devlog, GIFs cortos en redes y página de Steam en cuanto haya vertical slice. Las wishlists se acumulan con el tiempo.
- **Commits pequeños**, ramas por funcionalidad y LFS desde el primer día.
