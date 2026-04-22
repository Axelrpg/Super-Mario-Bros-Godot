extends CharacterBody2D
class_name BaseMushroom

var SPEED = 50
var direction = -1
var active = false

var can_be_collected: bool = true

func  _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if is_on_wall():
		direction *= -1
		
	velocity.x = direction * SPEED
	
	move_and_slide()
	
func set_direction():
	pass
	
func disable_collection(duration: float):
	can_be_collected = false
	await get_tree().create_timer(duration).timeout
	can_be_collected = true
