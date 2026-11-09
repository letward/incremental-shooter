extends Node3D

@export var spawn_radius: float = 26.0
@export var spawn_interval: float = 1.2

var spawn_timer: float = 0.0
var wave_delay: float = 0.0
var spawning_wave: bool = false
var enemies_left_to_spawn: int = 0
var wave_active: bool = false
var waiting_next: bool = false

func _ready() -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	GameManager.enemies_alive = 0
	_start_wave(1)

func _start_wave(w: int) -> void:
	GameManager.set_wave(w)
	AudioManager.play("wave_start", -3.0)
	var count = 5 + w * 3
	enemies_left_to_spawn = count
	spawn_timer = 0.0
	wave_active = true
	spawning_wave = true
	waiting_next = false

func _process(delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	if not wave_active:
		return
	if spawning_wave:
		spawn_timer -= delta
		if spawn_timer <= 0 and enemies_left_to_spawn > 0:
			spawn_timer = spawn_interval
			_spawn_one()
			enemies_left_to_spawn -= 1
			if enemies_left_to_spawn <= 0:
				spawning_wave = false
	# wave clear -> wait then next
	if not spawning_wave and GameManager.enemies_alive <= 0:
		if not waiting_next:
			waiting_next = true
			wave_delay = 3.0
		else:
			wave_delay -= delta
			if wave_delay <= 0:
				_start_wave(GameManager.wave + 1)

func _spawn_one() -> void:
	var w = GameManager.wave
	var variant = 0
	var r = randf()
	if w >= 3 and r < 0.25:
		variant = 1
	if w >= 5 and r > 0.75:
		variant = 2
	var angle = randf() * TAU
	var pos = Vector3(cos(angle) * spawn_radius, 1.0, sin(angle) * spawn_radius)
	# avoid spawning too close to any player
	for p in get_tree().get_nodes_in_group("player"):
		if pos.distance_to(p.global_position) < 8.0:
			pos = -pos
	var enemy_spawner = null
	var main = get_tree().current_scene
	if main and main.has_node("EnemySpawner"):
		enemy_spawner = main.get_node("EnemySpawner")
	if enemy_spawner and multiplayer.has_multiplayer_peer():
		enemy_spawner.spawn({"variant": variant, "pos": pos, "wave": w})
	else:
		var enemy_scene = load("res://scenes/enemy.tscn")
		if enemy_scene == null:
			return
		var e = enemy_scene.instantiate()
		if main and main.has_node("Enemies"):
			main.get_node("Enemies").add_child(e)
		else:
			get_tree().current_scene.add_child(e)
		e.position = pos
		e.setup(variant, w)
	GameManager.enemies_alive += 1
