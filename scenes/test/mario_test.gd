extends Node2D

@export var mario_scene: PackedScene

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var players: Node2D = $Players
@onready var marker: Marker2D = $Marker2D

var ready_peers: Array = []

func _ready() -> void:
	spawner.spawn_function = spawn_mario_custom
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		notify_ready(1)
	else:
		notify_ready.rpc_id(1, multiplayer.get_unique_id())
		
@rpc("any_peer", "reliable")
func notify_ready(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
		
	if peer_id not in ready_peers:
		ready_peers.append(peer_id)
		
	if ready_peers.size() == NetManager.players.size():
		spawn_all_players()
	
func spawn_all_players() -> void:
	for id in NetManager.players:
		spawn_mario(id)
		
func spawn_mario(peer_id: int) -> void:
	var data = {
		"peer_id": peer_id,
		"position": marker.global_position
	}
	spawner.spawn(data)
	
func spawn_mario_custom(data: Dictionary) -> Node:
	var mario = mario_scene.instantiate()
	mario.name = str(data["peer_id"])
	mario.position = data["position"]
	return mario

func _on_peer_disconnected(id: int) -> void:
	var mario = players.get_node_or_null(str(id))
	if mario:
		mario.queue_free()
