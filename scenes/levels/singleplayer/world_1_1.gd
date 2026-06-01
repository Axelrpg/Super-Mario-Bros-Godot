extends Node2D

@onready var luigi = $Luigi

func _ready() -> void:
	if not GameControl.is_multiplayer:
		luigi.disable()
	
	GameControl.reset_time(300)
	GameControl.start_timer()
	GameControl.reset_level_song_pitch_scale()
	GameControl.play_level_song_music()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		GameControl.reset_values(300)
		get_tree().reload_current_scene()
