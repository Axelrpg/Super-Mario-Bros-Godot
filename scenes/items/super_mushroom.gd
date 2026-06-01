extends BaseMushroom

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and can_be_collected:
		if body.current_state == body.PlayerState.SUPER:
			GameControl.spawn_score(1000, global_position, body)
		else:
			if body.has_method("take_power_up"):
				body.take_power_up(body.PlayerState.SUPER)
				GameControl.spawn_score(1000, global_position, body)
				GameControl.play_power_up_sound()
			queue_free()
