extends Area2D

@onready var flag_sprite: Sprite2D = $FlagSprite
@onready var arrival_point_small: Marker2D = $ArrivalPointSmall
@onready var arrival_point_super: Marker2D = $ArrivalPointSuper
@onready var sfx_flag_pole = $SFXFlagPole

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		set_deferred("monitoring", false)
		start_victory_sequence(body)
		
func start_victory_sequence(player: CharacterBody2D):
	player.set_physics_process(false)
	GameControl.stop_timer()
	GameControl.stop_level_song_music()
	
	var height_diff = arrival_point_small.global_position.y - player.global_position.y
	var height_score = 0
	
	if height_diff > 120: height_score = 5000
	elif height_diff > 80: height_score = 2000
	elif height_diff > 40: height_score = 800
	else: height_score = 100
	
	GameControl.spawn_score(height_score, player.global_position)
	GameControl.update_ui()
	
	player.global_position.x = global_position.x - 8
	player.animation_player.play("climb")
	
	var arrival_position
	if player.current_state == player.PlayerState.SMALL:
		arrival_position = arrival_point_small.global_position.y
	else:
		arrival_position = arrival_point_super.global_position.y
	
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
		player.sprite.flip_h = true
		player.global_position.x = global_position.x + 8
		
		await get_tree().create_timer(0.5).timeout
		walk_to_the_castle(player)
		)

func walk_to_the_castle(player: CharacterBody2D):
	GameControl.play_level_complete_music()
	player.sprite.flip_h = false
	player.animation_player.play("jump")
	
	var ground_y = player.global_position.y + 16
	var landing_x = player.global_position.x + 12
	
	var castle_door_pos = get_tree().get_first_node_in_group("castle_door").global_position
	
	var tween = create_tween()
	
	tween.tween_property(player, "global_position", Vector2(landing_x, ground_y), 0.3)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
		
	tween.tween_callback(func(): player.animation_player.play("walk"))
	
	tween.tween_property(player, "global_position:x", castle_door_pos.x, 1)
	tween.parallel().tween_property(player, "modulate:a", 0.0, 1.5).set_delay(1)
	
	tween.finished.connect(func():
		drain_time_bonus()
		)
		
func drain_time_bonus():
	while GameControl.time_left > 0:
		var reduction = min(GameControl.time_left, 2.0)
		GameControl.time_left -= reduction
		GameControl.total_score += 50 * reduction
		GameControl.update_ui()
		
		await get_tree().create_timer(0.01).timeout
	
	show_victory_ui()
		
func show_victory_ui():
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://scenes/levels/singleplayer/thank_you_screen.tscn")
