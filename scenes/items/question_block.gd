extends BaseBlocks

func _on_timer_timeout() -> void:
	is_empty = true
	animation_player.play("empty")
