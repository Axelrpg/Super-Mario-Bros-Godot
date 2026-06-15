extends CharacterBody2D

@export var texture_overworld: Texture2D
@export var texture_underworld: Texture2D
@export var texture_red: Texture2D

@export var is_paratroopa: bool = false
@export var is_red: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var screen_notifier = $VisibleOnScreenNotifier2D
@onready var edge_detector: RayCast2D = $EdgeDetector

var current_env = GameControl.LevelEnvironment.OVERWORLD
var owner_player_id: int = 1

enum State {
	WALK,
	SHELL_IDLE,
	SHELL_MOVING,
	FLY
}
var current_state = State.WALK

var walk_speed = 40
var shell_speed = 250
var fly_distance: float = 40.0
var fly_speed: float = 1.5
var fly_origin: Vector2
var fly_tween: Tween = null
var is_dying: bool = false
var has_spawned: bool = false
var deactivate_timer: SceneTreeTimer = null
var can_change_state: bool = true
var direction = -1

func _ready() -> void:
	set_physics_process(false)
	
	if is_red:
		sprite.texture = texture_red
		edge_detector.enabled = true

func _physics_process(delta: float) -> void:
	if edge_detector.enabled:
		edge_detector.position.x = abs(edge_detector.position.x) * direction
		edge_detector.force_raycast_update()
	
	if current_state != State.FLY:
		if not is_on_floor():
			velocity += get_gravity() * delta
		
	match current_state:
		State.FLY:
			animation_player.play("fly")
			collision_mask = 0b101
		State.WALK:
			velocity.x = direction * walk_speed
			animation_player.play("walk")
			collision_mask = 0b101
			check_walk_direction()
		State.SHELL_IDLE:
			velocity.x = 0
			animation_player.play("shell_idle")
			collision_mask = 0b101
		State.SHELL_MOVING:
			velocity.x = direction * shell_speed
			animation_player.play("shell_moving")
			collision_mask = 0b001
			if is_on_wall():
				GameControl.play_bump_sound()
				var wall_normal = get_wall_normal()
				if sign(wall_normal.x) != sign(direction):
					direction *= -1
				
	sprite.flip_h = direction > 0
	
	if current_state != State.FLY:
		move_and_slide()
	
func set_environment(env) -> void:
	if is_red: return
	
	current_env = env
	update_texture()

func update_texture() -> void:
	match current_env:
		GameControl.LevelEnvironment.OVERWORLD:
			sprite.texture = texture_overworld
		GameControl.LevelEnvironment.UNDERWORLD:
			sprite.texture = texture_underworld
			
func start_flying() -> void:
	fly_origin = global_position
	current_state = State.FLY
	fly_loop()

func fly_loop() -> void:
	while current_state == State.FLY:
		await _move_to(fly_origin + Vector2(0, fly_distance))
		await _move_to(fly_origin)

func _move_to(target: Vector2) -> void:
	fly_tween = create_tween()
	fly_tween.tween_property(self, "global_position", target, fly_speed)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	await fly_tween.finished

func die(_player: Node2D = null):
	match current_state:
		State.FLY:
			GameControl.play_stomp_swim_sound()
			current_state = State.WALK
			if fly_tween:
				fly_tween.kill()
				fly_tween = null
		State.WALK:
			GameControl.play_stomp_swim_sound()
			current_state = State.SHELL_IDLE
			block_state_change(0.3)
		State.SHELL_IDLE:
			GameControl.play_kick_kill_sound()
			var mario = get_tree().get_first_node_in_group("players")
			direction = sign(global_position.x - mario.global_position.x)
			current_state = State.SHELL_MOVING
		State.SHELL_MOVING:
			current_state = State.SHELL_IDLE
			block_state_change(0.3)
			
func block_state_change(duration: float) -> void:
	can_change_state = false
	await get_tree().create_timer(duration).timeout
	can_change_state = true

func die_special(body: Node2D, hit_direction: float = 1.0):
	if is_dying: return
	GameControl.spawn_score(100, global_position, body)
	GameControl.play_kick_kill_sound()
	
	is_dying = true
	set_physics_process(false)
	animation_player.play("shell_moving")
	collision_layer = 0
	collision_mask = 0
	hitbox.monitoring = false
	hurtbox.monitoring = false
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

func check_walk_direction():
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if sign(wall_normal.x) != sign(direction):
			direction *= -1
	elif is_on_floor() and edge_detector.enabled and not edge_detector.is_colliding():
		direction *= -1

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and can_change_state:
		owner_player_id = body.player_id
		match current_state:
			State.SHELL_IDLE:
				GameControl.play_kick_kill_sound()
				direction = sign(global_position.x - body.global_position.x)
				if direction == 0: direction = 1
				current_state = State.SHELL_MOVING
	elif body.is_in_group("enemies") and current_state == State.SHELL_MOVING and body != self:
		if body.has_method("die_special"):
			body.die_special(body, self.direction)
			
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox") and current_state == State.WALK:
		var enemy = area.get_parent()
		if enemy != self and enemy != null:
			var push_dir = sign(global_position.x - enemy.global_position.x)
			if push_dir == sign(direction):
				direction *= -1
				
func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body.velocity.y <= 0:
		match current_state:
			State.FLY, State.WALK, State.SHELL_MOVING:
				if body.has_method("take_damage"):
					body.take_damage() 

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if deactivate_timer:
		deactivate_timer = null
	
	if not has_spawned:
		has_spawned = true
		if is_paratroopa:
			start_flying()
			
	set_physics_process(true)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if not has_spawned: return
	
	deactivate_timer = get_tree().create_timer(3.0)
	await deactivate_timer.timeout
	
	if not screen_notifier.is_on_screen():
		set_physics_process(false)
