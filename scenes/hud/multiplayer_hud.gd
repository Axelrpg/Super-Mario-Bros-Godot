extends CanvasLayer

@onready var left_score_label = $HBoxContainer/MarginLeft/HBoxContainer/Score/Value
@onready var left_coins_label = $HBoxContainer/MarginLeft/HBoxContainer/Coins/Value

@onready var right_score_label = $HBoxContainer/MarginRight/HBoxContainer/Score/Value
@onready var right_coins_label = $HBoxContainer/MarginRight/HBoxContainer/Coins/Value

@onready var world_label = $HBoxContainer/MarginCenter/HBoxContainer/World/Value
@onready var time_label = $HBoxContainer/MarginCenter/HBoxContainer/Time/Value
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("idle")
	update_hud()
	
func update_hud():
	left_score_label.text = "%06d" % GameControl.get_player_score(1)
	left_coins_label.text = "x%02d" % GameControl.get_player_coins(1)
	
	right_score_label.text = "%06d" % GameControl.get_player_score(2)
	right_coins_label.text = "x%02d" % GameControl.get_player_coins(2)
	
	world_label.text = GameControl.current_world + "-" + GameControl.current_level
	time_label.text = "%03d" % floor(GameControl.time_left)
