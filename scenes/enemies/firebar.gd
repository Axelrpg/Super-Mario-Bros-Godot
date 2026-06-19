extends Node2D

@export var fireball_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D

var rotation_speed: float = 2.0
var ball_count: int = 6
var ball_spacing: float = 8.0
var clockwise: bool = true

func _ready() -> void:
	sprite.visible = false
	for i in ball_count:
		var ball = fireball_scene.instantiate()
		add_child(ball)
		ball.position = Vector2(i * ball_spacing, 0)
		
func _physics_process(delta: float) -> void:
	var dir = 1 if clockwise else -1
	rotation += rotation_speed * delta * dir
