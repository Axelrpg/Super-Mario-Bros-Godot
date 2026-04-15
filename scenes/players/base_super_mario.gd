extends BaseMario
class_name BaseSuperMario

@onready var ceiling_check: RayCast2D = $CeilingCheck

var CROUCH_FRICTION = 0.1

func _physics_process(delta: float) -> void:
	var wants_to_crouch = Input.is_action_pressed("crouch")
	is_ceiling_blocked = ceiling_check.is_colliding()
	
	if is_ceiling_blocked or (is_on_floor() and wants_to_crouch):
		crouch()
		
	super._physics_process(delta)
	
func update_animations_crouch():
	if animation_player.current_animation != "crouch":
		animation_player.play("crouch")
		
func crouch():
	if animation_player.current_animation != "crouch":
		animation_player.play("crouch")
	velocity.x = move_toward(velocity.x, 0, FRICTION * 0.4)
