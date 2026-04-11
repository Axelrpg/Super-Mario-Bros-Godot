extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bump_detector: Area2D = $BumpDetector

var is_empty = false

func _ready() -> void:
	animation_player.play("idle")

func _physics_process(_delta: float) -> void:
	if is_empty: return
	
	var bodies = bump_detector.get_overlapping_bodies()
	
	for body in bodies:
		if body.is_in_group("players"):
			if body.velocity.y > 10:
				give_coin()
				break

func give_coin():
	is_empty = true
	animation_player.play("bump")
	spawn_coin_visual()
	
func spawn_coin_visual():
	var coin_scene = preload("res://scenes/items/jumping_coin.tscn")
	var coin = coin_scene.instantiate()
	get_parent().add_child(coin)
	coin.global_position = global_position + Vector2(0, -16)
