extends BaseSuperMario

func take_damage():
	if is_invulnerable or is_dying:
		return
		
	downgrade_to_small()

func _on_stomp_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and velocity.y > 0:
		if body.has_method("die"):
			body.die()
			
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY * 0.9
		else:
			velocity.y = JUMP_VELOCITY * 0.6
