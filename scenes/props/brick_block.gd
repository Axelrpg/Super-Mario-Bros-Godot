extends BaseBlocks

@export var current_env = GameControl.LevelEnvironment.OVERWORLD
@export var texture_overworld: Texture2D
@export var texture_underworld: Texture2D

const DEBRIS_SCENE = preload("res://scenes/props/brick_debris.tscn")

func set_environment(env) -> void:
	current_env = env
	update_texture()

func update_texture() -> void:
	match current_env:
		GameControl.LevelEnvironment.OVERWORLD:
			sprite.texture = texture_overworld
		GameControl.LevelEnvironment.UNDERWORLD:
			sprite.texture = texture_underworld

func break_or_bump(player: CharacterBody2D):
	if player.current_state == player.PlayerState.SMALL:
		move_sprite()
		GameControl.play_bump_sound()
	else:
		check_objects_above()
		GameControl.play_brick_sound()
		break_block()
		
func break_block():
	collision_layer = 0
	collision_mask = 0
	visible = false
	queue_free()

	var debris_velocities = [
		Vector2(-100, -300),
		Vector2(100, -300),  
		Vector2(-150, -200), 
		Vector2(150, -200)   
	]
	
	for vel in debris_velocities:
		var debris = DEBRIS_SCENE.instantiate()
		debris.global_position = global_position
		debris.velocity = vel
		get_parent().add_child(debris)

func _on_timer_timeout() -> void:
	is_empty = true
	animation_player.play("empty")
