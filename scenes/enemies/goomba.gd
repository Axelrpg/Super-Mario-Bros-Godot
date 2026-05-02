extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var SPEED = 50
var direction = -1

var is_dying = false
var has_spawned = false

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if not is_dying:
		animation_player.play("walk")
		
	if is_on_wall():
		direction *= -1
		sprite.flip_h = not sprite.flip_h
		
	velocity.x = direction * SPEED
	
	move_and_slide()

func die():
	GameControl.spawn_score(100, global_position)
	GameControl.play_stomp_swim_sound()
	is_dying = true
	set_physics_process(false)
	collision.queue_free()
	
	if animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
		
	queue_free()
	
func die_special(hit_direction: float = 1.0):
	if is_dying: return
	GameControl.spawn_score(100, global_position)
	GameControl.play_kick_kill_sound()
	
	is_dying = true
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	sprite.flip_v = true
	
	var tween = create_tween().set_parallel(true)
	var jump_height = global_position.y - 50
	var fall_depth = global_position.y + 500
	
	var x_target = global_position.x + (50 * hit_direction)
	
	var y_tween = create_tween()
	y_tween.tween_property(self, "global_position:y", jump_height, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	y_tween.tween_property(self, "global_position:y", fall_depth, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_property(self, "global_position:x", x_target, 0.9)
	tween.tween_property(sprite, "rotation_degrees", 180 * hit_direction, 0.5)

	await y_tween.finished
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dying: return
	
	if body.is_in_group("players") and velocity.y <= 0:
		if body.has_method("take_damage"):
			body.take_damage()

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if not has_spawned:
		set_physics_process(true)
		has_spawned = true
