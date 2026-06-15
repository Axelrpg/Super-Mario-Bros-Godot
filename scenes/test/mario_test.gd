extends Node2D

func _process(_delta: float) -> void:
	GameControl.is_testing = true
	if Input.is_action_just_pressed("reset"):
		print("="  .repeat(50))
		print("RESET")
		print("=".repeat(50))
		get_tree().reload_current_scene()
