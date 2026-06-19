extends Area2D

@export var environment = GameControl.LevelEnvironment.OVERWORLD

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("set_environment"):
		area.set_environment(environment)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		match environment:
			GameControl.LevelEnvironment.OVERWORLD:
				GameControl.play_level_song_music(preload("res://music/1 - Running About.mp3"))
			GameControl.LevelEnvironment.UNDERWORLD:
				GameControl.play_level_song_music(preload("res://music/3 - Underground.mp3"))
			GameControl.LevelEnvironment.CASTLE:
				GameControl.play_level_song_music(preload("res://music/7 - Bowser's Castle.mp3"))
	
	if body.has_method("set_environment"):
		body.set_environment(environment)
