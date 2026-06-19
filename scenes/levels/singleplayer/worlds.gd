extends Node
class_name Worlds

@onready var luigi = $Luigi

func _ready() -> void:
	if not GameControl.is_multiplayer:
		luigi.disable()
	
	GameControl.reset_time(300)
	GameControl.start_timer()
	GameControl.reset_level_song_pitch_scale()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		print("="  .repeat(50))
		print("RESET")
		print("=".repeat(50))
		GameControl.reset_values(300)
		get_tree().reload_current_scene()
