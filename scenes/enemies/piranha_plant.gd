extends Area2D

@export var current_env = GameControl.LevelEnvironment.OVERWORLD
@export var texture_overworld: Texture2D
@export var texture_underworld: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var move_distance: float = 28
var move_speed: float = 0.8
var pause_time: float = 1.5
var detection_radius: float = 60

var is_paused: bool = false
var origin: Vector2

func _ready() -> void:
	animation_player.play("idle")
	origin = global_position
	start_cycle()

func start_cycle():
	while true:
		if not is_player_nearby():
			await move_to(origin + Vector2(0, -move_distance))
			await get_tree().create_timer(pause_time).timeout
			await move_to(origin)
		await get_tree().create_timer(pause_time).timeout
			
func move_to(target: Vector2):
	var tween = create_tween()
	tween.tween_property(self, "global_position", target, move_speed)\
		.set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	
func is_player_nearby() -> bool:
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if global_position.distance_to(player.global_position) < detection_radius:
			return true
	return false
	
func set_environment(env) -> void:
	current_env = env
	update_texture()

func update_texture() -> void:
	match current_env:
		GameControl.LevelEnvironment.OVERWORLD:
			sprite.texture = texture_overworld
		GameControl.LevelEnvironment.UNDERWORLD:
			sprite.texture = texture_underworld

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage()
