extends Control

@onready var status: Label = $Center/VBox/Status
@onready var players_label: Label = $Center/VBox/PlayersLabel
@onready var create_btn: Button = $Center/VBox/Tab/Create/CreateBtn
@onready var join_btn: Button = $Center/VBox/Tab/Join/JoinBtn
@onready var start_btn: Button = $Center/VBox/StartBtn
@onready var back_btn: Button = $Center/VBox/BackBtn

@onready var port_input: LineEdit = $Center/VBox/Tab/Create/PortInput
@onready var pass_input: LineEdit = $Center/VBox/Tab/Create/PassInput
@onready var ip_input: LineEdit = $Center/VBox/Tab/Join/IPInput
@onready var port_input2: LineEdit = $Center/VBox/Tab/Join/PortInput2
@onready var pass_input2: LineEdit = $Center/VBox/Tab/Join/PassInput2

func _ready() -> void:
	create_btn.pressed.connect(_create)
	join_btn.pressed.connect(_join)
	start_btn.pressed.connect(_start)
	back_btn.pressed.connect(_back)
	NetworkManager.server_started.connect(_on_server_started)
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_failed)
	NetworkManager.lobby_joined.connect(_on_lobby_joined)
	NetworkManager.player_connected.connect(_on_player_changed)
	NetworkManager.player_disconnected.connect(_on_player_changed)
	start_btn.visible = false
	_update_players()

func _create() -> void:
	var port = int(port_input.text)
	var pwd = pass_input.text
	NetworkManager.host_game(port, pwd)
	status.text = "Hosting on port %d..." % port

func _join() -> void:
	var ip = ip_input.text
	var port = int(port_input2.text)
	var pwd = pass_input2.text
	NetworkManager.join_game(ip, port, pwd)
	status.text = "Connecting to %s:%d..." % [ip, port]

func _on_server_started() -> void:
	status.text = "Lobby created. Waiting for players..."
	start_btn.visible = true
	_update_players()

func _on_connected() -> void:
	status.text = "Connected. Validating..."

func _on_lobby_joined() -> void:
	status.text = "Joined lobby!"
	_update_players()

func _on_failed() -> void:
	status.text = "Connection failed."

func _on_player_changed(_id) -> void:
	_update_players()

func _update_players() -> void:
	var count = 1
	if NetworkManager.is_host:
		count = 1 + NetworkManager.connected_peers.size()
	players_label.text = "Players: %d" % count
	if NetworkManager.is_host:
		start_btn.visible = true

func _start() -> void:
	if not NetworkManager.is_host:
		return
	# tell clients to go to loadout/game? For simplicity host starts; clients follow via scene change RPC
	rpc("go_to_game")
	go_to_game()

@rpc("authority", "reliable", "call_local")
func go_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/loadout_select.tscn")

func _back() -> void:
	NetworkManager.disconnect_game()
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")