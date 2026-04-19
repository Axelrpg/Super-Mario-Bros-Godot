extends BaseMario

func _ready() -> void:
	super()
	current_state = PlayerState.SMALL

func take_damage():
	if is_invulnerable or is_dying or is_starman:
		return
		
	die()

func _on_stomp_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and velocity.y > 0:
		if body.has_method("die"):
			body.die()
			
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY * 0.9
		else:
			velocity.y = JUMP_VELOCITY * 0.6

func _on_enemy_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if is_starman:
			var hit_dir = 1.0 if global_position.x < body.global_position.x else -1.0
			if body.has_method("die_special"):
				body.die_special(hit_dir)

func _on_starman_timer_timeout() -> void:
	end_starman_effect()
