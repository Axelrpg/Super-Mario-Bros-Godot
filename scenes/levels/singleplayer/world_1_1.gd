extends Node2D

func _ready() -> void:
	GameControl.reset_time(110)
	GameControl.start_timer()
	GameControl.reset_level_song_pitch_scale()
	GameControl.play_level_song_music()
	GameControl.is_timer_active = true

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		GameControl.reset_values(300)
		get_tree().reload_current_scene()
