extends ColorRect

@onready var sfx_game_over = $SFXGameOver

func _ready() -> void:
	sfx_game_over.play()
	await sfx_game_over.finished
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://scenes/levels/singleplayer/level_intro.tscn")
