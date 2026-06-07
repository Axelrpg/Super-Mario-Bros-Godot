extends BasePipe

@export var current_env = GameControl.LevelEnvironment.OVERWORLD
@export var texture_overworld: Texture2D
@export var texture_underworld: Texture2D

@export var has_piranha: bool = false

@onready var sprite = $Sprite2D
@onready var piranha = $PiranhaPlant

func _ready() -> void:
	piranha.visible = has_piranha
	piranha.monitoring = not has_piranha
	piranha.monitorable = not has_piranha

func set_environment(env) -> void:
	current_env = env
	update_texture()

func update_texture() -> void:
	match current_env:
		GameControl.LevelEnvironment.OVERWORLD:
			sprite.texture = texture_overworld
		GameControl.LevelEnvironment.UNDERWORLD:
			sprite.texture = texture_underworld
