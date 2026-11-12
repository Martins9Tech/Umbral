# UMBRAL — Arquitectura técnica y pipeline v0.1

> Complementa al [GDD](GDD.md). Versión de Godot instalada en este equipo: **4.7.2 stable**.

---

## 1. Stack

| Área | Elección | Notas |
|------|----------|-------|
| Motor | **Godot 4.7** | Renderer **Forward+** (PC) |
| Lenguaje | **GDScript con tipado estático** | El núcleo de simulación (hordas, proyectiles, colisiones) queda aislado para migrarlo a **C++ (GDExtension)** o C# si el profiler lo pide |
| Arte | **2D**: IA de imágenes (`tools/ia/`) + scripts de recorte (`tools/sprites/`) | Ver [GUIA_ESTILO §11](GUIA_ESTILO.md#11-arte-2d-flujo-de-producción) |
| Versiones | **Git + Git LFS** | `.png`, `.ttf` y audio por LFS |
| Tests | **gdUnit4** (o GUT) | Lógica pura: stats, fórmulas, efectos |
| Automatización | **Claude Code + MCP de Godot** + API de imágenes de Azure | Escenas, pruebas automáticas y generación de arte por lotes |

> **Decidido:** GDScript. Si el profiler lo exige, el núcleo de hordas se reescribe en C++ con GDExtension (la vía más rápida) sin tocar el resto del juego.

---

## 2. Mundo 2D

- **Lógica en metros (`Vector2`).** Colisiones, IA, spawns y daño trabajan en metros, igual que antes del cambio a 2D.
- **`Run.world`** es un `Node2D` escalado a píxeles (`Run.PPM` = 56 px/m): todo lo que cuelga de él se coloca y dibuja en metros.
- **Capas** (de abajo arriba): suelo (shader `ground_forest_2d`), decorado bajo, efectos de suelo (telegrafías, discos, arena del jefe), gemas, objetos (urnas, cofres, eventos), horda, jefes, jugadores (ordenados por Y), armas, efectos aéreos (proyectiles, rayos) y copas de los árboles.
- **Cámara:** `Camera2D` que sigue al campeón con suavizado; a 1080p se ven unos 34 × 19 m.
- **Luz:** `CanvasModulate` para la penumbra y `PointLight2D` en el campeón y en las setas.
- **Profundidad:** el campeón se dibuja siempre por encima de la horda (legibilidad); los enemigos grandes, por debajo de los pequeños.

## 3. Rendimiento de hordas — riesgo técnico n.º 1

**Objetivo:** 60 FPS con **500+ enemigos en pantalla** (1.000+ vivos) y 2.000+ proyectiles, en un PC medio (GTX 1060 o similar).

### Reglas
1. **Nada de un nodo con física por enemigo.** `CharacterBody3D` + `NavigationAgent3D` por enemigo no escala a cientos.
2. **Simulación orientada a datos:** un `EnemySwarm` guarda en arrays (`PackedVector2Array`, `PackedFloat32Array`…) posición, velocidad, vida, tipo y estado de cada enemigo, y los actualiza en **un único bucle** por frame.
3. **Render con `MultiMeshInstance2D`**, una por tipo de enemigo y otra para las sombras. Cada instancia lleva su transform, un color (estados) y *custom data* (destello al recibir daño, shader `horda_2d`).
4. **Animación procedural:** cada tipo salta, galopa o se balancea; se calcula al escribir el buffer (rotación, escala y altura por instancia). Si el profiler lo pide, se puede pasar al shader.
5. **Colisiones con rejilla espacial (spatial hash):** enemigo-enemigo (separación), proyectil-enemigo y jugador-enemigo, todo como círculo contra círculo.
6. **Movimiento:** perseguir + separación para la mayoría; **flow field** (BFS sobre una rejilla desde el jugador, recalculado 4-5 veces por segundo) en mapas con obstáculos.
7. **Pooling de todo:** proyectiles, gemas, números de daño y efectos visuales. Nada se crea ni se destruye en pleno combate.
8. **Gemas de XP:** límite máximo y fusión cuando hay demasiadas.
9. **Sombras baratas:** los enemigos usan *blob shadows* (decal o quad) en vez de sombras proyectadas.
10. **Élites y jefes sí son escenas completas** (son pocos): `AnimationTree`, hitboxes reales, física (Jolt) si hace falta.
11. **Profiling desde el día 1:** monitor de FPS, contador de entidades, tiempos de simulación y una escena de **stress test** (2.000 enemigos).
12. **Plan B:** como `EnemySwarm` y `ProjectileSystem` están aislados detrás de una API de datos, se pueden reescribir en GDExtension sin tocar el resto del juego.

### 3.1 Mediciones del prototipo

Prueba automática sin ventana (`--fixed-fps 60`, 600 frames medidos, solo CPU):

| Prueba | Enemigos | Simulación (media / máx.) | Preparar el dibujado |
|--------|----------|---------------------------|----------------------|
| Estrés (`--autotest --stress`): 1.500 enemigos encima del campeón (3D, 2026-11-07) | ~1.050 de media | 8,8 ms / 18 ms | 0,4 ms |
| Estrés en 2D (2026-11-12), con ventana | ~750 de media | 5,1 ms / 17 ms | 2,2 ms (animación por enemigo) |

- Coste aproximado: **~8 µs por enemigo y frame**, casi todo en la separación entre vecinos.
- Con 500 enemigos en pantalla son ~4 ms: el criterio de la Fase 1 se cumple en CPU. Con el máximo del Director (1.200 vivos) ronda los 10 ms, ajustado pero viable.
- Falta medir los FPS reales con ventana y GPU (overlay F1 en el editor).
- Si hiciera falta más margen, por orden: calcular la separación en frames alternos y, después, pasar `EnemySwarm` a GDExtension.

**Cómo repetir la prueba:**
```
Godot_v4.7.2-stable_win64_console.exe --headless --path game --fixed-fps 60 -- --autotest --stress
```
Sin `--stress`, la prueba da todas las armas y mide una partida con el Director acelerado.

### 3.2 Pruebas de dificultad

Partidas reales sin modo dios hasta morir o 15 min; imprimen `[BALANCE]` con tiempo, nivel y muertes:
- `-- --autotest --idle`: el jugador no se mueve (caso peor).
- `-- --autotest --bot`: un bot sencillo que huye de la horda, recoge cofres cercanos y usa la Técnica y la Definitiva en cuanto puede.

Añadiendo `--god` (`-- --autotest --bot --god`) el bot no muere: sirve para medir a qué nivel llega al minuto 10 y cuánto tarda en matar a la jefa.

Otras pruebas: `-- --autotest --augments` activa los 17 aumentos a la vez con el bot (caza errores de interacción); `-- --autotest --boss` lleva directamente a la jefa con una build fuerte e imprime `[BOSS]` cada 10 s; `-- --autotest --evo` comprueba que un cofre evoluciona un arma lista; `-- --autotest --showcase` prepara una escena con build variada, élite, cofre y menú de pausa para capturas (con `--write-movie`).

| Ajuste (2026-11-07) | Quieto | Bot |
|---------------------|--------|-----|
| Inicial | muere en 1:07 | **sobrevive 15 min** (nivel 54) |
| Calibrado | muere en 0:37-0:59 | muere hacia 4:10 (nivel 14) |
| Con mapa de 10 min y jefa (curva más suave) | muere en ~0:30 | muere entre 3:40 y 6:20; en modo dios llega a la jefa a nivel 27 y la mata en 56 s (2 evoluciones) o ~115 s (sin evoluciones) |

Cambios del calibrado: enemigos más rápidos (el Lobo supera al jugador) y con más daño, curva de XP `5 + 10n + 0,6n²`, vida de los enemigos `×(1 + 0,25m + 0,04m²)`, densidad mínima por minuto, Orrun con menos vida y armadura, y la Definitiva que deja de cargar 20 s tras usarla (antes casi se encadenaba y daba invulnerabilidad permanente).

---

## 4. Arquitectura de código

### 4.1 Principios
- **Basado en datos:** todo el contenido (campeones, armas, aumentos, enemigos, reinos) son `Resource` (`.tres`) editables en el inspector. Añadir contenido no requiere tocar código.
- **Composición sobre herencia.**
- **Bus de eventos** para desacoplar sistemas: los aumentos reaccionan a eventos y no a referencias directas.
- **RNG con semilla por run**, separado en flujos (spawns, botín, aumentos) para que las semillas sean reproducibles. Esto habilita el desafío diario y facilita reproducir bugs.

### 4.2 Autoloads
| Autoload | Responsabilidad |
|----------|-----------------|
| `EventBus` | Señales globales: `enemy_killed`, `damage_dealt`, `level_up`, `ability_cast`, `boss_phase_changed`… |
| `GameState` | Estado de la run en curso |
| `SaveManager` | Progreso persistente en `user://` (JSON versionado con migraciones) y ajustes aparte (`settings.cfg`) |
| `ContentDB` | Registro de todos los recursos de contenido, accesibles por id |
| `RNG` | Generadores con semilla por flujo |
| `AudioManager`, `SceneRouter` | Audio y transiciones entre escenas |

### 4.3 Recursos de datos
| Resource | Contenido principal |
|----------|---------------------|
| `ChampionData` | Stats base, modelo, `TraitData`, arma de firma, Técnica, Definitiva, Hito |
| `AbilityData` | Valores por rango, `Array[AbilityMutation]`, Despertar, tipo de apuntado |
| `WeaponData` | Niveles, etiquetas, patrón de disparo, receta de evolución |
| `RelicData` | Stat que modifica y valores por nivel |
| `AugmentData` | Rareza, etiquetas, set, efectos, condiciones de aparición |
| `ChaosMutatorData` | Efectos globales sobre jugador y enemigos |
| `EnemyData` | Stats, arquetipo, coste para el Director, mesh y textura VAT |
| `BossData` | `Array[BossPhase]` (umbral de vida y patrones) |
| `MapData` | Escena del terreno, tabla de spawns por minuto, eventos, Heraldo, jefe, música, condiciones de desbloqueo |

### 4.4 Stats y modificadores
- `StatBlock` con las estadísticas como `StringName` o enum.
- `Modifier { stat, tipo: PLANO | PORCENTAJE | MULTIPLICADOR, valor, origen, etiquetas }`
- `final = (base + Σ planos) × (1 + Σ %) × Π multiplicadores`, con caché que se invalida al cambiar.
- **Modificadores con etiqueta:** "Fuego +20 % de daño" solo se aplica a armas con la etiqueta Fuego.

### 4.5 Efectos y disparadores (lo que hace posibles los aumentos)
- **`Effect`** (Resource componible): `DealDamage`, `ApplyStatus`, `SpawnProjectile`, `AreaPulse`, `Heal`, `Shield`, `TempStatModifier`, `SpawnSummon`, `Chain`…
- **`Trigger`**: `on_hit`, `on_kill`, `on_crit`, `on_damaged`, `on_ability_cast`, `on_dash`, `on_level_up`, `on_status_applied`, `every_n_seconds`…
- **Un aumento** = modificadores de stats + lista de `(Trigger → Condición → Effect)`.
- **Vía de escape:** los aumentos que no encajen en el sistema pueden llevar un script propio (`AugmentScript`).
- **`DamageInfo`** (fuente, cantidad, tipo, etiquetas, crítico, posición) recorre un *pipeline* con ganchos antes y después de la mitigación, donde los aumentos pueden intervenir.

### 4.6 Armas, proyectiles y habilidades
- **`WeaponInstance`:** nodo ligero con temporizador que, al disparar, ejecuta un **Pattern** reutilizable y parametrizado (proyectil dirigido, orbital, área aleatoria, invocación, trampa…).
- **`ProjectileSystem`:** orientado a datos como el `EnemySwarm`; el visual va por MultiMesh o partículas.
- **`AbilityInstance`:** estado (rango, mutación, enfriamiento o carga), apuntado (dirección, punto o automático) y ejecución de `Effect`s.

### 4.7 Otros sistemas
- **`SpawnDirector`:** créditos por segundo, tablas por reino y eventos programados (GDD §8.2).
- **Jefes:** máquina de estados por fase; cada patrón de ataque es un recurso (telegrafía + timing + efecto).
- **Telegrafías:** quads en el suelo con un shader de relleno progresivo (indica cuándo impacta), dibujados por encima de los efectos visuales.
- **UI:** nodos `Control` con un `Theme` global. La subida de nivel pausa el árbol (`get_tree().paused`) y la UI usa `process_mode = ALWAYS`.

### 4.8 Estructura de carpetas propuesta
```
/game                 ← proyecto Godot (project.godot)
  /autoload
  /core               ← stats, efectos, eventos, rng, guardado
  /systems            ← swarm, proyectiles, director, botín, xp
  /entities           ← jugador, campeones, élites, jefes
  /content            ← .tres: campeones, armas, reliquias, aumentos, enemigos, jefes, reinos
  /scenes             ← hub, run, reinos
  /ui
  /vfx  /shaders  /audio
  /assets             ← sprites, iconos, marcos de interfaz y fuentes
  /debug              ← consola, stress tests
  /tests
/art                  ← fuentes: .blend, .kra, etc. (fuera del proyecto Godot)
/tools                ← generación de imágenes (ia/), recorte y preparación de arte (sprites/), telemetría
/docs
```

### 4.9 Herramientas de depuración (desde el prototipo)
- **Consola de trucos:** dar armas o aumentos, subir de nivel, saltar tiempo, invocar jefe o fase, modo dios, velocidad ×2, ver hitboxes y flow field.
- **Telemetría de balance:** al acabar cada run se guarda un JSON/CSV con daño por arma, aumentos elegidos, tiempo y causa de muerte.
- **Stress test** de enemigos y proyectiles.

**Registro de partidas (implementado):** al terminar cada partida se guarda un JSON en `user://telemetry` (en Windows: `%APPDATA%\Godot\app_userdata\Umbral\telemetry`) con resultado, tiempo, nivel, oro, causa de la muerte, build, daño por fuente, elecciones y una instantánea por minuto. Las partidas del bot se marcan con `"modo": "bot"`. Resumen:
```
python tools/telemetry_report.py            # tus partidas
python tools/telemetry_report.py --modo bot
```

**Guardado (implementado):** `SaveManager` guarda el progreso en `user://save.json` (Esencia, Armería, logros, estadísticas; versionado) y los ajustes en `user://settings.cfg`. Las pruebas automáticas nunca lo modifican. Prueba de la progresión con un guardado aparte: `-- --metatest --test-save`.

### 4.10 Balance con hojas de cálculo
Las tablas numéricas (armas por nivel, enemigos, curvas de XP y del Director) viven en una hoja de cálculo. Un script `@tool` de Godot importa el CSV y genera o actualiza los `.tres`. La hoja es la fuente de verdad de los números; el editor, la del resto.

---

## 5. Pipeline de arte

El juego es 2D desde el 2026-11-12 (el prototipo 3D con Blender y Hyper3D se descartó y se borró). Todo el flujo de producción de arte está en [GUIA_ESTILO §11](GUIA_ESTILO.md#11-arte-2d-flujo-de-producción): generación con la API de imágenes, recorte, marionetas de campeones, enemigos con animación por código, iconos, decorado, marcos de interfaz y fuentes.

- **Escala:** 1 m = 56 px a 1080p (`Run.PPM`); Orrun mide 2,7 m.
- **VFX:** dibujados por código (`VfxPool`, `Efecto` en `Player`), partículas 2D y shaders `canvas_item`.

### 5.6 Audio
- **SFX de prototipo:** jsfxr o ChipTone.
- **Librerías:** paquete anual gratuito de Sonniss (GDC); Freesound (revisa cada licencia).
- **Edición:** Reaper o Audacity.
- **Música dinámica:** `AudioStreamInteractive` / `AudioStreamSynchronized` (nativos de Godot) para capas por intensidad y fases de jefe. FMOD (integración GDExtension) solo si hiciera falta algo más avanzado.

---

## 6. Herramientas recomendadas

| Área | Herramienta | Coste |
|------|-------------|-------|
| Motor | Godot 4.7 | Gratis |
| Arte 2D | API de imágenes de Azure (gpt-image) + scripts propios; Krita para retoques | Pago por uso / gratis |
| UI e iconos | Krita, Aseprite, Inkscape, Figma (maquetas) | Gratis / bajo |
| VFX | Shaders y partículas 2D de Godot | Gratis |
| Audio | Reaper, Audacity, jsfxr / FMOD | Bajo / gratis |
| Versiones | Git + Git LFS (GitHub o GitLab) | Gratis |
| Gestión | HacknPlan (específico para gamedev), Jira, Trello o Notion | Gratis / pago |
| Balance | Google Sheets / Excel → CSV → importador `@tool` | — |
| Tests | gdUnit4 / GUT | Gratis |
| Steam | GodotSteam | Gratis |

---

## 7. Multijugador online

**Decidido (2026-11-07):** co-op online de 2 a 4 jugadores. La red se implementará más adelante, pero el código se escribe desde la Fase 2 para que añadirla no obligue a rehacer el juego.

### 7.1 Modelo: anfitrión con autoridad
- Un jugador hace de **anfitrión** y simula todo: horda, proyectiles, daño, botín, director.
- Los demás **solo envían su intención** (`PlayerInput`: movimiento, apuntado y botones) y reciben el estado para dibujarlo, interpolado.
- Sin simulación determinista ni *rollback*: más sencillo y robusto con cientos de enemigos.

### 7.2 Reglas para el código desde ya
1. **La simulación nunca lee el teclado o el ratón**: todo entra por `PlayerInput`. Hoy se rellena en local; mañana llegará por red.
2. **Nada asume un único jugador**: la partida tiene `players`; cada `Player` lleva su kit, sus armas, sus reliquias y su daño. `run.player` es solo el jugador local (cámara y HUD).
3. **El azar sale de los RNG de la partida** (`rng_spawn`, `rng_loot`), que solo usa el anfitrión.
4. **Lo puramente visual** (VFX, temblor de cámara) se podrá emitir como evento para los clientes.

### 7.3 Transporte y sincronización (propuesta)
- **Desarrollo y LAN:** `ENetMultiplayerPeer` de Godot.
- **Lanzamiento:** redes de Steam con **GodotSteam** (lobbies, invitaciones y relay de Steam, sin problemas de NAT).
- **Instantáneas a ~20 Hz:** jugadores completos; enemigos comprimidos (posición en int16 + tipo + flags ≈ 6 bytes). 1.000 enemigos ≈ 120 KB/s por cliente, que se reducirá enviando solo lo cercano a cada cliente y por deltas.
- **Eventos fiables** para lo puntual: muertes, cofres, subidas de nivel, VFX importantes.

### 7.4 Diseño de co-op (propuesta, a validar)
- **Experiencia y nivel compartidos.** Al subir de nivel se pausa para todos; cada jugador elige su mejora y se continúa cuando todos han elegido (o a los 20 s, con elección automática).
- **Cofres:** para quien los toca.
- **Caer en combate:** el jugador queda derribado y un compañero lo reanima quedándose cerca unos segundos; la partida acaba si caen todos.
- **Escalado:** vida de enemigos ×(1 + 0,6 por jugador extra) y densidad ×(1 + 0,5 por jugador extra).
