extends Node2D

var peer = ENetMultiplayerPeer.new()
const PORT = 7000
const MAX_CLIENTS = 4

var players = {}
var my_local_name = ""

signal player_list_changed
#signal connection_failed

func create_game(player_name):
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	
	players[1] = player_name
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	player_list_changed.emit()
	
func join_game(ip, player_name):
	if ip == "": ip = "127.0.0.1"
	var error = peer.create_client(ip, PORT)
	if error != OK:
		print("Error al crear el cliente: ", error)
		return
	
	my_local_name = player_name
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(_on_connection_success)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
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
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		
	players.clear()
	
	if multiplayer.peer_connected.connect(_on_player_connected):
		multiplayer.peer_connected.disconnect(_on_player_connected)
	
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
