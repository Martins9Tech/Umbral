class_name ChampionKit
extends Node
## Kit de 4 piezas de un campeón (GDD §4.1): Rasgo, arma de firma, Técnica y
## Definitiva. Cada campeón extiende esta clase. Pertenece a un Player concreto.

const MAX_TECHNIQUE_RANK := 5
const MAX_ULTIMATE_RANK := 3
const IMPETU_MAX := 100.0
const IMPETU_PER_KILL := 0.4
const IMPETU_PER_DAMAGE := 1.0
## Tras usar la Definitiva, el Ímpetu no se acumula durante este tiempo.
const IMPETU_LOCKOUT := 20.0

var run: Run
var champion: Player
var champion_name := ""
var trait_name := ""
var trait_description := ""
var technique_name := ""
var technique_description := ""
var ultimate_name := ""
var ultimate_description := ""
## Id del Rasgo (para su icono).
var trait_id: StringName
## Ids de las habilidades (los que emite EventBus.ability_cast).
var technique_id: StringName
var ultimate_id: StringName
## Altura del dibujo del campeón en metros (el cuerpo lógico es un círculo).
var visual_height := 2.6
var technique_rank := 1
var ultimate_rank := 1
## La Definitiva se carga con Ímpetu (matar y, sobre todo, recibir daño).
var impetu := 0.0
var technique_cooldown_left := 0.0
var impetu_lockout_left := 0.0
## Nombres visibles de las fuentes de daño propias del kit (para resúmenes).
var source_names: Dictionary = {}


func setup(p_run: Run, p_champion: Player) -> void:
	run = p_run
	champion = p_champion
	_on_setup()
	apply_base_stats(champion.stats)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_damaged.connect(_on_player_damaged)


# --- Para sobrescribir en cada campeón ---

func _on_setup() -> void:
	pass


func apply_base_stats(_stats: Stats) -> void:
	pass


## Dibujo 2D del campeón (marioneta o sprite). null = círculo greybox.
## Debe ofrecer: facing, movimiento, tinte, auto_avanzar, avanzar(delta),
## accion(nombre), herido() y morir(); y medir ALTURA unidades.
func create_visual() -> Node2D:
	return null


func signature_weapon_id() -> StringName:
	return &""


func tick(_delta: float) -> void:
	pass


func try_technique(_aim: Vector2) -> void:
	pass


func try_ultimate(_aim: Vector2) -> void:
	pass


func technique_cooldown_max() -> float:
	return 1.0


func ultimate_active() -> bool:
	return false


func damage_taken_multiplier() -> float:
	return 1.0


## Progreso del Rasgo (0-1) para su icono del HUD.
func trait_fill() -> float:
	return 0.0


## Texto grande del icono del Rasgo.
func trait_text() -> String:
	return ""


# --- Comunes ---

func ultimate_ready() -> bool:
	return impetu >= IMPETU_MAX


func dmg(base: float) -> float:
	return base * champion.stats.get_stat(StatId.DAMAGE)


func area() -> float:
	return champion.stats.get_stat(StatId.AREA)


## Llamar desde tick() de cada campeón.
func tick_impetu(delta: float) -> void:
	impetu_lockout_left = maxf(0.0, impetu_lockout_left - delta)


## Llamar cuando termina la Definitiva.
func start_impetu_lockout() -> void:
	impetu_lockout_left = IMPETU_LOCKOUT


func _can_gain_impetu() -> bool:
	return not ultimate_active() and impetu_lockout_left <= 0.0


func _on_enemy_killed(_type_index: int, _position: Vector2, _flags: int) -> void:
	if _can_gain_impetu():
		impetu = minf(IMPETU_MAX, impetu + IMPETU_PER_KILL)


func _on_player_damaged(player: Node, amount: float) -> void:
	if player == champion and _can_gain_impetu():
		impetu = minf(IMPETU_MAX, impetu + amount * IMPETU_PER_DAMAGE)
