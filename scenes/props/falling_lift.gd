extends AnimatableBody2D

var fall_speed: float = 50.0
var start_position: Vector2

func init(pos: Vector2, speed: float):
	start_position = pos
	fall_speed = speed
	
func _ready() -> void:
	global_position = start_position

func _physics_process(delta: float) -> void:
	var motion = Vector2(0, fall_speed * delta)
	move_and_collide(motion)
