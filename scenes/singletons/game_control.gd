extends Node

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

var score_scene = preload("res://scenes/items/floating_score.tscn")
var level_intro_scene = preload("res://scenes/levels/singleplayer/level_intro.tscn")

var lives: int = 2
var total_score: int = 0
var coins: int = 0
var current_world: String = "1"
var current_level: String = "1"
var time_left: float = 300
var is_timer_active: bool = true

var last_second: int = 0
var hurry_up_played: bool = false

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

func spawn_score(value: int, pos: Vector2):
	add_score(value)
	var score_popup = score_scene.instantiate()
	score_popup.global_position = pos
	get_tree().current_scene.add_child(score_popup)
	score_popup.setup(value)
	
func add_score(amount: int):
	total_score += amount
	
func add_coin(with_score: bool = true):
	coins += 1
	if coins >= 100:
		coins = 0
	
	if with_score:
		add_score(200)
	
	update_ui()
	
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
	
func play_level_song_music():
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
	
	if lives >= 0:
		get_tree().change_scene_to_file("res://scenes/levels/singleplayer/level_intro.tscn")
	else:
		game_over()

func game_over():
	get_tree().change_scene_to_file("res://scenes/levels/singleplayer/game_over.tscn")
