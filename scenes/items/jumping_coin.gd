extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if animation_player.has_animation("coin_jump"):
		animation_player.play("coin_jump")
	else:
		print("Error: No se encontró la animación 'coin_jump'")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "coin_jump":
		queue_free()
