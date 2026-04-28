extends ColorRect

@onready var world_label = $MarginContainer/VBoxContainer/WorldLabel
@onready var livel_label = $MarginContainer/VBoxContainer/HBoxContainer/LivesLabel

func _ready() -> void:
	world_label.text = "World " + GameControl.current_world + "-" + GameControl.current_level
	livel_label.text = str(GameControl.lives)
	
	await get_tree().create_timer(2.0).timeout
	
	start_level()
	
func start_level():
	get_tree().change_scene_to_file("res://scenes/levels/world_1_1.tscn")
