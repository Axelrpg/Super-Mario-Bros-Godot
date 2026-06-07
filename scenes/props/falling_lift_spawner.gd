extends Node2D

@export var lift_scene: PackedScene
@export var bounds_sprite: Sprite2D
@export var go_down: bool = true

var fall_speed: float = 50.0
var spacing: float = 160

var lifts: Array = []
var bounds_top: float
var bounds_bottom: float

func _ready() -> void:
	if bounds_sprite and bounds_sprite.texture:
		var texture_size = bounds_sprite.texture.get_size() * bounds_sprite.global_scale
		bounds_top = bounds_sprite.global_position.y - texture_size.y / 2.0
		bounds_bottom = bounds_sprite.global_position.y + texture_size.y / 2.0
		
		await get_tree().process_frame
		for i in 2:
			spawn_lift(bounds_top + i * spacing)

func _physics_process(_delta: float) -> void:
	for lift in lifts:
		if go_down:
			if lift.global_position.y > bounds_bottom + 16:
				reset_lift(lift, bounds_top - 16)
		else:
			if lift.global_position.y < bounds_top - 16:
				reset_lift(lift, bounds_bottom + 16)
			
func spawn_lift(y: float):
	var lift = lift_scene.instantiate()
	lift.init(Vector2(global_position.x, y), fall_speed if go_down else -fall_speed)
	get_parent().add_child(lift)
	lifts.append(lift)
	
func reset_lift(lift: Node, new_y: float) -> void:
	lift.collision_layer = 0  # desactiva colisión
	lift.global_position.y = new_y
	await get_tree().process_frame
	lift.collision_layer = 1  # reactiva colisión
