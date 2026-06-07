extends CharacterBody2D
class_name BaseMushroom

var SPEED = 50
var direction = -1
var active = false

var can_be_collected: bool = true

func  _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.x = direction * SPEED
		
	velocity += get_gravity() * delta
	move_and_slide()
	
	if is_on_wall():
		direction *= -1
	
func set_direction(new_dir: int = 1):
	direction = new_dir
	
func disable_collection(duration: float):
	can_be_collected = false
	await get_tree().create_timer(duration).timeout
	can_be_collected = true
