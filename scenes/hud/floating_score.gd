extends Marker2D

@onready var label: Label = $Label

func _ready() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "position:y", position.y - 30, 0.6)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	scale = Vector2(0.5, 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	tween.set_parallel(false)
	tween.finished.connect(queue_free)
	
func setup(value: int):
	label.text = str(value)
