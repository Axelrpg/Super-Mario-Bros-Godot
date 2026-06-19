extends Node

enum LevelEnvironment {
	OVERWORLD,
	UNDERWORLD,
	CASTLE
}
var current_env = LevelEnvironment.OVERWORLD

@export var is_multiplayer: bool = true
@export var next_level_scene: PackedScene

@onready var sfx_1up = $SFX/SFX1Up
@onready var sfx_brick = $SFX/SFXBrick
@onready var sfx_bump = $SFX/SFXBump
@onready var sfx_coin = $SFX/SFXCoin
@onready var sfx_hurry_up = $SFX/SFXHurryUp
@onready var sfx_item = $SFX/SFXItem
@onready var sfx_kick_kill = $SFX/SFXKickKill
@onready var sfx_power_up = $SFX/SFXPowerUp
@onready var sfx_stomp_swim = $SFX/SFXStompSwim

@onready var bgm_level_song = $BGM/BGMLevelSong
@onready var bgm_level_complete = $BGM/BGMLevelComplete
@onready var bgm_starman = $BGM/BGMStarman

var score_scene = preload("res://scenes/hud/floating_score.tscn")
var level_intro_scene = preload("res://scenes/levels/singleplayer/level_intro.tscn")

var lives: int = 2
var total_score: int = 0
var total_coins: int = 0
var current_world: String = "1"
var current_level: String = "1"
var time_left: float = 300
var is_timer_active: bool = true

var player_scores: Dictionary = {}
var player_coins: Dictionary = {}
var player_states: Dictionary = {}
var dead_players: Array = []
var total_players: int = 2
var death_count: int = 0

var last_second: int = 0
var hurry_up_played: bool = false

var is_testing = false

func _process(delta: float) -> void:
	if is_timer_active and time_left > 0:
		time_left -= delta
		
		if time_left <= 0:
			time_left = 0
			is_timer_active = false
			update_ui()
			killer_player_by_timeout()
			return
		
		var current_second = int(floor(time_left))
		if current_second != last_second:
			last_second = current_second
			update_ui()
			
			if current_second <= 100 and not hurry_up_played:
				play_hurry_up_sound()
				
func get_player_score(player_id: int):
	return player_scores.get(player_id, 0)
	
func get_player_coins(player_id: int):
	return player_coins.get(player_id, 0)
	
func get_respawn_time() -> float:
	death_count += 1
	return death_count * 3.0

func spawn_score(value: int, pos: Vector2, body: Node2D = null):
	var player_id = 0
	
	if body == null:
		player_id = 0
	elif body.is_in_group("players"):
		player_id = body.player_id
	elif body.get("owner_player_id") != null:
		player_id = body.owner_player_id
	
	add_score(value, player_id)
	
	var score_popup = score_scene.instantiate()
	score_popup.global_position = pos
	
	if GameControl.is_multiplayer and player_id > 0:
		var players = get_tree().get_nodes_in_group("players")
		for p in players:
			if p.player_id == player_id:
				p.get_viewport().add_child(score_popup)
				score_popup.setup(value)
				return
				
	body.get_viewport().add_child(score_popup)
	score_popup.setup(value)
	
func add_score(amount: int, player_id: int):
	if is_multiplayer:
		player_scores[player_id] = get_player_score(player_id) + amount
	else:
		total_score += amount
	
func add_coin(player_id: int, with_score: bool = true):
	if is_multiplayer:
		var coins = get_player_coins(player_id) + 1
		if coins >= 100:
			coins = 0
			add_score(200, player_id)
		player_coins[player_id] = coins
	else:
		total_coins += 1
		if total_coins >= 100:
			total_coins = 0
			
	if with_score:
		add_score(200, player_id)
		
	update_ui()
	
func update_ui():
	var huds = get_tree().get_nodes_in_group("hud")
	for hud in huds:
		if hud:
			hud.update_hud()
			
func advance_level():
	var level = int(current_level) + 1
	var world = int(current_world)
	
	if level > 4:
		level = 1
		current_world = str(world + 1)
		
	current_level = str(level)
	
func save_player_state(player: CharacterBody2D):
	player_states[player.player_id] = player.current_state
	
func restore_player(player: CharacterBody2D):
	if player.player_id in player_states:
		player.set_state(player_states[player.player_id])

func start_timer():
	is_timer_active = true

func stop_timer():
	is_timer_active = false	
	
func reset_time(custom_time: int = 300):
	time_left = custom_time
	
func reset_death_count():
	death_count = 0
	
func reset_values(custom_time: int = 300):
	if is_multiplayer:
		player_scores.clear()
		player_coins.clear()
	else:
		total_score = 0
		total_coins = 0
	
	time_left = custom_time
	death_count = 0
	
func killer_player_by_timeout():
	var players = get_tree().get_nodes_in_group("players")
	
	for player in players:
		if player.has_method("die"):
			player.die()
		
func register_death(player_id: int):
	if player_id not in dead_players:
		dead_players.append(player_id)
		
func unregister_death(player_id: int):
	dead_players.erase(player_id)
	
func all_players_dead() -> bool:
	return dead_players.size() >= total_players
		
func play_1up_sound():
	sfx_1up.play()
	
func play_brick_sound():
	sfx_brick.play()
	
func play_bump_sound():
	sfx_bump.play()
	
func play_coin_sound():
	sfx_coin.play()
	
func play_hurry_up_sound():
	hurry_up_played = true
	bgm_level_song.stream_paused = true
	sfx_hurry_up.play()
	await sfx_hurry_up.finished
	bgm_level_song.pitch_scale = 1.3
	bgm_level_song.stream_paused = false
	
func play_item_sound():
	sfx_item.play()
	
func play_kick_kill_sound():
	sfx_kick_kill.play()
	
func play_power_up_sound():
	sfx_power_up.play()
	
func play_stomp_swim_sound():
	sfx_stomp_swim.play()
	
func play_level_song_music(stream: AudioStream = null):
	if stream:
		bgm_level_song.stream = stream
	bgm_level_song.play()
	
func stop_level_song_music():
	bgm_level_song.stop()
	
func reset_level_song_pitch_scale():
	bgm_level_song.pitch_scale = 1
	
func play_level_complete_music():
	bgm_level_complete.play()
	
func play_starman_music():
	bgm_level_song.stop()
	bgm_starman.play()
	
func stop_starman_music():
	bgm_starman.stop()
	bgm_level_song.play()
		
func reload_level():
	lives -= 1
	
	if is_multiplayer:
		dead_players.clear()
		death_count = 0
	
	if lives >= 0:
		get_tree().change_scene_to_file("res://scenes/levels/singleplayer/level_intro.tscn")
	else:
		game_over()

func game_over():
	get_tree().change_scene_to_file("res://scenes/levels/singleplayer/game_over.tscn")
