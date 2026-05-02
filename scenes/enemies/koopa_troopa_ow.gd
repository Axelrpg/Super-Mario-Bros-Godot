extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_box: Area2D = $Hitbox

enum State {
	WALK,
	SHELL_IDLE,
	SHELL_MOVING
}
var current_state = State.WALK

var WALK_SPEED = 40
var SHELL_SPEED = 250
var direction = -1

var is_dying: bool = false
var has_spawned: bool = false

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	match current_state:
		State.WALK:
			velocity.x = direction * WALK_SPEED
			animation_player.play("walk")
			if is_on_wall():
				var wall_normal = get_wall_normal()
				if sign(wall_normal.x) != sign(direction):
					direction *= -1
		State.SHELL_IDLE:
			velocity.x = 0
			animation_player.play("shell_idle")
		State.SHELL_MOVING:
			velocity.x = direction * SHELL_SPEED
			animation_player.play("shell_moving")
			if is_on_wall():
				GameControl.play_bump_sound()
				var wall_normal = get_wall_normal()
				if sign(wall_normal.x) != sign(direction):
					direction *= -1
				
	sprite.flip_h = direction > 0
	
	move_and_slide()

func die():
	match current_state:
		State.WALK:
			GameControl.play_stomp_swim_sound()
			current_state = State.SHELL_IDLE
		State.SHELL_IDLE:
			GameControl.play_kick_kill_sound()
			var mario = get_tree().get_first_node_in_group("players")
			direction = sign(global_position.x - mario.global_position.x)
			current_state = State.SHELL_MOVING
		State.SHELL_MOVING:
			current_state = State.SHELL_IDLE

func die_special(hit_direction: float = 1.0):
	if is_dying: return
	GameControl.spawn_score(100, global_position)
	GameControl.play_kick_kill_sound()
	
	is_dying = true
	set_physics_process(false)
	animation_player.play("shell_moving")
	collision_layer = 0
	collision_mask = 0
	hit_box.monitoring = false
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
	if body.is_in_group("players"):
		if current_state == State.SHELL_IDLE:
			GameControl.play_kick_kill_sound()
			direction = sign(global_position.x - body.global_position.x)
			if direction == 0: direction = 1
			current_state =  State.SHELL_MOVING
			
		elif current_state == State.WALK or current_state == State.SHELL_MOVING:
			if body.has_method("take_damage"):
				if body.velocity.y <= 0:
					body.take_damage()
	elif body.is_in_group("enemies") and current_state == State.SHELL_MOVING and body != self:
		if body.has_method("die_special"):
			body.die_special(self.direction)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if not has_spawned:
		set_physics_process(true)
		has_spawned = true
