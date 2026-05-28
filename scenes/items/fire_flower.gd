extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var can_be_collected: bool = true

func _ready() -> void:
	animation_player.play("idle")
	set_physics_process(false)
	modulate.a = 0
	
	if has_method("disable_collection"):
		disable_collection(0.5)
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:y", global_position.y - 8, 1.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	await tween.finished
	if is_instance_valid(self):
		set_physics_process(true)
	
func  _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	
func disable_collection(duration: float):
	can_be_collected = false
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(duration).timeout
	can_be_collected = true

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and can_be_collected:
		if body.current_state == body.MarioState.FIRE:
			GameControl.spawn_score(1000, global_position)
		else:
			if body.has_method("take_power_up"):
				body.take_power_up(body.MarioState.FIRE)
				GameControl.spawn_score(1000, global_position)
				GameControl.play_power_up_sound()
		queue_free()
