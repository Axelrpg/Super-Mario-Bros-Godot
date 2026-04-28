extends BaseMushroom

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and can_be_collected:
		GameControl.spawn_score(1000, global_position)
		GameControl.lives += 1
		GameControl.play_1up_sound()
		queue_free()
