extends CharacterBody2D
class_name BaseMario

enum PlayerState {
	SMALL,
	SUPER,
	FIRE
}
var current_state = PlayerState.SMALL

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var stomp_detector: Area2D = $StompDetector
@onready var enemy_detector: Area2D = $EnemyDetector
@onready var starman_timer: Timer = $StarmanTimer

var visual_small: Sprite2D
var visual_super: Sprite2D
var visual_fire: Sprite2D

var WALK_SPEED = 100
var RUN_SPEED = 200
var ACCELERATION = 5
var FRICTION = 15

var JUMP_VELOCITY = -400.0
var JUMP_RELEASE_FORCE = 0.5

var anim_speed_scale: float
var height_idle = 80
var height_walk = 96
var height_run = 128
var invulnerability_duration = 3
var starman_tween: Tween
var just_hit_ceiling: bool = false

var is_skidding = false
var is_dying = false
var is_super = false
var is_ceiling_blocked = false
var is_invulnerable = false
var is_starman = false
var is_manual_jumping = false

func _ready() -> void:
	visual_small = get_node_or_null("VisualSmall")
	visual_super = get_node_or_null("VisualSuper")
	visual_fire = get_node_or_null("VisualFire")

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity += get_gravity() * delta
		move_and_collide(velocity * delta)
		return
		
	set_global_variables()
	handle_movement(delta)
	move_and_slide()
	
func set_global_variables():
	GameEvents.SPEED_X = velocity.x
	GameEvents.SPEED_Y = velocity.y
	GameEvents.ANIM_SPEED_SCALE = animation_player.speed_scale
	GameEvents.CURRENT_ANIMATION = animation_player.current_animation
	GameEvents.MANUAL_JUMPING = is_manual_jumping
	
