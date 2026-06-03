extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("idle")
	
func  _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.current_state == body.PlayerState.FIRE:
			GameControl.spawn_score(1000, global_position, body)
	else:
		if body.has_method("take_power_up"):
			body.take_power_up(body.PlayerState.FIRE)
			GameControl.spawn_score(1000, global_position, body)
			GameControl.play_power_up_sound()
		queue_free()
