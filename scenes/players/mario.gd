extends CharacterBody2D

enum PlayerState {
	SMALL,
	SUPER,
	FIRE
}
var current_state = PlayerState.SMALL

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

@export var player_id: int = 1

@onready var small_sprite: Sprite2D = $Sprites/SmallMario
@onready var super_sprite: Sprite2D = $Sprites/SuperMario
@onready var fire_sprite: Sprite2D = $Sprites/FireMario

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var stomp_detector: Area2D = $StompDetector
@onready var enemy_detector: Area2D = $EnemyDetector
@onready var starman_timer: Timer = $StarmanTimer
@onready var ceiling_check: RayCast2D = $CeilingCheck

# Sounds
@onready var sfx_jump_small: AudioStreamPlayer = $Sounds/SFXJumpSmall
@onready var sfx_jump: AudioStreamPlayer = $Sounds/SFXJump
@onready var sfx_power_down: AudioStreamPlayer = $Sounds/SFXPowerDown
@onready var sfx_death: AudioStreamPlayer = $Sounds/SFXDeath
@onready var sfx_fireball = $Sounds/SFXFireball

var current_sprite: Sprite2D:
	get:
		match current_state:
			PlayerState.SMALL: return small_sprite
			PlayerState.SUPER: return super_sprite
			PlayerState.FIRE: return fire_sprite
			_: return small_sprite

const STATE_LIBRARY = {
	PlayerState.SMALL: "small",
	PlayerState.SUPER: "super",
	PlayerState.FIRE: "fire"
}

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

func _ready() -> void:
	original_layer = collision_layer
	original_mask = collision_mask
	
	if player_id == 2:
		apply_palette(PALETTE_LUIGI)

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
	
func apply_palette(palette: Dictionary):
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://shaders/palette_swap.gdshader")
	for param in palette:
		mat.set_shader_parameter(param, palette[param])
		
	small_sprite.material = mat
	super_sprite.material = mat
	
func handle_movement(delta: float) -> void:
	handle_gravity(delta)
	handle_jump()
	handle_crouch_or_move()
	handle_fireball()

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func handle_jump() -> void:
	if Input.is_action_just_pressed("p%d_jump" % player_id) and is_on_floor():
		is_manual_jumping = true
		velocity.y = get_jump_velocity(get_target_jump_height())
		
		if current_state == PlayerState.SMALL:
			sfx_jump_small.play()
		else:
			sfx_jump.play()

	if velocity.y >= 0:
		is_manual_jumping = false

	if Input.is_action_just_released("p%d_jump" % player_id) and velocity.y < 0:
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
	
	var is_crouching = current_state != PlayerState.SMALL \
		and is_on_floor() \
		and (Input.is_action_pressed("p%d_down" % player_id) or is_ceiling_blocked)

	if is_crouching:
		var direction := Input.get_axis("p%d_left" % player_id, "p%d_right" % player_id)
		if is_ceiling_blocked and direction != 0 and velocity.y < 0:
			var escape_speed = (WALK_SPEED / 4.0) * direction
			velocity.x = escape_speed
			current_sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * 0.35)
		update_animations_crouch()
		return

	handle_horizontal_movement()

	if not is_on_floor() and is_ceiling_blocked:
		update_animations_crouch()
	else:
		update_animations(Input.get_axis("p%d_left" % player_id, "p%d_right" % player_id))

func handle_horizontal_movement() -> void:
	var is_crouching = Input.is_action_pressed("p%d_down" % player_id)
	var can_run = Input.is_action_pressed("p%d_run" % player_id) and not is_crouching
	var current_max_speed = RUN_SPEED if can_run else WALK_SPEED
	var direction := Input.get_axis("p%d_left" % player_id, "p%d_right" % player_id)

	if direction:
		if sign(direction) != sign(velocity.x) and abs(velocity.x) > WALK_SPEED * 0.5:
			is_skidding = true
			velocity.x = move_toward(velocity.x, direction * current_max_speed, FRICTION * 0.35)
			current_sprite.flip_h = velocity.x > 0
		else:
			is_skidding = false
			velocity.x = move_toward(velocity.x, direction * current_max_speed, ACCELERATION)
			current_sprite.flip_h = direction < 0
	else:
		is_skidding = false
		velocity.x = move_toward(velocity.x, 0, FRICTION)

func handle_fireball() -> void:
	if Input.is_action_just_pressed("p%d_run" % player_id) and current_state == PlayerState.FIRE:
		if animation_player.current_animation != "crouch":
			shoot_fireball()
			
func play_anim(anim_name: String):
	var library = STATE_LIBRARY[current_state]
	animation_player.play(library + "/" + anim_name)

