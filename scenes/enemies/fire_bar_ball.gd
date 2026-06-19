extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage()
