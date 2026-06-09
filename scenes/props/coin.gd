extends Area2D

@export var current_env = GameControl.LevelEnvironment.OVERWORLD
@export var texture_overworld: Texture2D
@export var texture_underworld: Texture2D

@onready var sprite = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("idle")

func set_environment(env) -> void:
	current_env = env
	update_texture()

func update_texture() -> void:
	match current_env:
		GameControl.LevelEnvironment.OVERWORLD:
			sprite.texture = texture_overworld
		GameControl.LevelEnvironment.UNDERWORLD:
			sprite.texture = texture_underworld
			
func collect(player_id: int):
	set_deferred("monitoring", false)
	GameControl.add_coin(player_id)
	GameControl.play_coin_sound()
	queue_free()
			
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		collect(body.player_id)
