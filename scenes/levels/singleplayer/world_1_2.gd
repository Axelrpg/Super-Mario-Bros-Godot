extends Node2D

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		GameControl.reset_values(300)
		get_tree().reload_current_scene()
