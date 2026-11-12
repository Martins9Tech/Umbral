class_name UpgradeOffer
extends RefCounted
## Genera y aplica las opciones de mejora de un jugador (GDD §5.1): subida de
## nivel y cofres. Cada opción es un Dictionary con: kind, title, description,
## tag y sus datos.

const WEIGHT_WEAPON_UP := 1.2
const WEIGHT_WEAPON_NEW := 1.0
const WEIGHT_RELIC := 0.9
const WEIGHT_TECHNIQUE := 0.8
const WEIGHT_ULTIMATE := 0.6
const ULTIMATE_MIN_LEVEL := 6
const HEAL_AMOUNT := 30.0


## owned_only: solo mejora lo que el jugador ya tiene (lo usan los cofres).
static func generate(run: Run, player: Player, rng: RandomNumberGenerator, amount: int,
		owned_only: bool = false) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []

	for weapon: Weapon in player.weapons:
		if weapon.level < weapon.data.max_level and not weapon.is_evolved():
			var description := weapon.data.description + _evolution_hint(weapon.data)
			# ¿Esta subida deja el arma lista para evolucionar?
			var completes := weapon.level + 1 >= weapon.data.max_level and weapon.data.evolution != null \
				and player.relic_level(weapon.data.evolution_relic) > 0
			if completes:
				description = "¡Con esta mejora quedará LISTA para evolucionar!  " + weapon.data.description
			pool.append({
				"kind": &"weapon_up", "weapon": weapon, "weight": WEIGHT_WEAPON_UP, "tag": "ARMA",
				"title": "%s  ·  Nv %d" % [weapon.data.display_name, weapon.level + 1],
				"description": description, "evolution": completes,
			})

	if not owned_only and player.free_weapon_slots() > 0:
		for data: WeaponData in ContentDB.weapons:
			if data.is_signature or data.is_evolution or player.has_weapon(data.id):
				continue
			# Armas que se desbloquean con logros (GDD §9).
			if not run.unlock_everything and not SaveManager.is_weapon_unlocked(data.id):
				continue
			var synergy_text := _synergy_hint(player, data)
			pool.append({
				"kind": &"weapon_new", "data": data, "weight": WEIGHT_WEAPON_NEW, "tag": "ARMA",
				"title": "%s  ·  NUEVA  ·  %s" % [data.display_name, _element_names(data)],
				"description": synergy_text + data.description + _evolution_hint(data),
				"synergy": not synergy_text.is_empty(),
			})

	for relic: RelicData in ContentDB.relics:
		var current := player.relic_level(relic.id)
		if current >= relic.max_level:
			continue
		if current == 0 and (owned_only or player.free_relic_slots() <= 0):
			continue
		var level_text := "NUEVA" if current == 0 else "Nv %d" % (current + 1)
		var hint := _relic_hint(player, relic)
		pool.append({
			"kind": &"relic", "data": relic, "weight": WEIGHT_RELIC, "tag": "RELIQUIA",
			"title": "%s  ·  %s" % [relic.display_name, level_text],
			"description": relic.description + hint,
			# Solo la primera vez importa para evolucionar (basta tenerla).
			"evolution": current == 0 and not hint.is_empty(),
		})

	var kit := player.kit
	if kit.technique_rank < ChampionKit.MAX_TECHNIQUE_RANK:
		pool.append({
			"kind": &"technique", "weight": WEIGHT_TECHNIQUE, "tag": "TÉCNICA",
			"title": "%s  ·  Rango %d" % [kit.technique_name, kit.technique_rank + 1],
			"description": "Más daño y menos enfriamiento.",
		})
	if kit.ultimate_rank < ChampionKit.MAX_ULTIMATE_RANK and run.level >= ULTIMATE_MIN_LEVEL:
		pool.append({
			"kind": &"ultimate", "weight": WEIGHT_ULTIMATE, "tag": "DEFINITIVA",
			"title": "%s  ·  Rango %d" % [kit.ultimate_name, kit.ultimate_rank + 1],
			"description": "Aumenta el daño de la Definitiva.",
		})

	var picked: Array[Dictionary] = []
	while picked.size() < amount and not pool.is_empty():
		var total := 0.0
		for option: Dictionary in pool:
			total += float(option["weight"])
		var roll := rng.randf() * total
		var chosen := pool.size() - 1
		for k in pool.size():
			roll -= float(pool[k]["weight"])
			if roll <= 0.0:
				chosen = k
				break
		picked.append(pool[chosen])
		pool.remove_at(chosen)

	if picked.is_empty():
		picked.append({
			"kind": &"heal", "tag": "EXTRA", "title": "Curación",
			"description": "Recupera %d de vida." % int(HEAL_AMOUNT),
		})
	return picked


static func apply(player: Player, option: Dictionary) -> void:
	var kind: StringName = option["kind"]
	match kind:
		&"weapon_up":
			var weapon: Weapon = option["weapon"]
			weapon.level_up()
		&"weapon_new":
			var data: WeaponData = option["data"]
			player.add_weapon(data)
		&"relic":
			var relic: RelicData = option["data"]
			player.set_relic_level(relic, player.relic_level(relic.id) + 1)
		&"technique":
			player.kit.technique_rank += 1
		&"ultimate":
			player.kit.ultimate_rank += 1
		&"heal":
			player.heal(HEAL_AMOUNT)


static func relic_display_name(id: StringName) -> String:
	for relic: RelicData in ContentDB.relics:
		if relic.id == id:
			return relic.display_name
	return str(id)


## "¡Activa la sinergia de Fuego (2/3)!" si coger esta arma sube un nivel de sinergia.
static func _synergy_hint(player: Player, data: WeaponData) -> String:
	for tag: StringName in Synergies.elements_of(data.tags):
		var amount := player.synergy_count(tag) + 1
		if Synergies.tier_for(amount) > player.synergy_tier(tag):
			return "¡Activa la sinergia de %s (%d armas)!  " % [Synergies.display_name(tag), amount]
	return ""


static func _element_names(data: WeaponData) -> String:
	var names := PackedStringArray()
	for tag: StringName in Synergies.elements_of(data.tags):
		names.append(Synergies.display_name(tag))
	return ", ".join(names)


static func _evolution_hint(data: WeaponData) -> String:
	if data.evolution == null:
		return ""
	return "\nEvoluciona con: %s" % relic_display_name(data.evolution_relic)


static func _relic_hint(player: Player, relic: RelicData) -> String:
	var names := PackedStringArray()
	for weapon: Weapon in player.weapons:
		if not weapon.is_evolved() and weapon.data.evolution_relic == relic.id:
			names.append(weapon.data.display_name)
	if names.is_empty():
		return ""
	return "\nNecesaria para evolucionar: %s" % ", ".join(names)
