extends Node2D

@export var current_env = GameControl.LevelEnvironment.OVERWORLD
@export var texture_overworld: Texture2D
@export var texture_underworld: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

var velocity = Vector2.ZERO
var gravity = 1200
var rotation_speed = 10

func _ready() -> void:
	rotation = randf_range(0, TAU)
	
func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	global_position += velocity * delta
	rotation += rotation_speed * delta
	
	if global_position.y > 3000:
		queue_free()

func set_environment(env) -> void:
	current_env = env
	update_texture()

func update_texture() -> void:
	match current_env:
		GameControl.LevelEnvironment.OVERWORLD:
			sprite.texture = texture_overworld
		GameControl.LevelEnvironment.UNDERWORLD:
			sprite.texture = texture_underworld
