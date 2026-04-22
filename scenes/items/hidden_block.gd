extends BaseBlocks

func _ready() -> void:
	is_hidden_block = true
	sprite.modulate.a = 0

func _on_timer_timeout() -> void:
	pass # Replace with function body.
