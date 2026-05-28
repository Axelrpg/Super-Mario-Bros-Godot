extends CharacterBody2D

enum MarioState {
	SMALL,
	SUPER,
	FIRE
}

enum MoveState {
	CLIMB,
	CROUCH,
	DIE,
	IDLE,
	JUMP,
	SHOOT,
	SKID,
	WALK
}

@export var current_state: MarioState = MarioState.SMALL
@export var move_state: MoveState = MoveState.IDLE
@export var facing_right: bool = true
@export var player_index: int = 0

@onready var small_sprite: Sprite2D = $Sprites/SmallMario
@onready var super_sprite: Sprite2D = $Sprites/SuperMario
@onready var fire_sprite: Sprite2D = $Sprites/FireMario

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var stomp_detector: Area2D = $StompDetector
@onready var enemy_detector: Area2D = $EnemyDetector
@onready var starman_timer: Timer = $StarmanTimer
@onready var ceiling_check: RayCast2D = $CeilingCheck
@onready var name_label: Node2D = $NameLabel
@onready var player_name_label: Label = $NameLabel/PlayerNameLabel

# Sounds
@onready var sfx_jump_small: AudioStreamPlayer = $Sounds/SFXJumpSmall
@onready var sfx_jump: AudioStreamPlayer = $Sounds/SFXJump
@onready var sfx_power_down: AudioStreamPlayer = $Sounds/SFXPowerDown
@onready var sfx_death: AudioStreamPlayer = $Sounds/SFXDeath
@onready var sfx_fireball = $Sounds/SFXFireball

var current_sprite: Sprite2D:
	get:
		match current_state:
			MarioState.SMALL: return small_sprite
			MarioState.SUPER: return super_sprite
			MarioState.FIRE: return fire_sprite
			_: return small_sprite

const STATE_LIBRARY = {
	MarioState.SMALL: "small",
	MarioState.SUPER: "super",
	MarioState.FIRE: "fire"
}

const ANIM_TABLE = {
	MarioState.SMALL: {
		MoveState.CLIMB: "climb",
		MoveState.CROUCH: "idle",
		MoveState.DIE: "die",
		MoveState.IDLE: "idle",
		MoveState.JUMP: "jump",
		MoveState.SKID: "skid",
		MoveState.WALK: "walk"
	},
	MarioState.SUPER: {
		MoveState.CLIMB: "climb",
		MoveState.CROUCH: "crouch",
		MoveState.DIE: "die",
		MoveState.IDLE: "idle",
		MoveState.JUMP: "jump",
		MoveState.SKID: "skid",
		MoveState.WALK: "walk"
	},
	MarioState.FIRE: {
		MoveState.CLIMB: "climb",
		MoveState.CROUCH: "crouch",
		MoveState.DIE: "die",
		MoveState.IDLE: "idle",
		MoveState.JUMP: "jump",
		MoveState.SHOOT: "shoot",
		MoveState.SKID: "skid",
		MoveState.WALK: "walk"
	}
}

const PALETTE_MARIO = {
	"new_shirt": Color("6b6d00"),
	"new_hair":  Color("b53120"),
	"new_skin":  Color("ea9e22"),
}

const PALETTE_LUIGI = {
	"new_shirt": Color("388700"),
	"new_hair":  Color("fffeff"),  
	"new_skin":  Color("ea9e22"),
}

var _last_move_state = -1
var _last_mario_state = -1
var _last_facing: bool = true

var original_layer: int
var original_mask: int

var WALK_SPEED = 100
var RUN_SPEED = 150
var ACCELERATION = 2.5
var FRICTION = 15

var JUMP_VELOCITY = -400.0
var JUMP_RELEASE_FORCE = 0.5

var anim_speed_scale: float
var height_idle = 64
var height_walk = 64
var height_run = 80
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

var can_shoot = true

var is_online = false

func _enter_tree() -> void:
	if multiplayer.has_multiplayer_peer():
		var player_id = name.to_int()
		set_multiplayer_authority(player_id)

func _ready() -> void:
	original_layer = collision_layer
	original_mask = collision_mask
	
	is_online = NetManager.is_online
	
	if not is_online:
		name_label.visible = false
		_apply_palette(PALETTE_MARIO)
		return
		
	var player_id = name.to_int()
	if is_multiplayer_authority():
		name_label.visible = false
	else:
		var player_name = NetManager.players.get(player_id, "Player")
		player_name_label.text = player_name
		name_label.visible = true
		name_label.position = Vector2(0, -16)
		
	if player_id == 1:
		_apply_palette(PALETTE_MARIO)
	else:
		_apply_palette(PALETTE_LUIGI)

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority() or is_online == false:
		if is_dying:
			velocity += get_gravity() * delta
			move_and_collide(velocity * delta)
			return
		
		set_global_variables()
		handle_movement(delta)
		move_and_slide()
		
	_update_visuals()
	
