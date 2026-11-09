extends Node

var sounds: Dictionary = {}
var players: Array = []
const POOL_SIZE: int = 10

func _ready() -> void:
	var names = ["shoot","hit","enemy_death","reload","pickup","wave_start","player_hurt","empty","ui_click"]
	for n in names:
		var res = load("res://assets/sounds/%s.wav" % n)
		if res:
			sounds[n] = res
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)

func play(name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not sounds.has(name):
		return
	for p in players:
		if not p.playing:
			p.stream = sounds[name]
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return
	# reuse
	players[0].stream = sounds[name]
	players[0].volume_db = volume_db
	players[0].pitch_scale = pitch
	players[0].play()
