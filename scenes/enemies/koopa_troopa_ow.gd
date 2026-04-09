extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

enum State {
	WALK,
	SHELL_IDLE,
	SHELL_MOVING
}
var current_state = State.WALK

var WALK_SPEED = 40
var SHELL_SPEED = 250
var direction = -1

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
				var wall_normal = get_wall_normal()
				if sign(wall_normal.x) != sign(direction):
					direction *= -1
				
	sprite.flip_h = direction > 0
	
	move_and_slide()

func die():
	match current_state:
		State.WALK:
			current_state = State.SHELL_IDLE
		State.SHELL_IDLE:
			var mario = get_tree().get_first_node_in_group("players")
			direction = sign(global_position.x - mario.global_position.x)
			current_state = State.SHELL_MOVING
		State.SHELL_MOVING:
			current_state = State.SHELL_IDLE


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		if current_state == State.SHELL_IDLE:
			direction = sign(global_position.x - body.global_position.x)
			if direction == 0: direction = 1
			current_state =  State.SHELL_MOVING
			
		elif current_state == State.WALK or current_state == State.SHELL_MOVING:
			if body.has_method("take_damage"):
				if body.velocity.y <= 0:
					body.take_damage()
