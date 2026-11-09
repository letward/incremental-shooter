extends Node3D

@onready var players_node: Node3D = $Players
@onready var enemies_node: Node3D = $Enemies
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var enemy_spawner: MultiplayerSpawner = $EnemySpawner

func _ready() -> void:
	player_spawner.spawn_path = players_node.get_path()
	player_spawner.spawn_function = _spawn_player
	enemy_spawner.spawn_path = enemies_node.get_path()
	enemy_spawner.spawn_function = _spawn_enemy

	if multiplayer.has_multiplayer_peer():
		if multiplayer.is_server():
			_spawn_player_local(multiplayer.get_unique_id())
			for pid in NetworkManager.connected_peers:
				_spawn_player_local(pid)
			NetworkManager.player_connected.connect(func(pid): _spawn_player_local(pid))
	else:
		# single player
		var p = preload("res://scenes/player.tscn").instantiate()
		p.name = "1"
		p.set_multiplayer_authority(1)
		p.position = Vector3(0, 1.5, 0)
		players_node.add_child(p)

func _spawn_player_local(pid: int) -> void:
	if player_spawner.spawn_path:
		player_spawner.spawn(pid)

func _spawn_player(data) -> Node:
	var pid = 1
	if typeof(data) == TYPE_INT:
		pid = data
	var p = preload("res://scenes/player.tscn").instantiate()
	p.name = str(pid)
	p.set_multiplayer_authority(pid)
	p.position = Vector3(0, 1.5, 0)
	return p

func _spawn_enemy(data) -> Node:
	var variant = 0
	var pos = Vector3.ZERO
	var wave = GameManager.wave
	if typeof(data) == TYPE_DICTIONARY:
		variant = data.get("variant", 0)
		pos = data.get("pos", Vector3.ZERO)
		wave = data.get("wave", GameManager.wave)
	var e = preload("res://scenes/enemy.tscn").instantiate()
	e.setup(variant, wave)
	e.position = pos
	return e