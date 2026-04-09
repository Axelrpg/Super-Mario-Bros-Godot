extends CharacterBody2D

var SPEED = 50
var direction = -1

func  _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if is_on_wall():
		direction *= -1
		
	velocity.x = direction * SPEED
	
	move_and_slide()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		if body.has_method("upgrade_to_super"):
			body.upgrade_to_super()
		queue_free()