func set_global_variables():
	GameEvents.SPEED_X = velocity.x
	GameEvents.SPEED_Y = velocity.y
	GameEvents.ANIM_SPEED_SCALE = animation_player.speed_scale
	GameEvents.CURRENT_ANIMATION = animation_player.current_animation
	GameEvents.MANUAL_JUMPING = is_manual_jumping
	
func _apply_palette(palette: Dictionary) -> void:
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://shaders/palette_swap.gdshader")
	for param in palette:
		mat.set_shader_parameter(param, palette[param])
	
	for sprite in $Sprites.get_children():
		if sprite is Sprite2D:
			sprite.material = mat
	
func handle_movement(delta: float) -> void:
	handle_gravity(delta)
	handle_jump()
	handle_crouch_or_move()
	handle_fireball()

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		is_manual_jumping = true
		velocity.y = get_jump_velocity(get_target_jump_height())
		
		if current_state == MarioState.SMALL:
			sfx_jump_small.play()
		else:
			sfx_jump.play()

	if velocity.y >= 0:
		is_manual_jumping = false

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_RELEASE_FORCE

	if is_on_ceiling() and velocity.y < 0:
		velocity.y = 0

func get_target_jump_height() -> float:
	var current_speed = abs(velocity.x)
	if current_speed > WALK_SPEED + 10:
		return height_run
	elif current_speed > 10:
		return height_walk
	return height_idle

func handle_crouch_or_move() -> void:
	is_ceiling_blocked = ceiling_check.is_colliding()
	
	var is_crouching = current_state != MarioState.SMALL \
		and is_on_floor() \
		and (Input.is_action_pressed("crouch") or is_ceiling_blocked)

	if is_crouching:
		var direction := Input.get_axis("left", "right")
		if is_ceiling_blocked and direction != 0 and velocity.y < 0:
			var escape_speed = (WALK_SPEED / 4.0) * direction
			velocity.x = escape_speed
			current_sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * 0.35)
		update_move_state_crouch()
		return

	handle_horizontal_movement()
	if not is_on_floor() and is_ceiling_blocked:
		update_move_state_crouch()
	else:
		update_move_state(Input.get_axis("left", "right"))

func handle_horizontal_movement() -> void:
	var is_crouching = Input.is_action_pressed("crouch")
	var can_run = Input.is_action_pressed("run") and not is_crouching
	var current_max_speed = RUN_SPEED if can_run else WALK_SPEED
	var direction := Input.get_axis("left", "right")

	if direction:
		if sign(direction) != sign(velocity.x) and abs(velocity.x) > WALK_SPEED * 0.5:
			is_skidding = true
			velocity.x = move_toward(velocity.x, direction * current_max_speed, FRICTION * 0.35)
			facing_right = velocity.x < 0
		else:
			is_skidding = false
			velocity.x = move_toward(velocity.x, direction * current_max_speed, ACCELERATION)
			facing_right = direction > 0
	else:
		is_skidding = false
		velocity.x = move_toward(velocity.x, 0, FRICTION)

func handle_fireball() -> void:
	if Input.is_action_just_pressed("run") and current_state == MarioState.FIRE:
		if animation_player.current_animation != "crouch":
			shoot_fireball()
		
func play_anim(anim_name: String):
	var library = STATE_LIBRARY[current_state]
	animation_player.play(library + "/" + anim_name)

func update_move_state(direction: float) -> void:
	if not is_on_floor():
		if current_state != MarioState.SMALL and (is_ceiling_blocked or Input.is_action_pressed("crouch")):
			move_state = MoveState.CROUCH
		else:
			move_state = MoveState.JUMP
		return

	if is_skidding:
		move_state = MoveState.SKID
		return

	if Input.is_action_pressed("crouch") or is_ceiling_blocked:
		if current_state == MarioState.SMALL:
			move_state = MoveState.WALK if direction != 0 else MoveState.IDLE
		else:
			move_state = MoveState.CROUCH
		return

	if direction != 0:
		move_state = MoveState.WALK
	else:
		move_state = MoveState.IDLE

func update_move_state_crouch() -> void:
	if current_state == MarioState.SMALL:
		move_state = MoveState.IDLE
	else:
		move_state = MoveState.CROUCH
		
