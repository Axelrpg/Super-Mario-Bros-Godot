extends StaticBody2D

@export var current_env = GameControl.LevelEnvironment.OVERWORLD
@export var texture_overworld: Texture2D
@export var texture_underworld: Texture2D

@export var target_pipe_tag: String = ""
@export var camera_limits_sprite: Sprite2D
@export var is_enterable: bool = true
@export var has_piranha: bool = false

@onready var sprite = $Sprite2D
@onready var piranha = $PiranhaPlant
@onready var entry_area: Area2D = $EntryArea
@onready var sfx_pipe = $SFXPipe

var is_entrance: bool = false

func _ready() -> void:
	enable_piranha()
	
func _physics_process(_delta: float) -> void:
	if is_entrance:
		return
		
	var facing_dir = Vector2.UP.rotated(rotation).round()
	var required_action = ""
	
	if facing_dir == Vector2.UP: required_action = "down"
	if facing_dir == Vector2.DOWN: required_action = "up"
	if facing_dir == Vector2.LEFT: required_action = "right"
	if facing_dir == Vector2.RIGHT: required_action = "left"
	
	if is_enterable:
		var bodies = entry_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("players"):
				if check_collision_by_direction(body, facing_dir):
					var action = "p%d_%s" % [body.player_id, required_action]
					if Input.is_action_pressed(action):
						is_entrance = true
						disable_piranha()
						enter_pipe(body)

func set_environment(env) -> void:
	current_env = env
	update_texture()

func update_texture() -> void:
	match current_env:
		GameControl.LevelEnvironment.OVERWORLD:
			sprite.texture = texture_overworld
		GameControl.LevelEnvironment.UNDERWORLD:
			sprite.texture = texture_underworld
			
func enable_piranha():
	piranha.visible = has_piranha
	piranha.monitoring = has_piranha
	piranha.monitorable = has_piranha
			
func disable_piranha():
	piranha.visible = false
	piranha.monitoring = false
	piranha.monitorable = false

func check_collision_by_direction(player: CharacterBody2D, dir: Vector2) -> bool:
	if dir == Vector2.UP: return player.is_on_floor()
	if dir == Vector2.DOWN: return player.is_on_ceiling()
	if dir == Vector2.LEFT: return player.is_on_wall()
	if dir == Vector2.RIGHT: return player.is_on_wall()
	return false

func enter_pipe(player: CharacterBody2D):
	player.set_physics_process(false)
	player.z_index = 2
	sfx_pipe.play()
	
	if not GameControl.is_multiplayer:
		GameControl.stop_timer()
	
	var direction = Vector2.DOWN.rotated(rotation)
	var is_small = player.current_state == player.PlayerState.SMALL
	
	var align_pos = player.global_position
	if abs(direction.x) > 0.5:
		align_pos.y = global_position.y
		player.play_anim("walk")
		player.current_sprite.flip_h = direction.x < 0
	else:
		align_pos.x = global_position.x
		player.play_anim("idle")
		
	if is_small:
		var align_tween = create_tween()
		align_tween.tween_property(player, "global_position", align_pos, 0.1)
		await align_tween.finished
	
	var distance = 16 if is_small else 32
	var target_pos = player.global_position + (direction * distance)
	
	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, 0.6)
	
	tween.finished.connect(func(): transport_player(player))
	
func transport_player(player: CharacterBody2D):
	if GameControl.is_multiplayer:
		await MultiplayerTransition.fade_out(player.player_id, 0.5).finished
	else:
		await CustomTransition.fade_out(0.5).finished
	
	var exit_pipe = get_tree().get_nodes_in_group("pipes").filter(
		func(p): return p.target_pipe_tag == self.target_pipe_tag and p != self
	)[0]
	exit_pipe.disable_piranha()
	
	var new_limits = exit_pipe.get_camera_limits()
	
	var camera = get_tree().get_first_node_in_group("camera")
	camera.teleport_to_zone(exit_pipe.global_position, new_limits)
	
	player.global_position = exit_pipe.global_position - Vector2(0, -8)
	
	await get_tree().create_timer(1.5).timeout
	
	if GameControl.is_multiplayer:
		await MultiplayerTransition.fade_in(player.player_id, 1).finished
	else:
		await CustomTransition.fade_in(1).finished
	
	exit_pipe.exit_sequence(player, exit_pipe)
	
func exit_sequence(player: CharacterBody2D, exit_pipe: StaticBody2D):
	var out_direction = Vector2.UP.rotated(rotation)
	var is_small = player.current_state == player.PlayerState.SMALL
	sfx_pipe.play()
	
	var align_pos = player.global_position
	if abs(out_direction.x) > 0.5:
		align_pos.y = global_position.y
		player.play_anim("walk")
		player.current_sprite.flip_h = out_direction.x < 0
	else:
		align_pos.x = global_position.x
		player.play_anim("idle")
	
	if is_small:
		var align_tween = create_tween()
		align_tween.tween_property(player, "global_position", align_pos, 0.1)
		await align_tween.finished
	
	var exit_distance = 24
	var target_pos = global_position + (out_direction * exit_distance)
	
	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, 0.6)
	
	tween.finished.connect(func():
		player.z_index = 4
		player.set_physics_process(true)
		is_entrance = false
		exit_pipe.enable_piranha()
		GameControl.start_timer()
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
