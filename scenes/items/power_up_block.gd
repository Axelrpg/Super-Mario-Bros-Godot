extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

const MUSHROOM_SCENE = preload("res://scenes/items/super_mushroom.tscn")
const FIRE_FLOWER_SCENE = preload("res://scenes/items/fire_flower.tscn")

var is_empty = false

func _ready() -> void:
	animation_player.play("idle")

func _on_bump_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body.velocity.y > 0 and not is_empty:
		give_power_up(body)

func give_power_up(player):
	is_empty = true
	animation_player.play("bump")
	
	var item_to_spawn
	if player.current_state == player.PlayerState.SMALL:
		item_to_spawn = MUSHROOM_SCENE.instantiate()
	else:
		item_to_spawn = FIRE_FLOWER_SCENE.instantiate()
		
	if item_to_spawn.has_method("set_direction"):
		var hit_dir = 1.0 if player.global_position.x < global_position.x else -1.0
		item_to_spawn.direction = hit_dir
		
	item_to_spawn.global_position = global_position + Vector2(0, -16)
	get_parent().add_child.call_deferred(item_to_spawn)
	
	spawn_animation_tween(item_to_spawn)

func spawn_animation_tween(item: CharacterBody2D):
	await get_tree().process_frame
	if is_instance_valid(item):
		item.modulate.a = 0.0
		item.global_position.y += 8
		
		item.set_physics_process(false)
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(item, "global_position:y",
		item.global_position.y - 8, 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		tween.tween_property(item, "modulate:a", 1.0, 0.3)
		
		await tween.finished
		if is_instance_valid(item):
			item.set_physics_process(true)
