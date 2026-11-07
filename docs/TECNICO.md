# UMBRAL — Arquitectura técnica y pipeline v0.1

> Complementa al [GDD](GDD.md). Versión de Godot instalada en este equipo: **4.7.2 stable**.

---

## 1. Stack

| Área | Elección | Notas |
|------|----------|-------|
| Motor | **Godot 4.7** | Renderer **Forward+** (PC) |
| Lenguaje | **GDScript con tipado estático** | El núcleo de simulación (hordas, proyectiles, colisiones) queda aislado para migrarlo a **C++ (GDExtension)** o C# si el profiler lo pide |
| 3D | **Blender** → glTF 2.0 (`.glb`) | |
| Versiones | **Git + Git LFS** | `.blend`, `.glb`, `.png` y `.wav` por LFS |
| Tests | **gdUnit4** (o GUT) | Lógica pura: stats, fórmulas, efectos |
| Automatización | **Claude Code + MCP de Godot y Blender** | Ya conectados en este equipo: crear escenas, exportar modelos en lote, scripts de Blender |

> **Decidido:** GDScript. Si el profiler lo exige, el núcleo de hordas se reescribe en C++ con GDExtension (la vía más rápida) sin tocar el resto del juego.

---

## 2. Perspectiva 2.5D (plano 2D + elementos 3D)

- **Mundo 3D; lógica en el plano XZ (y = 0).** Todo el gameplay trabaja con `Vector2(x, z)`: colisiones, IA y spawns son 2D, lo que es más simple y más rápido. La altura es solo visual (proyectiles en arco, saltos, cuerpos voladores).
- **Camera3D (decidido):** perspectiva con FOV estrecho (~30-35°), inclinación de ~55° y distancia fija; sigue al jugador con suavizado. El FOV y la inclinación exactos se ajustan en el prototipo.
- **Iluminación:** una `DirectionalLight3D` con sombras y luz ambiental; shader toon opcional.
- **Contornos:** *inverted hull* o post-proceso para el jugador, élites y jefes.
- **Oclusión:** si algo tapa al jugador, se desvanece o se muestra su silueta a través de las paredes.

---

## 3. Rendimiento de hordas — riesgo técnico n.º 1

**Objetivo:** 60 FPS con **500+ enemigos en pantalla** (1.000+ vivos) y 2.000+ proyectiles, en un PC medio (GTX 1060 o similar).

### Reglas
1. **Nada de un nodo con física por enemigo.** `CharacterBody3D` + `NavigationAgent3D` por enemigo no escala a cientos.
2. **Simulación orientada a datos:** un `EnemySwarm` guarda en arrays (`PackedVector2Array`, `PackedFloat32Array`…) posición, velocidad, vida, tipo y estado de cada enemigo, y los actualiza en **un único bucle** por frame.
3. **Render con `MultiMeshInstance3D`**, una por tipo de enemigo. Cada instancia lleva su transform y *custom data* (frame de animación, destello al recibir daño, disolución al morir).
4. **Animación con VAT (Vertex Animation Textures):** las animaciones (andar, atacar, morir) se "hornean" en Blender a una textura, y un shader de vértices en Godot reproduce el frame de cada instancia. Para los enemigos más simples basta con animación procedural en shader (balanceo, *squash & stretch*).
5. **Colisiones con rejilla espacial (spatial hash):** enemigo-enemigo (separación), proyectil-enemigo y jugador-enemigo, todo como círculo contra círculo.
6. **Movimiento:** perseguir + separación para la mayoría; **flow field** (BFS sobre una rejilla desde el jugador, recalculado 4-5 veces por segundo) en mapas con obstáculos.
7. **Pooling de todo:** proyectiles, gemas, números de daño y efectos visuales. Nada se crea ni se destruye en pleno combate.
8. **Gemas de XP:** límite máximo y fusión cuando hay demasiadas.
9. **Sombras baratas:** los enemigos usan *blob shadows* (decal o quad) en vez de sombras proyectadas.
10. **Élites y jefes sí son escenas completas** (son pocos): `AnimationTree`, hitboxes reales, física (Jolt) si hace falta.
11. **Profiling desde el día 1:** monitor de FPS, contador de entidades, tiempos de simulación y una escena de **stress test** (2.000 enemigos).
12. **Plan B:** como `EnemySwarm` y `ProjectileSystem` están aislados detrás de una API de datos, se pueden reescribir en GDExtension sin tocar el resto del juego.

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
  /assets             ← .glb y texturas importadas
  /debug              ← consola, stress tests
  /tests
