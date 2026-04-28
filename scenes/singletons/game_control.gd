extends Node

@onready var sfx_1up = $SFX1Up

var score_scene = preload("res://scenes/items/floating_score.tscn")
var level_intro_scene = preload("res://scenes/levels/level_intro.tscn")

var lives: int = 2
var total_score: int = 0
var coins: int = 0
var current_world: String = "1"
var current_level: String = "1"
var time_left: float = 300
var is_timer_active: bool = true

var last_second: int = 0

func _process(delta: float) -> void:
	if is_timer_active and time_left > 0:
		time_left -= delta
		
		if time_left <= 0:
			time_left = 0
			is_timer_active = false
			update_ui()
			killer_player_by_timeout()
			return
		
		var current_second = floor(time_left)
		if current_second != last_second:
			last_second = current_second
			update_ui()

func spawn_score(value: int, pos: Vector2):
	add_score(value)
	var score_popup = score_scene.instantiate()
	score_popup.global_position = pos
	get_tree().current_scene.add_child(score_popup)
	score_popup.setup(value)
	
func add_score(amount: int):
	total_score += amount
	
func add_coin():
	coins += 1
	if coins >= 100:
		coins = 0
	add_score(200)
	
func update_ui():
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_hud()

func stop_timer():
	is_timer_active = false
	
func start_timer():
	is_timer_active = true
	
func reset_time(custom_time: int = 300):
	time_left = custom_time
	
func reset_values(custom_time: int = 300):
	total_score = 0
	coins = 0
	time_left = custom_time
	
func killer_player_by_timeout():
	var player = get_tree().get_first_node_in_group("players")
	
	if player and player.has_method("die"):
		player.die()
		
func play_1up_sound():
	sfx_1up.play()
		
func reload_level():
	lives -= 1
	
	if lives >= 0:
		get_tree().change_scene_to_file("res://scenes/levels/level_intro.tscn")
	else:
		game_over()

func game_over():
	get_tree().change_scene_to_file("res://scenes/levels/game_over.tscn")
