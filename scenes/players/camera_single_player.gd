extends Camera2D

@onready var background_sprite: Sprite2D = $"../Background"

func _ready() -> void:
	setup_camera_limits()

func _process(_delta: float) -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		var target = players[0]
		global_position = target.global_position

func setup_camera_limits():
	if background_sprite and background_sprite.texture:
		var texture_size = background_sprite.texture.get_size()
		var sprite_scale = background_sprite.global_scale
		
		var width = texture_size.x * sprite_scale.x
		var height = texture_size.y * sprite_scale.y
		
		limit_left = int(background_sprite.global_position.x - (width / 2))
		limit_right = int(background_sprite.global_position.x + (width / 2))
		limit_top = int(background_sprite.global_position.y - (height / 2))
		limit_bottom = int(background_sprite.global_position.y + (height / 2))
		
