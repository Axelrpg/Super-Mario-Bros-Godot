extends CanvasLayer

@onready var score_label = $MarginContainer/HBoxContainer/Score/Value
@onready var coins_label = $MarginContainer/HBoxContainer/Coins/Value
@onready var world_label = $MarginContainer/HBoxContainer/World/Value
@onready var time_label = $MarginContainer/HBoxContainer/Time/Value
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("idle")
	update_hud()
	
func update_hud():
	score_label.text = "%06d" % GameControl.total_score
	coins_label.text = "x%02d" % GameControl.total_coins
	world_label.text = GameControl.current_world + "-" + GameControl.current_level
	time_label.text = "%03d" % floor(GameControl.time_left)
