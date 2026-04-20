extends Node2D

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
