extends StaticBody2D

@onready var entry_area: Area2D = $EntryArea

@export var target_pipe_tag: String = ""
@export var camera_limits_sprite: Sprite2D

var is_entrance: bool = true

func _physics_process(_delta: float) -> void:
	if is_entrance and Input.is_action_pressed("down"):
		var bodies = entry_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("players") and body.is_on_floor():
				enter_pipe(body)
				
func enter_pipe(player: CharacterBody2D):
	player.set_physics_process(false)
	player.animation_player.play("idle")
	player.z_index = 2
	
	var tween = create_tween()
	var target_pos
	if player.current_state == player.PlayerState.SMALL:
		target_pos = player.global_position + Vector2(0, 16)
	else:
		target_pos = player.global_position + Vector2(0, 32)
	tween.tween_property(player, "global_position", target_pos, 0.6)
	
	tween.finished.connect(func(): transport_player(player))
	
func transport_player(player: CharacterBody2D):
	await CustomTransition.fade_out(0.5)
	
	var exit_pipe = get_tree().get_nodes_in_group("pipes").filter(
		func(p): return p.target_pipe_tag == self.target_pipe_tag and p != self
	)[0]
	
	var new_limits = exit_pipe.get_camera_limits()
	
	var camera = get_tree().get_first_node_in_group("camera")
	camera.teleport_to_zone(exit_pipe.global_position, new_limits)
	
	player.global_position = exit_pipe.global_position
	
	await get_tree().create_timer(1).timeout
	await CustomTransition.fade_in(1)
	exit_pipe.exit_sequence(player)
	
func exit_sequence(player: CharacterBody2D):
	player.global_position = global_position
	
	var tween = create_tween()
	var target_pos
	if player.current_state == player.PlayerState.SMALL:
		target_pos = player.global_position + Vector2(0, -24)
	else:
		target_pos = player.global_position + Vector2(0, -32)
	
	tween.tween_property(player, "global_position", target_pos, 0.6)
	
	tween.finished.connect(func():
		player.z_index = 10
		player.set_physics_process(true)
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
