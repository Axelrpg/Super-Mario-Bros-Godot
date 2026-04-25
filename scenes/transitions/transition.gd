extends CanvasLayer

@onready var color_rect = $ColorRect

func fade_out(duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	return tween
	
func fade_in(duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	return tween
