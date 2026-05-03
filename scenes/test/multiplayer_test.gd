extends Node2D

@export var player_scene: PackedScene = preload("res://scenes/players/mario.tscn")
@export var goomba_scene: PackedScene = preload("res://scenes/enemies/goomba.tscn")

@onready var players_markers: Node2D = $Players
@onready var players_container: Node2D = $SpawnedPlayers
@onready var enemy_markers: Node2D = $Enemies
@onready var enemy_container: Node2D = $SpawnedEnemies
@onready var ms_players: MultiplayerSpawner = $MSPlayers

func _ready() -> void:
	ms_players.spawn_function = _spawn_mario
	if multiplayer.is_server():
		spawn_players()
		spawn_goombas()
		
func _process(_delta: float) -> void:
	if multiplayer.is_server() and Input.is_action_just_pressed("reset"):
		NetManager.server_request_reload()
			
func _spawn_mario(data: Dictionary) -> Node:
	var new_mario = player_scene.instantiate()
	new_mario.name = str(data.id)
	new_mario.position = data.position
	return new_mario
		
func spawn_players():
	var markers = players_markers.get_children()
	var index = 0
	
	for id in NetManager.players:
		if index >= markers.size(): break
			
		var data = {
			"id": id,
			"position": markers[index].position
		}
		ms_players.spawn(data)
		index += 1
		
func spawn_goombas():
	for marker in enemy_markers.get_children():
		if marker is Marker2D:
			var new_goomba = goomba_scene.instantiate()
			new_goomba.position = marker.global_position
			enemy_container.add_child(new_goomba, true)
