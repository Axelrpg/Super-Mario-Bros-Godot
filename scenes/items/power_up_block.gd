extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_empty = false

func _ready() -> void:
	animation_player.play("idle")

func _on_bump_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body.velocity.y > 0 and not is_empty:
		give_power_up()

func give_power_up():
	is_empty = true
	animation_player.play("bump")
	