func update_animations(direction: float) -> void:
	if animation_player.current_animation == "fire/shoot":
		return

	if not is_on_floor():
		if current_state != PlayerState.SMALL and (is_ceiling_blocked or Input.is_action_pressed("p%d_down" % player_id)):
			play_anim("crouch")
		else:
			play_anim("jump")
		return

	if Input.is_action_pressed("p%d_down" % player_id) or is_ceiling_blocked:
		if current_state == PlayerState.SMALL:
			if direction != 0:
				play_anim("walk")
			else:
				play_anim("idle")
		else:
			play_anim("crouch")
	elif is_skidding:
		play_anim("skid")
	elif direction != 0:
		play_anim("walk")
		var current_velocity = abs(velocity.x)
		anim_speed_scale = remap(current_velocity, 0, WALK_SPEED, 0.8, 1.0) \
			if current_velocity <= WALK_SPEED \
			else remap(current_velocity, WALK_SPEED, RUN_SPEED, 1.0, 2.0)
		animation_player.speed_scale = min(2.0, anim_speed_scale)
	else:
		play_anim("idle")
		
func update_animations_crouch() -> void:
	if current_state == PlayerState.SMALL:
		play_anim("idle")
	else:
		play_anim("crouch")

func get_jump_velocity(h: float) -> float:
	return -sqrt(2 * get_gravity().y * h)
	
func shoot_fireball():
	var active_fireballs = get_tree().get_nodes_in_group("fireballs")
	
	if active_fireballs.size() < 2 and can_shoot:
		sfx_fireball.play()
		play_anim("shoot")
		
		var fireball_scene = preload("res://scenes/players/fire_ball.tscn")
		var fireball = fireball_scene.instantiate()
	
		fireball.direction = -1 if current_sprite.flip_h else 1
		fireball.global_position = global_position + Vector2(fireball.direction * 12, -8)
		get_parent().add_child(fireball)
		
		can_shoot = false
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(self):
			can_shoot = true
	
func take_power_up(new_state: PlayerState):
	match new_state:
		PlayerState.SUPER:
			if current_state == PlayerState.FIRE:
				return
			call_deferred("change_state", PlayerState.SUPER)
		PlayerState.FIRE:
			call_deferred("change_state", PlayerState.FIRE)

func take_damage():
	if is_invulnerable:
		return
		
	match current_state:
		PlayerState.SMALL:
			die()
		PlayerState.SUPER:
			sfx_power_down.play()
			call_deferred("change_state", PlayerState.SMALL, true)
		PlayerState.FIRE:
			sfx_power_down.play()
			call_deferred("change_state", PlayerState.SUPER, true)
	
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
	
	var flag = get_tree().get_first_node_in_group("flag_pole")
	if flag and not flag.victory_started and flag.waiting_players.size() > 0:
		flag.victory_started = true
		
	if not GameControl.is_testing:
		if flag.victory_started:
			return
	
	if GameControl.is_multiplayer:
		GameControl.register_death(player_id)
		
		if GameControl.all_players_dead():
			RespawnCountdown.cancel_all()
			GameControl.stop_timer()
			GameControl.stop_level_song_music()
			await get_tree().create_timer(3.0).timeout
			GameControl.reload_level()
		else:
			var respawn_time = GameControl.get_respawn_time()
			await RespawnCountdown.start(respawn_time, player_id)
			if not GameControl.all_players_dead():
				GameControl.unregister_death(player_id)
				respawn()
	else:
		GameControl.stop_timer()
		GameControl.stop_level_song_music()
		await get_tree().create_timer(3.0).timeout
		GameControl.reload_level()
		
func respawn():
	var spawn = get_tree().get_first_node_in_group("spawn_points")
	global_position = spawn.global_position if spawn else global_position
	velocity = Vector2.ZERO
	is_dying = false
	z_index = 4
	collision_layer = 2
	collision_mask = 1
	stomp_detector.monitoring = true
	play_anim("idle")
	start_invulnerability_cpu()
	
func disable():
	set_physics_process(false)
	set_process_input(false)
	collision_layer = 0
	collision_mask = 0
	stomp_detector.monitoring = false
	velocity = Vector2.ZERO
	visible = false
	
func change_state(new_state: PlayerState, invulnerable: bool = false) -> void:
	if current_state == new_state:
		return
	
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	stomp_detector.monitoring = false
	animation_player.stop()
	
	var next_sprite
	match new_state:
		PlayerState.SMALL:
			next_sprite = small_sprite
		PlayerState.SUPER:
			next_sprite = super_sprite
		PlayerState.FIRE:
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
		
func set_state(state: PlayerState):
	current_state = state
	
	small_sprite.visible = false
	super_sprite.visible = false
	fire_sprite.visible = false
	
	match state:
		PlayerState.SMALL:
			current_sprite = small_sprite
		PlayerState.SUPER:
			current_sprite = super_sprite
		PlayerState.FIRE:
			current_sprite = fire_sprite
			
	current_sprite.visible = true

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
			body.die(self)
			
		if Input.is_action_pressed("p%d_jump" % player_id):
			velocity.y = JUMP_VELOCITY * 0.9
		else:
			velocity.y = JUMP_VELOCITY * 0.6

func _on_enemy_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if is_starman:
			var hit_dir = 1.0 if global_position.x < body.global_position.x else -1.0
			if body.has_method("die_special"):
				body.die_special(self, hit_dir)

func _on_starman_timer_timeout() -> void:
	end_starman_effect()
