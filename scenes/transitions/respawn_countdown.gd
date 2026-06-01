extends CanvasLayer

@onready var p1 = $HBoxContainer/Left/P1
@onready var p2 = $HBoxContainer/Right/P2

var cancelled: bool = false

func start(seconds: float, player_id: int = 0):
	cancelled = false
	var label = p1 if player_id == 1 else p2
	label.visible = true
	var time_left = seconds
	
	while time_left > 0 and not cancelled:
		label.text = str(ceil(time_left) as int)
		await get_tree().create_timer(0.1).timeout
		time_left -= 0.1
		
	label.visible = false
	
func cancel_all():
	cancelled = true
	hide_labels()

func hide_labels():
	p1.visible = false
	p2.visible = false
