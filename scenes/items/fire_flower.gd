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
			GameControl.spawn_score(1000, global_position)
	else:
		if body.has_method("upgrade_to_super"):
			body.upgrade_to_fire()
			GameControl.spawn_score(1000, global_position)
		queue_free()
