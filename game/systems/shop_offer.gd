class_name ShopOffer
extends RefCounted
## Artículos del Mercader Errante (GDD §5.7): arma nueva, subir un arma,
## reliquia, curación completa y un aumento, cada uno con su precio en oro.

const PRICE_WEAPON_NEW := 60
const PRICE_WEAPON_UP := 35
const PRICE_RELIC := 40
const PRICE_HEAL := 25
const AUGMENT_PRICES := [70, 110, 160]  # Eco, Arcano, Mítico


static func generate(run: Run, player: Player, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	# Pool amplio de mejoras y se coge la primera de cada tipo.
	var pool := UpgradeOffer.generate(run, player, rng, 14)
	for wanted: StringName in [&"weapon_new", &"weapon_up", &"relic"]:
		for option: Dictionary in pool:
			if option["kind"] == wanted:
				offers.append({
					"kind": &"upgrade", "option": option, "tag": option["tag"],
					"title": option["title"], "description": option["description"],
					"price": _upgrade_price(wanted),
				})
				break
	offers.append({
		"kind": &"heal", "tag": "CURACIÓN", "title": "Poción del bosque",
		"description": "Recupera toda tu vida.", "price": PRICE_HEAL,
	})
	var augments := AugmentOffer.generate(player, rng, run.director.minute(), 1)
	if not augments.is_empty():
		var data := augments[0]
		offers.append({
			"kind": &"augment", "data": data, "tag": "AUMENTO " + AugmentData.rarity_name(data.rarity),
			"title": data.display_name, "description": data.description,
			"price": AUGMENT_PRICES[data.rarity],
		})
	return offers


static func apply(run: Run, player: Player, offer: Dictionary) -> void:
	match offer["kind"]:
		&"upgrade":
			UpgradeOffer.apply(player, offer["option"])
		&"heal":
			player.heal(player.max_hp())
		&"augment":
			var data: AugmentData = offer["data"]
			player.add_augment(data)
	run.log_choice(&"tienda", str(offer["title"]))


static func _upgrade_price(kind: StringName) -> int:
	match kind:
		&"weapon_new":
			return PRICE_WEAPON_NEW
		&"weapon_up":
			return PRICE_WEAPON_UP
	return PRICE_RELIC