func _update_visuals() -> void:
	if move_state != _last_move_state or current_state != _last_mario_state:
		if animation_player.current_animation != "fire/shoot":
			
			if not ANIM_TABLE.has(current_state):
				push_error("ANIM_TABLE no tiene entrada para current_state: %d" % current_state)
				return
				
			if not ANIM_TABLE[current_state].has(move_state):
				push_error("ANIM_TABLE[%d] no tiene entrada para move_state: %d" % [current_state, move_state])
				return
			
			var anim_name = ANIM_TABLE[current_state][move_state]
			play_anim(anim_name)
			
			if move_state != MoveState.WALK:
				animation_player.speed_scale = 1.0
				
		_last_mario_state = move_state
		_last_mario_state = current_state
			
	if move_state == MoveState.WALK:
		var spd = abs(velocity.x)
		animation_player.speed_scale = min(2.0,
			remap(spd, 0, WALK_SPEED, 0.8, 1.0) if spd <= WALK_SPEED
			else remap(spd, WALK_SPEED, RUN_SPEED, 1.0, 2.0))

	if facing_right != _last_facing:
		current_sprite.flip_h = not facing_right
		_last_facing = facing_right

func get_jump_velocity(h: float) -> float:
	return -sqrt(2 * get_gravity().y * h)
	
func shoot_fireball():
	var active_fireballs = get_tree().get_nodes_in_group("fireballs")
	
	if active_fireballs.size() < 2 and can_shoot:
		sfx_fireball.play()
		play_anim("shoot")
		
		var fireball_scene = preload("res://scenes/items/fire_ball.tscn")
		var fireball = fireball_scene.instantiate()
	
		fireball.direction = -1 if current_sprite.flip_h else 1
		fireball.global_position = global_position + Vector2(fireball.direction * 12, -8)
		get_parent().add_child(fireball)
		
		can_shoot = false
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(self):
			can_shoot = true
	
func take_power_up(new_state: MarioState):
	name_label.position = Vector2(0, -32)
	match new_state:
		MarioState.SUPER:
			if current_state == MarioState.FIRE:
				return
			call_deferred("change_state", MarioState.SUPER)
		MarioState.FIRE:
			call_deferred("change_state", MarioState.FIRE)

func take_damage():
	match current_state:
		MarioState.SMALL:
			die()
		MarioState.SUPER:
			sfx_power_down.play()
			name_label.position = Vector2(0, -16)
			call_deferred("change_state", MarioState.SMALL, true)
		MarioState.FIRE:
			sfx_power_down.play()
			call_deferred("change_state", MarioState.SUPER, true)
	
func die():
	if is_dying: return
	sfx_death.play()
	is_dying = true
	z_index = 10
	collision_layer = 0
	collision_mask = 0
	stomp_detector.monitoring = false
	play_anim("die")
	velocity.y = JUMP_VELOCITY * 0.8
	velocity.x = 0
	GameControl.stop_timer()
	GameControl.stop_level_song_music()
	
	await get_tree().create_timer(3.0).timeout
	GameControl.reload_level()
	
func change_state(new_state: MarioState, invulnerable: bool = false) -> void:
	if current_state == new_state:
		return
	
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	stomp_detector.monitoring = false
	animation_player.stop()
	
	var next_sprite
	match new_state:
		MarioState.SMALL:
			next_sprite = small_sprite
		MarioState.SUPER:
			next_sprite = super_sprite
		MarioState.FIRE:
			next_sprite = fire_sprite

	next_sprite.flip_h = current_sprite.flip_h
	next_sprite.frame  = current_sprite.frame
	for i in range(8):
		current_sprite.visible = !current_sprite.visible
		next_sprite.visible    = !next_sprite.visible
		await get_tree().create_timer(0.1).timeout
	
	current_state = new_state
	collision_layer = original_layer
	collision_mask  = original_mask
	stomp_detector.monitoring = true
	set_physics_process(true)
	if invulnerable:
		start_invulnerability_cpu()

func start_invulnerability_cpu():
	is_invulnerable = true
	
	var tween = create_tween().set_loops(int(invulnerability_duration / 0.2))
	tween.tween_property(current_sprite, "modulate:a", 0.0, 0.1)
	tween.tween_property(current_sprite, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(invulnerability_duration).timeout
	is_invulnerable = false
	current_sprite.modulate.a = 1.0
	
func become_starman(duration: float = 10.0):
	is_starman = true
	GameControl.play_starman_music()
	
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
	
	starman_tween.tween_property(current_sprite, "modulate", Color.WHITE, flicker_time)
	starman_tween.tween_property(current_sprite, "modulate", Color.YELLOW, flicker_time)
	starman_tween.tween_property(current_sprite, "modulate", Color.CYAN, flicker_time)
	starman_tween.tween_property(current_sprite, "modulate", Color.RED, flicker_time)
	
func end_starman_effect():
	is_starman = false
	GameControl.stop_starman_music()
	if starman_tween:
		starman_tween.kill()
	current_sprite.modulate = Color.WHITE
	if enemy_detector:
		enemy_detector.monitoring = false

func _on_stomp_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and velocity.y > 0:
		if body.has_method("die"):
			var attacker_id = multiplayer.get_unique_id() if NetManager.is_online else 0
			body.die(attacker_id)
			
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
