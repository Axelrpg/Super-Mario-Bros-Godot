extends CanvasLayer

@onready var velocity_x = $Container/VelocityX/Value
@onready var anim_speed_scale = $Container/AnimSpeedScale/Value

func _process(_delta: float) -> void:
	velocity_x.text = str(GameEvents.SPEED_X)
	anim_speed_scale.text = str(GameEvents.ANIM_SPEED_SCALE)
