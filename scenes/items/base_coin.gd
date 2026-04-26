extends Area2D
class_name BaseCoin

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		collect()

func collect():
	set_deferred("monitoring", false)
	
	queue_free()