func handle_movement(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		is_manual_jumping = true
		var target_height: float
		var current_speed = abs(velocity.x)
		
		if current_speed > WALK_SPEED + 10:
			target_height = height_run
		elif current_speed > 10:
			target_height = height_walk
		else:
			target_height = height_idle
			
		velocity.y = get_jump_velocity(target_height)
		
	if velocity.y >= 0:
		is_manual_jumping = false
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_RELEASE_FORCE
		
	if is_on_ceiling() and velocity.y < 0:
		velocity.y = 0
		
	if is_on_floor() and (Input.is_action_pressed("crouch") or is_ceiling_blocked):
		update_animations_crouch()
		return
			
	var current_max_speed = WALK_SPEED
	if Input.is_action_pressed("run"):
		current_max_speed = RUN_SPEED

	var direction := Input.get_axis("left", "right")
	if direction:
		if sign(direction) != sign(velocity.x) and abs(velocity.x) > WALK_SPEED * 0.5:
			is_skidding = true
			velocity.x = move_toward(velocity.x, direction * current_max_speed, FRICTION * 0.35)
			sprite.flip_h = velocity.x > 0
		else:
			is_skidding = false
			velocity.x = move_toward(velocity.x, direction * current_max_speed, ACCELERATION)
			sprite.flip_h = direction < 0
	else:
		is_skidding = false
		velocity.x = move_toward(velocity.x, 0, FRICTION)
		
	if not is_on_floor() and is_ceiling_blocked:
		update_animations_crouch()
	else:
		update_animations(direction)
	
func update_animations(direction):
	if animation_player.current_animation == "shoot":
		return
	
	if not is_on_floor():
		if (current_state == PlayerState.SUPER or current_state == PlayerState.FIRE) and (is_ceiling_blocked or Input.is_action_pressed("crouch")):
			animation_player.play("crouch")
		else:
			animation_player.play("jump")
	elif is_skidding:
		animation_player.play("skid")
	elif direction != 0:
		animation_player.play("walk")
		var current_velocity = abs(velocity.x)
		
		if current_velocity <= WALK_SPEED:
			anim_speed_scale = remap(current_velocity, 0, WALK_SPEED, 0.8, 1.0)
		else:
			anim_speed_scale = remap(current_velocity, WALK_SPEED, RUN_SPEED, 1.0, 2.0)
		
		anim_speed_scale = min(2.0, anim_speed_scale)
		animation_player.speed_scale = anim_speed_scale
	else:
		animation_player.play("idle")
		
func update_animations_crouch():
	pass

func get_jump_velocity(h: float) -> float:
	return -sqrt(2 * get_gravity().y * h)

func take_damage():
	pass
	
func die():
	if is_dying: return
	is_dying = true
	z_index = 10
	collision_layer = 0
	collision_mask = 0
	stomp_detector.monitoring = false
	animation_player.play("die")
	velocity.y = JUMP_VELOCITY * 0.8
	velocity.x = 0
	
func upgrade_to_super():
	if current_state == PlayerState.SUPER:
		return
	
	set_physics_process(false)
	is_dying = true
	collision_layer = 0
	collision_mask = 0
	stomp_detector.monitoring = false
	
	var super_mario_scene = load("res://scenes/players/super_mario.tscn")
	var super_mario = super_mario_scene.instantiate()
	
	for i in range(8):
		sprite.visible = !sprite.visible
		visual_super.visible = !visual_super.visible
		visual_super.flip_h = sprite.flip_h
		visual_super.frame = sprite.frame
		await get_tree().create_timer(0.1).timeout
		
	super_mario.global_position = visual_super.global_position
	super_mario.velocity = velocity
	
	if is_starman:
		var time_left = starman_timer.time_left
		super_mario.become_starman(time_left)
	
	var super_sprite = super_mario.get_node("Sprite2D")
	if super_sprite:
		super_sprite.flip_h = sprite.flip_h
		super_sprite.frame = sprite.frame
	
	get_parent().add_child(super_mario)
	queue_free()
	
func upgrade_to_fire():
	if current_state == PlayerState.FIRE:
		return
	
	set_physics_process(false)
	is_dying = true
	collision_layer = 0
	collision_mask = 0
	stomp_detector.monitoring = false
	
	var fire_mario_scene = load("res://scenes/players/fire_mario.tscn")
	var fire_mario = fire_mario_scene.instantiate()
	
	for i in range(8):
		sprite.visible = !sprite.visible
		visual_fire.visible = !visual_fire.visible
		visual_fire.flip_h = sprite.flip_h
		visual_fire.frame = sprite.frame
		await get_tree().create_timer(0.1).timeout
		
	fire_mario.global_position = visual_fire.global_position
	fire_mario.velocity = velocity
	
	if is_starman:
		var time_left = starman_timer.time_left
		fire_mario.become_starman(time_left)
	
	var fire_sprite = fire_mario.get_node("Sprite2D")
	if fire_sprite:
		fire_sprite.flip_h = sprite.flip_h
	
	get_parent().add_child(fire_mario)
	queue_free()
	
func downgrade_to_small():
	set_physics_process(false)
	is_dying = true
	collision_layer = 0
	collision_mask = 0
	stomp_detector.monitoring = false
	
	var small_mario_scene = load("res://scenes/players/mario.tscn")
	var small_mario = small_mario_scene.instantiate()
	
	for i in range(8):
		sprite.visible = !sprite.visible
		visual_small.visible = !visual_small.visible
		visual_small.flip_h = sprite.flip_h
		visual_small.frame = sprite.frame
		await get_tree().create_timer(0.1).timeout
		
	small_mario.global_position = visual_small.global_position
	small_mario.velocity = velocity
	
	var small_sprite = small_mario.get_node("Sprite2D")
	if small_sprite:
		small_sprite.flip_h = sprite.flip_h
	
	get_parent().add_child(small_mario)
	
	if small_mario.has_method("start_invulnerability_cpu"):
		small_mario.start_invulnerability_cpu()
		
	queue_free()
	
func downgrade_to_super():
	set_physics_process(false)
	is_dying = true
	collision_layer = 0
	collision_mask = 0
	stomp_detector.monitoring = false
	
	var super_mario_scene = load("res://scenes/players/super_mario.tscn")
	var super_mario = super_mario_scene.instantiate()
	
	for i in range(8):
		sprite.visible = !sprite.visible
		visual_super.visible = !visual_super.visible
		visual_super.flip_h = sprite.flip_h
		visual_super.frame = sprite.frame
		await get_tree().create_timer(0.1).timeout
		
	super_mario.global_position = visual_super.global_position
	super_mario.velocity = velocity
	
	var super_sprite = super_mario.get_node("Sprite2D")
	if super_sprite:
		super_sprite.flip_h = sprite.flip_h
	
	get_parent().add_child(super_mario)
	
	if super_mario.has_method("start_invulnerability_cpu"):
		super_mario.start_invulnerability_cpu()
		
	queue_free()

func start_invulnerability_cpu():
	is_invulnerable = true
	
	var tween = create_tween().set_loops(int(invulnerability_duration / 0.2))
	tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(invulnerability_duration).timeout
	is_invulnerable = false
	sprite.modulate.a = 1.0
	
func become_starman(duration: float = 10.0):
	is_starman = true
	
	if not is_inside_tree():
		await ready
	
	start_starman_flicker()
	starman_timer.wait_time = duration
	starman_timer.start()
	
func start_starman_flicker():
	if enemy_detector:
		enemy_detector.monitoring = true
		
	if starman_tween:
		starman_tween.kill()
		
	starman_tween = create_tween().set_loops()
	var flicker_time = 0.05
	
	starman_tween.tween_property(sprite, "modulate", Color.WHITE, flicker_time)
	starman_tween.tween_property(sprite, "modulate", Color.YELLOW, flicker_time)
	starman_tween.tween_property(sprite, "modulate", Color.CYAN, flicker_time)
	starman_tween.tween_property(sprite, "modulate", Color.RED, flicker_time)
	
func end_starman_effect():
	is_starman = false
	if starman_tween:
		starman_tween.kill()
	sprite.modulate = Color.WHITE
	if enemy_detector:
		enemy_detector.monitoring = false
	
