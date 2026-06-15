extends AnimatableBody2D

@export var axis: Vector2 = Vector2.RIGHT

var move_distance: float = 80.0
var move_speed: float = 1.5
var pause_time: float = 0.5

var origin: Vector2

func _ready() -> void:
	origin = global_position
	start_loop()

func start_loop():
	while true:
		await move_to(origin + axis * move_distance)
		await get_tree().create_timer(pause_time).timeout
		await move_to(origin)
		await get_tree().create_timer(pause_time).timeout
		
func move_to(target: Vector2):
	var tween = create_tween()
	tween.tween_property(self, "global_position", target, move_speed)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
