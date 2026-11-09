extends Node

var selected: String = "rifle"

var loadouts: Dictionary = {
	"pistol": {"name": "Pistol", "desc": "Light and quick. A reliable sidearm.", "damage": 7.0, "interval": 0.25, "mag": 12, "pellets": 1, "spread": 0.02, "range": 80.0, "color": Color(1.0, 0.9, 0.3)},
	"rifle": {"name": "Assault Rifle", "desc": "Balanced. Effective at all ranges.", "damage": 10.0, "interval": 0.12, "mag": 30, "pellets": 1, "spread": 0.01, "range": 100.0, "color": Color(0.2, 0.8, 1.0)},
	"smg": {"name": "SMG", "desc": "High fire rate, low damage. Spray and pray.", "damage": 5.0, "interval": 0.06, "mag": 45, "pellets": 1, "spread": 0.04, "range": 60.0, "color": Color(0.3, 1.0, 0.4)},
	"shotgun": {"name": "Shotgun", "desc": "Devastating up close. Slow reload.", "damage": 7.0, "interval": 0.85, "mag": 6, "pellets": 8, "spread": 0.14, "range": 30.0, "color": Color(1.0, 0.5, 0.2)},
	"sniper": {"name": "Sniper", "desc": "One-shot potential. Slow and precise.", "damage": 45.0, "interval": 1.2, "mag": 5, "pellets": 1, "spread": 0.001, "range": 200.0, "color": Color(0.9, 0.3, 0.9)},
}

func get_loadout(id: String) -> Dictionary:
	if loadouts.has(id):
		return loadouts[id]
	return loadouts["rifle"]

func get_selected() -> Dictionary:
	return get_loadout(selected)
