extends BaseMushroom

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and can_be_collected:
		if body.current_state == body.MarioState.SUPER:
			GameControl.spawn_score(1000, global_position)
		else:
			if body.has_method("take_power_up"):
				body.take_power_up(body.MarioState.SUPER)
				GameControl.spawn_score(1000, global_position)
				GameControl.play_power_up_sound()
			queue_free()
