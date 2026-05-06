extends Node2D

@export var player_scene = preload("res://scenes/players/mario.tscn")

@onready var players_markers: Node2D = $Players
@onready var ms_players: MultiplayerSpawner = $MSPlayers

func _ready() -> void:
	if NetManager.is_online:
		ms_players.spawn_function = _spawn_players
		if multiplayer.is_server():
			spawn_players()
	else:
		GameControl.reset_time(300)
		GameControl.start_timer()
		GameControl.reset_level_song_pitch_scale()
		GameControl.play_level_song_music()
		GameControl.is_timer_active = true

func _process(_delta: float) -> void:
	if NetManager.is_online:
		if multiplayer.is_server() and Input.is_action_just_pressed("reset"):
			NetManager.server_request_reload()
	else:
		if Input.is_action_just_pressed("reset"):
			GameControl.reset_values(300)
			get_tree().reload_current_scene()

func _spawn_players(data: Dictionary) -> Node:
	var new_player = player_scene.instantiate()
	new_player.name = str(data.id)
	new_player.position = data.position
	return new_player
		
func spawn_players():
	var markers = players_markers.get_children()
	markers.shuffle()
	var index = 0
	
	for id in NetManager.players:
		if index >= markers.size(): break
			
		var data = {
			"id": id,
			"position": markers[index].position
		}
		ms_players.spawn(data)
		index += 1
