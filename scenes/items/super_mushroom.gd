extends BaseMushroom

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and can_be_collected:
		if body.current_state == body.PlayerState.SUPER:
			pass
		else:
			if body.has_method("upgrade_to_super"):
				body.upgrade_to_super()
			queue_free()
