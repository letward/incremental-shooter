extends Node

signal connected_to_server
signal connection_failed
signal server_started
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal lobby_joined

var is_host: bool = false
var host_password: String = ""
var connected_peers: Array = []
var local_peer_id: int = 1

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int, password: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, 8)
	if err != OK:
		push_error("Failed to create server: %s" % err)
		return
	multiplayer.multiplayer_peer = peer
	is_host = true
	host_password = password
	local_peer_id = 1
	server_started.emit()

func join_game(ip: String, port: int, password: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		push_error("Failed to create client: %s" % err)
		return
	multiplayer.multiplayer_peer = peer
	is_host = false
	# store password to send after connect
	_pending_password = password

var _pending_password: String = ""

func _on_connected_to_server() -> void:
	local_peer_id = multiplayer.get_unique_id()
	# send password to host
	rpc_id(1, "validate_password", _pending_password)
	connected_to_server.emit()

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	connection_failed.emit()

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	connection_failed.emit()

func _on_peer_connected(id: int) -> void:
	if is_host:
		connected_peers.append(id)
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	connected_peers.erase(id)
	player_disconnected.emit(id)

@rpc("any_peer", "reliable")
func validate_password(pwd: String) -> void:
	var sender = multiplayer.get_remote_sender_id()
	if pwd == host_password:
		rpc_id(sender, "password_accepted")
	else:
		rpc_id(sender, "password_rejected")

@rpc("authority", "reliable")
func password_accepted() -> void:
	lobby_joined.emit()

@rpc("authority", "reliable")
func password_rejected() -> void:
	disconnect_game()
	connection_failed.emit()

func disconnect_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_host = false
	connected_peers.clear()