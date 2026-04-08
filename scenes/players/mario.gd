extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var WALK_SPEED = 100
var RUN_SPEED = 200
var ACCELERATION = 10
var FRICTION = 15

var JUMP_VELOCITY = -400.0
var JUMP_RELEASE_FORCE = 0.5

var anim_speed_scale: float
var height_idle = 80
var height_walk = 96
var height_run = 128

var is_skidding = false
var is_dying = false

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity += get_gravity() * delta
		move_and_collide(velocity * delta)
		return
		
	set_global_variables()
	handle_movement(delta)
	
func set_global_variables():
	GameEvents.SPEED_X = velocity.x
	GameEvents.SPEED_Y = velocity.y
	GameEvents.ANIM_SPEED_SCALE = animation_player.speed_scale
	
func handle_movement(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta
		
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
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		var target_height: float
		var current_speed = abs(velocity.x)
		
		if current_speed > WALK_SPEED + 10:
			target_height = height_run
		elif current_speed > 10:
			target_height = height_walk
		else:
			target_height = height_idle
			
		velocity.y = get_jump_velocity(target_height)
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_RELEASE_FORCE
		
	update_animations(direction)
	move_and_slide()
	
func update_animations(direction):
	if not is_on_floor():
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

func get_jump_velocity(h: float) -> float:
	return -sqrt(2 * get_gravity().y * h)

func take_damage():
	die()
	
func die():
	if is_dying: return
	is_dying = true
	collision_layer = 0
	collision_mask = 0
	animation_player.play("die")
	velocity.y = JUMP_VELOCITY * 0.8
	velocity.x = 0

func _on_stomp_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and velocity.y > 0:
		if body.has_method("die"):
			body.die()
			
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY * 0.9
		else:
			velocity.y = JUMP_VELOCITY * 0.6
