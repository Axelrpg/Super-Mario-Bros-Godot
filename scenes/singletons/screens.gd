extends Node

func _ready() -> void:
	_setup_window_position()
	
func _setup_window_position():
	var screen_size = DisplayServer.screen_get_size()
	var window_width = screen_size.x / 2
	var window_height = screen_size.y
	
	DisplayServer.window_set_size(Vector2i(window_width, window_height))
	
	var args = OS.get_cmdline_user_args()
	
	if "left" in args:
		DisplayServer.window_set_position(Vector2i(0, 0))
	elif "right" in args:
		DisplayServer.window_set_position(Vector2i(window_width, 0))
