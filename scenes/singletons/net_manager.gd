extends Node2D

func _ready() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(7777, 16)
	
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Servidor corriendo en puerto 7777")
	else:
		print("Error al iniciar servidor: ", error)
