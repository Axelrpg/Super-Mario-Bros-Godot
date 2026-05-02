extends BaseSuperMario

@onready var sfx_fireball = $Sounds/SFXFireball

var can_shoot: bool = true

func _ready() -> void:
	super()
	current_state = PlayerState.FIRE

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("run"):
		if animation_player.current_animation == "crouch":
			return
		
		shoot_fireball()
		
	super._physics_process(delta)

func shoot_fireball():
	var active_fireballs = get_tree().get_nodes_in_group("fireballs")
	
	if active_fireballs.size() < 2 and can_shoot:
		sfx_fireball.play()
		animation_player.play("shoot")
		
		var fireball_scene = preload("res://scenes/items/fire_ball.tscn")
		var fireball = fireball_scene.instantiate()
	
		fireball.direction = -1 if sprite.flip_h else 1
		fireball.global_position = global_position + Vector2(fireball.direction * 12, -8)
		get_parent().add_child(fireball)
		
		can_shoot = false
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(self):
			can_shoot = true
			
func take_damage():
	if is_invulnerable or is_dying or is_starman:
		return
		
	downgrade_to_super()

func _on_stomp_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and velocity.y > 0:
		if body.has_method("die"):
			body.die()
			
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY * 0.9
		else:
			velocity.y = JUMP_VELOCITY * 0.6

func _on_enemy_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if is_starman:
			var hit_dir = 1.0 if global_position.x < body.global_position.x else -1.0
			if body.has_method("die_special"):
				body.die_special(hit_dir)

func _on_starman_timer_timeout() -> void:
	end_starman_effect()
