extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var speed: float = 80.0
var direction: int = -1

func _ready() -> void:
	animation_player.play("idle")

func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage()
	queue_free()