/art                  ← fuentes: .blend, .kra, etc. (fuera del proyecto Godot)
/tools                ← scripts de exportación de Blender, importador de hojas de balance
/docs
```

### 4.9 Herramientas de depuración (desde el prototipo)
- **Consola de trucos:** dar armas o aumentos, subir de nivel, saltar tiempo, invocar jefe o fase, modo dios, velocidad ×2, ver hitboxes y flow field.
- **Telemetría de balance:** al acabar cada run se guarda un JSON/CSV con daño por arma, aumentos elegidos, tiempo y causa de muerte.
- **Stress test** de enemigos y proyectiles.

### 4.10 Balance con hojas de cálculo
Las tablas numéricas (armas por nivel, enemigos, curvas de XP y del Director) viven en una hoja de cálculo. Un script `@tool` de Godot importa el CSV y genera o actualiza los `.tres`. La hoja es la fuente de verdad de los números; el editor, la del resto.

---

## 5. Pipeline de arte (Blender → Godot)

### 5.1 Especificaciones orientativas
| Elemento | Triángulos | Texturas | Animación |
|----------|-----------|----------|-----------|
| Campeón | 5k-12k | 1-2k, pintada a mano | Esqueleto + `AnimationTree` |
| Jefe | 10k-25k | 2k | Esqueleto |
| Enemigo común | 300-1.500 | Atlas compartido de 256-512 | **VAT** |
| Élite | 1k-3k | 512 | VAT o esqueleto |
| Escenario | Kit modular | Atlas por reino | — |

- **Escala:** 1 unidad = 1 m; campeones de ~2 m (proporciones exageradas).
- **Exportación:** aplicar transformaciones y exportar `.glb`; el exportador convierte el eje Z-up de Blender al Y-up de Godot.
- **Nombres:** `chr_orrun.glb`, `enm_bosque_seta.glb`, `prop_bosque_arbol_01.glb`. Animaciones: `idle`, `run`, `dash`, `cast_tech`, `cast_ult`, `hit`, `death`, `victory`.
- **Importación:** usar sufijos de Godot (`-col`, `-colonly`) para colisiones y scripts de post-importación para asignar materiales.
- Godot puede importar `.blend` directamente (con Blender instalado), lo que es cómodo para iterar. Para builds estables se recomienda exportar `.glb` con un script por lotes, automatizable con el MCP de Blender.

### 5.2 Animación
- **Rig:** Rigify (gratis) o Auto-Rig Pro (de pago).
- **Prototipos:** Mixamo para animaciones humanoides rápidas (revisa su licencia actual).
- **Enemigos:** andar, atacar y morir, horneadas a VAT con un add-on de Blender (p. ej. OpenVAT) y un shader propio en Godot.

### 5.3 Texturizado
- **Opción A (rápida y coherente):** low-poly + *gradient atlas* (UVs sobre una paleta de colores) + shader toon. Ideal para enemigos y escenario.
- **Opción B (más "MOBA"):** pintado a mano con Blender Texture Paint, Krita, ArmorPaint o Substance Painter. Para campeones y jefes.
- **Recomendado:** mixto, B para personajes protagonistas y A para todo lo demás.

### 5.4 VFX
- `GPUParticles3D` + shaders (disolución, fresnel, ruido animado, *gradient mapping*).
- Flipbooks renderizados en Blender (o con EmberGen, de pago).
- Las telegrafías se implementan como sistema propio, no como VFX sueltos (§4.7).

### 5.5 Assets para prototipar (gratuitos, CC0)
- **KayKit**, **Quaternius**, **Kenney**: personajes, mazmorras y props low-poly, perfectos como placeholders.
- **Poly Haven:** texturas y HDRI.
- **IA generativa 3D** (Meshy, Tripo, Rodin…): útil para placeholders o bases que luego se retopologizan; revisa las licencias.

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
| 3D, rig y animación | Blender (+ Rigify) / Auto-Rig Pro | Gratis / pago |
| Texturas | Krita, Material Maker / ArmorPaint / Substance Painter | Gratis / bajo / pago |
| UI e iconos | Krita, Aseprite, Inkscape, Figma (maquetas) | Gratis / bajo |
| VFX | Shaders de Godot, Blender / EmberGen | Gratis / pago |
| Audio | Reaper, Audacity, jsfxr / FMOD | Bajo / gratis |
| Versiones | Git + Git LFS (GitHub o GitLab) | Gratis |
| Gestión | HacknPlan (específico para gamedev), Jira, Trello o Notion | Gratis / pago |
| Balance | Google Sheets / Excel → CSV → importador `@tool` | — |
| Tests | gdUnit4 / GUT | Gratis |
| Steam | GodotSteam | Gratis |
