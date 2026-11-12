class_name OrrunKit
extends ChampionKit
## Orrun, el Monolito Errante: tanque cuerpo a cuerpo (GDD §4.4).
## - Rasgo, Raíz Profunda: quieto acumula Piedra (menos daño recibido);
##   al moverse la libera como onda sísmica.
## - Arma de firma: Puño Telúrico (ver systems/weapons/puno_telurico.gd).
## - Técnica, Zancada de Falla: embestida que daña y deja una grieta que ralentiza.
## - Definitiva, Despertar del Monte: 6 s inmóvil e invulnerable con terremotos.

const STONE_INTERVAL := 1.0
const MAX_STONES := 5
const STONE_REDUCTION := 0.05
const STRIDE_DISTANCE := 6.0
const STRIDE_TIME := 0.18
const STRIDE_SLOW_TIME := 4.0
const ULT_DURATION := 6.0
const QUAKE_INTERVAL := 1.0

var stones := 0
var _still_time := 0.0
var _ult_left := 0.0
var _quake_left := 0.0


func _on_setup() -> void:
	champion_name = "Orrun, el Monolito Errante"
	trait_name = "Raíz Profunda"
	trait_description = "Quieto, gana 1 capa de Piedra por segundo (máx. 5): -5 % de daño recibido por capa. Al moverse, la libera como una onda sísmica que crece con las capas."
	technique_name = "Zancada de Falla"
	technique_description = "Embestida hacia donde apuntas que daña y empuja, y deja una grieta que ralentiza durante 4 s."
	ultimate_name = "Despertar del Monte"
	ultimate_description = "Durante 6 s, Orrun queda inmóvil e invulnerable y lanza un terremoto enorme cada segundo. Se carga con Ímpetu."
	visual_height = 2.7
	trait_id = &"raiz_profunda"
	technique_id = &"zancada_de_falla"
	ultimate_id = &"despertar_del_monte"
	source_names = {
		&"raiz_profunda": trait_name,
		&"zancada_de_falla": technique_name,
		&"despertar_del_monte": ultimate_name,
	}


func apply_base_stats(stats: Stats) -> void:
	stats.set_base(StatId.MAX_HP, 140.0)
	stats.set_base(StatId.ARMOR, 10.0)
	stats.set_base(StatId.REGEN, 0.3)
	stats.set_base(StatId.MOVE_SPEED, 6.0)


func create_visual() -> Node2D:
	return MarionetaOrrun.new()


func signature_weapon_id() -> StringName:
	return &"puno_telurico"


func tick(delta: float) -> void:
	technique_cooldown_left = maxf(0.0, technique_cooldown_left - delta)
	tick_impetu(delta)
	_tick_trait(delta)
	champion.set_stone_count(stones)


func _tick_trait(delta: float) -> void:
	if _ult_left > 0.0:
		_tick_ultimate(delta)
		return
	if champion.is_moving:
		if stones > 0:
			_release_stones()
		_still_time = 0.0
	else:
		_still_time += delta
		if _still_time >= STONE_INTERVAL and stones < MAX_STONES:
			_still_time = 0.0
			stones += 1
			run.vfx.disc(champion.pos, 0.8 + 0.15 * stones, Color(0.65, 0.65, 0.7, 0.5), 0.35)


func damage_taken_multiplier() -> float:
	return 1.0 - STONE_REDUCTION * stones


func trait_fill() -> float:
	return stones / float(MAX_STONES)


func trait_text() -> String:
	return "%d/%d" % [stones, MAX_STONES]


func technique_cooldown_max() -> float:
	return (6.0 - 0.4 * (technique_rank - 1)) * champion.stats.get_stat(StatId.COOLDOWN)


func try_technique(aim: Vector2) -> void:
	if technique_cooldown_left > 0.0 or _ult_left > 0.0 or champion.is_dashing():
		return
	var direction := aim.normalized()
	var start := champion.pos
	var end := (start + direction * STRIDE_DISTANCE).clamp(run.bounds.position, run.bounds.end)
	champion.start_dash(direction, start.distance_to(end), STRIDE_TIME)
	champion.play_action(&"technique")
	var width := 1.4 * area()
	run.damage_segment(start, end, width, dmg(25.0 + 12.0 * (technique_rank - 1)), 7.0, &"zancada_de_falla", champion)
	run.swarm.add_slow_zone(start, end, width, STRIDE_SLOW_TIME)
	run.vfx.line(start, end, width * 1.6, Color(0.42, 0.28, 0.18, 0.75), STRIDE_SLOW_TIME)
	technique_cooldown_left = technique_cooldown_max()
	EventBus.ability_cast.emit(champion, technique_id)


func ultimate_active() -> bool:
	return _ult_left > 0.0


func try_ultimate(_aim: Vector2) -> void:
	if not ultimate_ready() or _ult_left > 0.0:
		return
	impetu = 0.0
	_ult_left = ULT_DURATION
	_quake_left = 0.0
	stones = 0
	champion.rooted = true
	champion.invulnerable = true
	champion.set_ultimate_visual(true)
	EventBus.ability_cast.emit(champion, ultimate_id)


func _tick_ultimate(delta: float) -> void:
	_ult_left -= delta
	_quake_left -= delta
	var center := champion.pos
	if _quake_left <= 0.0:
		_quake_left = QUAKE_INTERVAL
		var radius := 9.0 * area()
		run.damage_circle(center, radius, dmg(40.0 + 25.0 * (ultimate_rank - 1)), 10.0, &"despertar_del_monte", center, champion)
		run.vfx.disc(center, radius, Color(0.6, 0.45, 0.3, 0.45), 0.45)
		run.add_shake(0.35)
		champion.play_action(&"cast")
	if _ult_left <= 0.0:
		champion.rooted = false
		champion.invulnerable = false
		champion.set_ultimate_visual(false)
		start_impetu_lockout()


func _release_stones() -> void:
	var center := champion.pos
	var radius := (2.5 + 0.6 * stones) * area()
	run.damage_circle(center, radius, dmg(8.0 * stones), 5.0 + 2.0 * stones, &"raiz_profunda", center, champion)
	run.vfx.disc(center, radius, Color(0.8, 0.8, 0.85, 0.55), 0.4)
	if stones >= 3:
		run.add_shake(0.06 * stones)
	stones = 0
