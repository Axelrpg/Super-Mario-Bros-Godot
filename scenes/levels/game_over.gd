extends ColorRect

func _ready() -> void:
	await get_tree().create_timer(10).timeoutlevel_intro_scene
	get_tree().change_scene_to_file("res://scenes/levels/level_intro.tscn")
