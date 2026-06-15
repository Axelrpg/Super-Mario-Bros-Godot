extends CharacterBody2D

@export var texture_overworld: Texture2D
@export var texture_underworld: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var screen_notifier = $VisibleOnScreenNotifier2D

var current_env = GameControl.LevelEnvironment.OVERWORLD
var speed = 50
var is_dying = false
var has_spawned = false
var deactivate_timer: SceneTreeTimer = null
var direction = -1

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if not is_dying:
		animation_player.play("walk")
		
	velocity.x = direction * speed
	move_and_slide()
	
	if is_on_wall():
		var wall_collision = get_last_slide_collision()
		if wall_collision:
			var collider = wall_collision.get_collider()
			if not collider.is_in_group("enemies"):
				direction *= -1
				sprite.flip_h = not sprite.flip_h
	
func set_environment(env) -> void:
	current_env = env
	update_texture()

func update_texture() -> void:
	match current_env:
		GameControl.LevelEnvironment.OVERWORLD:
			sprite.texture = texture_overworld
		GameControl.LevelEnvironment.UNDERWORLD:
			sprite.texture = texture_underworld

func die(player: Node2D = null):
	if is_dying: return
	is_dying = true
	
	GameControl.spawn_score(100, global_position, player)
	GameControl.play_stomp_swim_sound()
	set_physics_process(false)
	collision.queue_free()
	hitbox.monitoring = false
	hurtbox.monitoring = false
	
	if animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
		
	queue_free()
	
func die_special(body: Node2D, hit_direction: float = 1.0):
	if is_dying: return
	GameControl.spawn_score(100, global_position, body)
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

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var enemy = area.get_parent()
		if enemy != self and enemy != null:
			direction *= -1
			sprite.flip_h = not sprite.flip_h

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if is_dying: return
	
	if body.is_in_group("players") and body.velocity.y <= 0:
		if body.has_method("take_damage"):
			body.take_damage()

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if deactivate_timer:
		deactivate_timer = null
	
	if not has_spawned:
		has_spawned = true
			
	set_physics_process(true)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if not has_spawned: return
	
	deactivate_timer = get_tree().create_timer(3.0)
	await deactivate_timer.timeout
	
	if not screen_notifier.is_on_screen():
		set_physics_process(false)
