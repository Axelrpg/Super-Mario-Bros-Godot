extends BaseMushroom

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and can_be_collected:
		var player := body as Player
		if player.current_state == Player.PlayerState.SUPER:
			GameControl.spawn_score(1000, global_position, player)
		else:
			player.take_power_up(Player.PlayerState.SUPER)
			GameControl.spawn_score(1000, global_position, player)
				GameControl.play_power_up_sound()
			queue_free()
