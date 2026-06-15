extends Area2D

var current_env = GameControl.LevelEnvironment.OVERWORLD
@export var texture_overworld: Texture2D
@export var texture_underworld: Texture2D

@export var next_level_scene: PackedScene

@onready var flag_sprite: Sprite2D = $FlagSprite
@onready var arrival_point_small: Marker2D = $ArrivalPointSmall
@onready var sfx_flag_pole = $SFXFlagPole

var victory_started: bool = false
var first_player_at_flag: CharacterBody2D = null
var players_at_flag: Array = []
var waiting_players: Array = []

func set_environment(env) -> void:
	current_env = env
	update_texture()

func update_texture() -> void:
	match current_env:
		GameControl.LevelEnvironment.OVERWORLD:
			flag_sprite.texture = texture_overworld
		GameControl.LevelEnvironment.UNDERWORLD:
			flag_sprite.texture = texture_underworld

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		start_victory_sequence(body)
		
func start_victory_sequence(player: CharacterBody2D):
	player.set_physics_process(false)
	GameControl.stop_timer()
	
	var height_diff = arrival_point_small.global_position.y - player.global_position.y
	var height_score = 0
	
	if height_diff > 120: height_score = 5000
	elif height_diff > 80: height_score = 2000
	elif height_diff > 40: height_score = 800
	else: height_score = 100
	
	if GameControl.is_multiplayer:
		if first_player_at_flag == null:
			first_player_at_flag = player
			height_score += 1000
			
		GameControl.spawn_score(height_score, player.global_position, player)
	else:
		GameControl.spawn_score(height_score, player.global_position, player)
		
	GameControl.update_ui()
	
	player.global_position.x = global_position.x - 8
	player.play_anim("climb")
	
	if GameControl.is_multiplayer:
		players_at_flag.append(player)
		var all_players = get_tree().get_nodes_in_group("players")
		
		if players_at_flag.size() >= all_players.size():
			for waiting in waiting_players:
				run_flag_descent(waiting)
			waiting_players.clear()
			run_flag_descent(player)
		else:
			waiting_players.append(player)
			var timer = get_tree().create_timer(10.0)
			
			while timer.time_left > 0 and not victory_started:
				await get_tree().process_frame
			
			if player in waiting_players:
				waiting_players.erase(player)
				victory_started = true
				for p in all_players:
					if p not in players_at_flag:
						if not p.is_dying:
							p.set_physics_process(false)
							p.velocity = Vector2.ZERO
							p.play_anim("die")
				run_flag_descent(player)
	else:
		run_flag_descent(player)
	
func run_flag_descent(player: CharacterBody2D):
	GameControl.stop_level_song_music()
	var arrival_position = arrival_point_small.global_position.y
	var descent_speed = 75
	
	var mario_distance = abs(arrival_position - player.global_position.y)
	var mario_duration = mario_distance / descent_speed
	
	var flag_distance = abs(64 - flag_sprite.position.y)
	var flag_duration = flag_distance / descent_speed
	
	var tween = create_tween()
	sfx_flag_pole.play()
	tween.tween_property(flag_sprite, "position:y", 64, flag_duration).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property(player, "global_position:y", arrival_position, mario_duration).set_trans(Tween.TRANS_LINEAR)
	
	tween.set_parallel(false)
	tween.finished.connect(func():
		player.current_sprite.flip_h = true
		player.global_position.x = global_position.x + 8
		
		await get_tree().create_timer(0.5).timeout
		walk_to_the_castle(player)
		)

func walk_to_the_castle(player: CharacterBody2D):
	GameControl.play_level_complete_music()
	player.current_sprite.flip_h = false
	player.play_anim("jump")
	
	var ground_y = player.global_position.y + 16
	var landing_x = player.global_position.x + 12
	
	var castle_door_pos = get_tree().get_first_node_in_group("castle_door").global_position
	
	var tween = create_tween()
	
	tween.tween_property(player, "global_position", Vector2(landing_x, ground_y), 0.3)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
		
	tween.tween_callback(func(): player.play_anim("walk"))
	
	tween.tween_property(player, "global_position:x", castle_door_pos.x, 1)
	tween.parallel().tween_property(player, "modulate:a", 0.0, 1.5).set_delay(1)
	
	tween.finished.connect(func():
		drain_time_bonus()
		)
		
func drain_time_bonus():
	var players_reached = players_at_flag
	
	while GameControl.time_left > 0:
		var reduction = min(GameControl.time_left, 2.0)
		GameControl.time_left -= reduction
		
		if GameControl.is_multiplayer:
			for p in players_reached:
				GameControl.add_score(int(50 * reduction), p.player_id)
		else:
			GameControl.total_score += 50 * reduction
		
		GameControl.update_ui()
		await get_tree().create_timer(0.01).timeout
	
	show_victory_ui()
		
func show_victory_ui():
	await get_tree().create_timer(5).timeout
	
	for p in get_tree().get_nodes_in_group("players"):
		GameControl.save_player_state(p)
	
	GameControl.next_level_scene = next_level_scene
	GameControl.advance_level()
	get_tree().change_scene_to_file("res://scenes/levels/singleplayer/level_intro.tscn")
