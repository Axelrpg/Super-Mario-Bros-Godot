extends BaseBlocks

@export var texture_overworld: Texture2D
@export var texture_underworld: Texture2D
@export var texture_castle: Texture2D

var current_env = GameControl.LevelEnvironment.OVERWORLD

func set_environment(env) -> void:
	current_env = env
	update_texture()

func update_texture() -> void:
	match current_env:
		GameControl.LevelEnvironment.OVERWORLD:
			sprite.texture = texture_overworld
		GameControl.LevelEnvironment.UNDERWORLD:
			sprite.texture = texture_underworld
		GameControl.LevelEnvironment.CASTLE:
			sprite.texture = texture_castle

func _on_timer_timeout() -> void:
	is_empty = true
	animation_player.play("empty")
