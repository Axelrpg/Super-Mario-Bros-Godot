extends StaticBody2D
class_name BasePipe

@onready var entry_area: Area2D = $EntryArea

@export var target_pipe_tag: String = ""
@export var camera_limits_sprite: Sprite2D

var is_entrance: bool = false

func _physics_process(_delta: float) -> void:
	if is_entrance:
		return
		
	var facing_dir = Vector2.UP.rotated(rotation).round()
	
	var required_action = ""
	
	if facing_dir == Vector2.UP: required_action = "down"
	if facing_dir == Vector2.DOWN: required_action = "up"
	if facing_dir == Vector2.LEFT: required_action = "right"
	if facing_dir == Vector2.RIGHT: required_action = "left"
	
	if Input.is_action_pressed(required_action):
		var bodies = entry_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("players"):
				if check_collision_by_direction(body, facing_dir):
					is_entrance = true
					enter_pipe(body)

func check_collision_by_direction(player: CharacterBody2D, dir: Vector2) -> bool:
	if dir == Vector2.UP: return player.is_on_floor()
	if dir == Vector2.DOWN: return player.is_on_ceiling()
	if dir == Vector2.LEFT: return player.is_on_wall()
	if dir == Vector2.RIGHT: return player.is_on_wall()
	return false

func enter_pipe(player: CharacterBody2D):
	player.set_physics_process(false)
	player.animation_player.play("idle")
	player.z_index = 2
	
	var direction = Vector2.DOWN.rotated(rotation)
	
	var align_pos = player.global_position
	if abs(direction.x) > 0.5:
		align_pos.y = global_position.y
	else:
		align_pos.x = global_position.x
		
	var align_tween = create_tween()
	align_tween.tween_property(player, "global_position", align_pos, 0.1)
	await align_tween.finished
	
	var distance = 16 if player.current_state == player.PlayerState.SMALL else 32
	var target_pos = player.global_position + (direction * distance)
	
	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, 0.6)
	
	tween.finished.connect(func(): transport_player(player))
	
func transport_player(player: CharacterBody2D):
	await CustomTransition.fade_out(0.5).finished
	
	var exit_pipe = get_tree().get_nodes_in_group("pipes").filter(
		func(p): return p.target_pipe_tag == self.target_pipe_tag and p != self
	)[0]
	
	var new_limits = exit_pipe.get_camera_limits()
	
	var camera = get_tree().get_first_node_in_group("camera")
	camera.teleport_to_zone(exit_pipe.global_position, new_limits)
	
	player.global_position = exit_pipe.global_position
	
	await get_tree().create_timer(1.5).timeout
	await CustomTransition.fade_in(1).finished
	exit_pipe.exit_sequence(player)
	
func exit_sequence(player: CharacterBody2D):
	var out_direction = Vector2.UP.rotated(rotation)
	
	if abs(out_direction.x) > 0.1:
		player.sprite.flip_h = out_direction.x < 0
	
	var distance_inside = 16 if player.current_state == player.PlayerState.SMALL else 32
	player.global_position = global_position - (out_direction * distance_inside)
	
	var exit_distance = 24 if player.current_state == player.PlayerState.SMALL else 32
	var target_pos = global_position + (out_direction * exit_distance)
	
	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, 0.6)
	
	tween.finished.connect(func():
		player.z_index = 4
		player.set_physics_process(true)
		is_entrance = false
		)
		
func get_camera_limits() -> Dictionary:
	if camera_limits_sprite == null:
		return {
			"left": -10000,
			"right": 10000,
			"top": -10000,
			"bottom": 10000
		}
		
	var rect = camera_limits_sprite.get_rect()
	var global_pos = camera_limits_sprite.global_position
	var sprite_scale = camera_limits_sprite.global_scale
	
	return {
		"left": int(global_pos.x + rect.position.x * sprite_scale.x),
		"right": int(global_pos.x + (rect.position.x + rect.size.x) * sprite_scale.x),
		"top": int(global_pos.y + rect.position.y * sprite_scale.y),
		"bottom": int(global_pos.y + (rect.position.y + rect.size.y) * sprite_scale.y)
	}
