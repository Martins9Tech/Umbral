class_name AugmentOffer
extends RefCounted
## Genera las 3 opciones de aumento (GDD §5.5). Cada carta tira su rareza
## según el minuto: cuanto más avanzada la partida, más Arcanos y Míticos.


## Pesos de rareza (Eco, Arcano, Mítico) según el minuto.
static func rarity_weights(minute: float) -> Array[float]:
	if minute < 6.0:
		return [0.6, 0.33, 0.07]
	return [0.3, 0.48, 0.22]


## forced_rarity >= 0 obliga a que todas sean de esa rareza (p. ej. el altar).
static func generate(player: Player, rng: RandomNumberGenerator, minute: float, amount: int = 3,
		forced_rarity: int = -1) -> Array[AugmentData]:
	var weights := rarity_weights(minute)
	var picked: Array[AugmentData] = []
	for _k in amount:
		var rarity := forced_rarity if forced_rarity >= 0 else _roll_rarity(rng, weights)
		var candidate := _pick(player, rng, picked, rarity)
		if candidate == null:
			candidate = _pick(player, rng, picked, -1)  # cualquier rareza
		if candidate != null:
			picked.append(candidate)
	return picked


static func _roll_rarity(rng: RandomNumberGenerator, weights: Array[float]) -> int:
	var roll := rng.randf()
	for k in weights.size():
		roll -= weights[k]
		if roll <= 0.0:
			return k
	return 0


static func _pick(player: Player, rng: RandomNumberGenerator, exclude: Array[AugmentData], rarity: int) -> AugmentData:
	var pool: Array[AugmentData] = []
	for data: AugmentData in ContentDB.augments:
		if player.has_augment(data.id) or exclude.has(data):
			continue
		if rarity >= 0 and data.rarity != rarity:
			continue
		pool.append(data)
	if pool.is_empty():
		return null
	return pool[rng.randi_range(0, pool.size() - 1)]
