extends Node

signal money_changed(amount: int)
signal kills_changed(amount: int)
signal wave_changed(wave: int)
signal health_changed(current: float, maximum: float)
signal ammo_changed(current: int, maximum: int, reserve: int)
signal upgrade_purchased(id: String)

var money: int = 0
var kills: int = 0
var wave: int = 1
var enemies_alive: int = 0
var paused: bool = false

# Upgrade definitions
var upgrades: Dictionary = {
	"damage": {"name": "Damage", "desc": "+25% weapon damage", "base": 50, "scale": 1.55, "level": 0, "max": 25, "kind": "mult", "step": 0.25},
	"fire_rate": {"name": "Fire Rate", "desc": "Faster shooting", "base": 75, "scale": 1.6, "level": 0, "max": 20, "kind": "add", "step": -0.006},
	"max_health": {"name": "Max Health", "desc": "+25 max health", "base": 60, "scale": 1.5, "level": 0, "max": 12, "kind": "add", "step": 25.0},
	"move_speed": {"name": "Move Speed", "desc": "+0.5 movement speed", "base": 80, "scale": 1.5, "level": 0, "max": 12, "kind": "add", "step": 0.5},
	"mag_size": {"name": "Magazine Size", "desc": "+5 bullets per mag", "base": 90, "scale": 1.5, "level": 0, "max": 12, "kind": "add", "step": 5},
	"reload_speed": {"name": "Reload Speed", "desc": "Faster reload", "base": 100, "scale": 1.55, "level": 0, "max": 10, "kind": "add", "step": -0.12},
	"armor": {"name": "Armor", "desc": "+5% damage reduction", "base": 120, "scale": 1.6, "level": 0, "max": 12, "kind": "add", "step": 0.05},
	"lifesteal": {"name": "Lifesteal", "desc": "+2% lifesteal on hit", "base": 200, "scale": 1.7, "level": 0, "max": 10, "kind": "add", "step": 0.02},
}

func _ready() -> void:
	pass

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false

func add_kill() -> void:
	kills += 1
	kills_changed.emit(kills)

func set_wave(w: int) -> void:
	wave = w
	wave_changed.emit(wave)

func upgrade_cost(id: String) -> int:
	var u = upgrades[id]
	var lvl = u["level"]
	return int(u["base"] * pow(u["scale"], lvl))

func can_upgrade(id: String) -> bool:
	var u = upgrades[id]
	return u["level"] < u["max"]

func buy_upgrade(id: String) -> bool:
	if not can_upgrade(id):
		return false
	var cost = upgrade_cost(id)
	if not spend_money(cost):
		return false
	var u = upgrades[id]
	u["level"] += 1
	upgrades[id] = u
	upgrade_purchased.emit(id)
	return true

func get_stat(id: String, base: float) -> float:
	# generic: for damage mult
	return base

func damage_mult() -> float:
	return 1.0 + upgrades["damage"]["level"] * upgrades["damage"]["step"]

func fire_interval() -> float:
	var base = 0.15
	var v = base + upgrades["fire_rate"]["level"] * upgrades["fire_rate"]["step"]
	return max(0.04, v)

func max_health() -> float:
	return 100.0 + upgrades["max_health"]["level"] * upgrades["max_health"]["step"]

func move_speed() -> float:
	return 5.0 + upgrades["move_speed"]["level"] * upgrades["move_speed"]["step"]

func mag_size() -> int:
	return 30 + upgrades["mag_size"]["level"] * upgrades["mag_size"]["step"]

func reload_time() -> float:
	var base = 1.6
	var v = base + upgrades["reload_speed"]["level"] * upgrades["reload_speed"]["step"]
	return max(0.4, v)

func armor_reduction() -> float:
	return min(0.6, upgrades["armor"]["level"] * upgrades["armor"]["step"])

func lifesteal() -> float:
	return upgrades["lifesteal"]["level"] * upgrades["lifesteal"]["step"]
