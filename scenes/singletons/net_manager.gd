extends Node2D

var is_online := false

var peer = ENetMultiplayerPeer.new()
const PORT = 7000
const MAX_CLIENTS = 4

var players = {}
var my_local_name = ""
var _peers_ready_to_reload := []

signal player_list_changed
signal server_shut_down

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connection_success)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
		
func server_request_reload():
	if not multiplayer.is_server():
		return
	_peers_ready_to_reload.clear()
	notify_reload.rpc()
	
@rpc("authority", "reliable")
func notify_reload():
	confirm_ready_to_reload.rpc_id(1)
	
@rpc("any_peer", "reliable")
func confirm_ready_to_reload():
	if not multiplayer.is_server():
		return
		
	var sender = multiplayer.get_remote_sender_id()
	if sender not in _peers_ready_to_reload:
		_peers_ready_to_reload.append(sender)
		
	if _peers_ready_to_reload.size() >= multiplayer.get_peers().size():
		reload_clients.rpc()
		await get_tree().create_timer(0.2).timeout
		get_tree().reload_current_scene()
		
@rpc("authority", "reliable")
func reload_clients():
	if not multiplayer.is_server():
		get_tree().reload_current_scene()

func create_game(player_name):
	is_online = true
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	
	players[1] = player_name
	player_list_changed.emit()
	
func join_game(ip, player_name):
	is_online = true
	if ip == "": ip = "127.0.0.1"
	
	peer = ENetMultiplayerPeer.new()
	
	var error = peer.create_client(ip, PORT)
	if error != OK:
		print("Error al crear el cliente: ", error)
		return
	
	my_local_name = player_name
	multiplayer.multiplayer_peer = peer
	
@rpc("any_peer", "reliable")
func register_player(new_name):
	var id = multiplayer.get_remote_sender_id()
	if id == 0: id = 1
	players[id] = new_name
	player_list_changed.emit()
	if multiplayer.is_server():
		update_clients_list.rpc(players)
		
@rpc("authority", "reliable")
func update_clients_list(server_players):
	players = server_players
	player_list_changed.emit()
	
@rpc("any_peer", "reliable")
func receive_existing_players(existing_players):
	players = existing_players
	var my_id = multiplayer.get_unique_id()
	var my_name = players[1]
	
	players.erase(1)
	players[my_id] = my_name
	
	rpc("register_player", my_name)
	player_list_changed.emit()
	
func disconnect_game():
	is_online = false
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		
	players.clear()
	print("Desconectado con exito")
	
func _on_player_connected(id):
	print("Jugador conectado ", id)
	
func _on_player_disconnected(id):
	players.erase(id)
	update_clients_list.rpc(players)
	player_list_changed.emit()
	
func _on_connection_success():
	register_player.rpc(my_local_name)

func _on_connection_failed():
	print("No se pudo conectar")
	
func _on_server_disconnected():
	disconnect_game()
	server_shut_down.emit()
