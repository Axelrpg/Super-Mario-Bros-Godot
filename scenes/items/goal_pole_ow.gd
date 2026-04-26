extends Area2D

@onready var flag_sprite: Sprite2D = $FlagSprite
@onready var arrival_point: Marker2D = $ArrivalPoint

signal level_completed

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		set_deferred("monitoring", false)
		start_victory_sequence(body)
		
func start_victory_sequence(player: CharacterBody2D):
	player.set_physics_process(false)
	
	player.global_position.x = global_position.x - 8
	# Animacion de climb
	
	var tween = create_tween()
	tween.tween_property(flag_sprite, "position:y", 64, 1.5).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(player, "global_position:y", arrival_point.global_position.y, 1.5).set_trans(Tween.TRANS_LINEAR)
	
	tween.set_parallel(false)
	tween.finished.connect(func():
		player.sprite.flip_h = true
		player.global_position.x = global_position.x + 8
		
		await get_tree().create_timer(0.5).timeout
		walk_to_the_castle(player)
		)

func walk_to_the_castle(player: CharacterBody2D):
	player.sprite.flip_h = false
	player.animation_player.play("walk")
	
	var castle_door_pos = get_tree().get_first_node_in_group("castle_door").global_position
	
	var tween = create_tween()
	tween.tween_property(player, "global_position:x", castle_door_pos.x, 2.0)
	tween.parallel().tween_property(player, "modulate:a", 0.0, 2.0).set_delay(1.5)
	
	tween.finished.connect(func():
		emit_signal("level_completed")
		show_victory_ui()
		)
		
func show_victory_ui():
	print("¡Felicidades!")
	pass
