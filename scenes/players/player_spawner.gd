extends Node2D

@export var mario_scene: PackedScene
@export var spawn_points: Array[Node2D] = []

func _ready() -> void:
	if not multiplayer.is_server(): return
	
	var players = multiplayer.get_peers()
	players.append(1)
	
	for i in players.size():
		spawn_player(players[i], i)
	
@rpc("authority", "call_local", "reliable")
func spawn_player(peer_id: int, index: int) -> void:
	var mario = mario_scene.instantiate()
	mario.name = str(peer_id)
	mario.player_id = index + 1
	mario.set_multiplayer_authority(peer_id)
	
	add_child(mario)
	
	if index < spawn_points.size():
		mario.global_position = spawn_points[index].global_position
