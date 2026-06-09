extends BaseKoopa

@onready var edge_detector: RayCast2D = $EdgeDetector

func _physics_process(delta: float) -> void:
	if edge_detector:
		edge_detector.position.x = abs(edge_detector.position.x) * direction
		edge_detector.force_raycast_update()
		
	super(delta)

func check_walk_direction():
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if sign(wall_normal.x) != sign(direction):
			direction *= -1
	elif is_on_floor() and edge_detector and not edge_detector.is_colliding():
		direction *= -1

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		owner_player_id = body.player_id
		if current_state == State.WALK:
			current_state = State.SHELL_IDLE
			velocity = Vector2.ZERO
		elif current_state == State.SHELL_IDLE:
			GameControl.play_kick_kill_sound()
			direction = sign(global_position.x - body.global_position.x)
			if direction == 0: direction = 1
			current_state = State.SHELL_MOVING
		elif current_state == State.SHELL_MOVING:
			if body.has_method("take_damage"):
				if body.velocity.y <= 0:
					body.take_damage()
	
	elif body.is_in_group("enemies") and current_state == State.SHELL_MOVING and body != self:
		if body.has_method("die_special"):
			body.die_special(body, self.direction)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if not has_spawned:
		set_physics_process(true)
		has_spawned = true
