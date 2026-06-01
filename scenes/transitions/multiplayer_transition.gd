extends CanvasLayer

@onready var left = $HBoxContainer/Left
@onready var right = $HBoxContainer/Right

func fade_out(player_id: int, duration: float = 0.5):
	var color_rect = left if player_id == 1 else right
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	return tween
	
func fade_in(player_id: int, duration: float = 0.5):
	var color_rect = left if player_id == 1 else right
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	return tween
