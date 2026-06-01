extends Camera2D

@export var world_root: Node2D = null

var target_player: Node2D = null
var background_sprite: Sprite2D

func _ready() -> void:
	if world_root:
		background_sprite = world_root.get_node("Area1/Background")
	setup_camera_limits()

func _process(_delta: float) -> void:
	if target_player:
		global_position = target_player.global_position

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

func teleport_to_zone(new_pos: Vector2, limits: Dictionary):
	limit_left = limits.left
	limit_right = limits.right
	limit_top = limits.top
	limit_bottom = limits.bottom
	global_position = new_pos
	reset_smoothing()
	
	
	
	
	
