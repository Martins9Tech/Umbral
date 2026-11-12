class_name MetaContent
extends RefCounted
## Contenido de la progresión permanente (GDD §9): campeones, mejoras de la
## Armería, logros y la fórmula de Esencia. Los datos viven aquí para el
## prototipo; más adelante pasarán a .tres como el resto del contenido.

# --- Campeones ---
const CHAMPIONS := [
	{
		"id": &"orrun", "name": "Orrun", "title": "El Monolito Errante", "role": "Tanque · cuerpo a cuerpo",
		"kit": "res://entities/champions/orrun/orrun_kit.gd", "color": Color("e3811f"),
		"description": "Una montaña que camina. Aguanta quieto para endurecerse y suelta ondas sísmicas al moverse.",
		"unlock": &"",
	},
	{
		"id": &"sela", "name": "Sela Voltaria", "title": "La Tormenta Encadenada", "role": "Maga · a distancia",
		"kit": "", "color": Color("5fd8ff"),
		"description": "Rayos que saltan entre enemigos y una tormenta que la sigue. Próximamente.",
		"unlock": &"proximamente",
	},
]

# --- Armería: mejoras permanentes (se compran con Esencia) ---
## stat: estadística afectada; kind: Stats.Kind; value: por rango; cost: coste del rango 1 (sube por rango).
const ARMORY := [
	{"id": &"vigor", "name": "Vigor", "desc": "+10 de vida máxima por rango.", "stat": &"max_hp", "kind": 0, "value": 10.0, "max": 5, "cost": 60},
	{"id": &"poder", "name": "Poder", "desc": "+5 % de daño por rango.", "stat": &"damage", "kind": 1, "value": 0.05, "max": 5, "cost": 80},
	{"id": &"coraza", "name": "Coraza", "desc": "+3 de armadura por rango.", "stat": &"armor", "kind": 0, "value": 3.0, "max": 5, "cost": 70},
	{"id": &"celeridad", "name": "Celeridad", "desc": "+4 % de velocidad por rango.", "stat": &"move_speed", "kind": 1, "value": 0.04, "max": 3, "cost": 90},
	{"id": &"iman", "name": "Imán", "desc": "+15 % de radio del imán por rango.", "stat": &"magnet", "kind": 1, "value": 0.15, "max": 3, "cost": 50},
	{"id": &"sabiduria", "name": "Sabiduría", "desc": "+5 % de experiencia por rango.", "stat": &"xp_gain", "kind": 1, "value": 0.05, "max": 5, "cost": 70},
	{"id": &"codicia", "name": "Codicia", "desc": "+15 % de oro por rango.", "stat": &"", "kind": 1, "value": 0.15, "max": 3, "cost": 60},
	{"id": &"recambio", "name": "Recambio", "desc": "+1 recambio en cada elección de aumento.", "stat": &"", "kind": 0, "value": 1.0, "max": 2, "cost": 150},
	{"id": &"segunda_vida", "name": "Segunda Oportunidad", "desc": "Una vez por partida, al caer vuelves con la mitad de la vida.", "stat": &"", "kind": 0, "value": 1.0, "max": 1, "cost": 400},
]

# --- Logros (desbloquean contenido y dan Esencia) ---
## check: qué se mira al acabar la partida (ver Run.end_of_run_stats).
const ACHIEVEMENTS := [
	{"id": &"primera_partida", "name": "Primeros pasos", "desc": "Termina tu primera partida.", "check": &"runs", "goal": 1, "essence": 50, "unlocks": &""},
	{"id": &"carnicero", "name": "Carnicero", "desc": "Mata 1.000 enemigos en una partida.", "check": &"kills", "goal": 1000, "essence": 100, "unlocks": &"minas_de_brea"},
	{"id": &"evolucionista", "name": "Evolucionista", "desc": "Evoluciona un arma.", "check": &"evolutions", "goal": 1, "essence": 120, "unlocks": &"orbe_de_tormenta"},
	{"id": &"veterano", "name": "Veterano", "desc": "Juega 3 partidas.", "check": &"runs", "goal": 3, "essence": 80, "unlocks": &"guadana_umbria"},
	{"id": &"superviviente", "name": "Superviviente", "desc": "Llega al minuto 10.", "check": &"minutes", "goal": 10, "essence": 150, "unlocks": &""},
	{"id": &"armonia", "name": "Armonía", "desc": "Activa una sinergia de nivel 2 (3 armas del mismo elemento).", "check": &"synergy3", "goal": 1, "essence": 120, "unlocks": &""},
	{"id": &"buen_cliente", "name": "Buen cliente", "desc": "Gasta 150 de oro en una partida.", "check": &"gold_spent", "goal": 150, "essence": 80, "unlocks": &""},
	{"id": &"matarraices", "name": "Matarraíces", "desc": "Derrota a La Madre Raíz.", "check": &"victory", "goal": 1, "essence": 300, "unlocks": &""},
]


static func champion(id: StringName) -> Dictionary:
	for entry: Dictionary in CHAMPIONS:
		if entry["id"] == id:
			return entry
	return CHAMPIONS[0]


static func armory_entry(id: StringName) -> Dictionary:
	for entry: Dictionary in ARMORY:
		if entry["id"] == id:
			return entry
	return {}


## Coste del siguiente rango (sube con cada compra).
static func armory_cost(entry: Dictionary, current_rank: int) -> int:
	return int(entry["cost"]) * (current_rank + 1)


## Arma bloqueada por un logro que aún no tienes.
static func weapon_lock(weapon_id: StringName) -> Dictionary:
	for achievement: Dictionary in ACHIEVEMENTS:
		if achievement["unlocks"] == weapon_id:
			return achievement
	return {}


## Esencia ganada al acabar una partida.
static func essence_for(stats: Dictionary) -> int:
	var minutes: float = stats["minutes"]
	var essence := minutes * 12.0 + float(stats["kills"]) / 40.0 + float(stats["level"]) * 2.0
	essence += float(stats["gold"]) * 0.3
	if stats["victory"]:
		essence += 200.0
	return roundi(essence)
