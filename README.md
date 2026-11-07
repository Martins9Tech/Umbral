# UMBRAL *(título provisional)*

Roguelike de supervivencia contra hordas en 3D isométrico (estilo survivors), con campeones de kit propio, armas automáticas, aumentos, reinos conectados por portales y jefes con fases. Motor: **Godot 4.7** · Arte: **Blender**.

**Estado:** preproducción. Decisiones de base cerradas el 2026-11-07; proyecto de Godot creado, aún sin código. **Plataforma:** PC (Steam).

## Cómo abrir el proyecto
1. Instala [Git LFS](https://git-lfs.com) y ejecuta `git lfs install` una vez por equipo (los modelos, texturas y audios van por LFS).
2. Abre Godot 4.7 → **Importar** → selecciona `game/project.godot`.

## Estructura
- `game/`: proyecto de Godot (código, escenas, contenido `.tres` y assets importados).
- `art/`: fuentes de arte (`.blend`, `.kra`…), fuera del proyecto de Godot.
- `tools/`: scripts auxiliares (exportación desde Blender, importación de hojas de balance).
- `docs/`: documentación de diseño y técnica.

## Documentación
- [docs/GDD.md](docs/GDD.md): diseño del juego (campeones, progresión, aumentos, reinos, portales, jefes, enemigos).
- [docs/TECNICO.md](docs/TECNICO.md): arquitectura en Godot, rendimiento de hordas y pipeline Blender → Godot.
- [docs/ROADMAP.md](docs/ROADMAP.md): fases de desarrollo, decisiones abiertas y riesgos.
