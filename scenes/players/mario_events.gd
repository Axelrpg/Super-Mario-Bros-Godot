extends CanvasLayer

@onready var velocity_x = $Container/VelocityX/Value
@onready var anim_speed_scale = $Container/AnimSpeedScale/Value
@onready var current_animation = $Container/CurrentAnimation/Value
@onready var manual_jumping = $Container/ManualJumping/Value

func _process(_delta: float) -> void:
	velocity_x.text = str(GameEvents.SPEED_X)
	anim_speed_scale.text = str(GameEvents.ANIM_SPEED_SCALE)
	current_animation.text = GameEvents.CURRENT_ANIMATION
	manual_jumping.text = str(sign(GameEvents.SPEED_Y))
