extends Node2D

const port: int = 7777

var max_players: int = 4
var players: Dictionary = {}
var my_name: String = "Player"
var is_multiplayer_online: bool = false

signal player_list_changed
signal game_started

func host_game() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port, max_players)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	players[1] = {
		"name": my_name,
		"ready": false
	}
	player_list_changed.emit()
	is_multiplayer_online = true
	
func join_game(address: String = "127.0.0.1") -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	is_multiplayer_online = true
	
func disconnect_from_game() -> void:
	players.clear()
	multiplayer.multiplayer_peer = null
	
func _on_peer_disconnected(id: int) -> void:
	players.erase(id)
	player_list_changed.emit()
	
func _on_connected_to_server() -> void:
	var my_id = multiplayer.get_unique_id()
	register_player.rpc_id(1, my_id, my_name)
	
func _on_connection_failed() -> void:
	push_error("Conexion fallida")
	multiplayer.multiplayer_peer = null
	
@rpc("any_peer", "reliable")
func register_player(id: int, player_name: String) -> void:
	if not multiplayer.is_server(): return
	players[id] = {
		"name": player_name,
		"ready": false
	}
	sync_player_list.rpc(players)
	apply_player_list(players)
	
@rpc("authority", "reliable")
func sync_player_list(list: Dictionary) -> void:
	apply_player_list(list)
	
func apply_player_list(list: Dictionary) -> void:
	players = list
	player_list_changed.emit()
	
@rpc("authority", "reliable")
func start_game_rpc() -> void:
	game_started.emit()
	get_tree().change_scene_to_file("res://scenes/test/mario_test.tscn")
	
func start_game() -> void:
	if not multiplayer.is_server(): return
	start_game_rpc.rpc()
	get_tree().change_scene_to_file("res://scenes/test/mario_test.tscn")
	
