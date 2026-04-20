extends StaticBody2D
class_name BaseBlocks

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bump_detector: Area2D = $BumpDetector
@onready var timer: Timer = $Timer

enum ItemType {
	COIN,
	POWER_UP,
	STAR,
	NONE,
}
@export var content: ItemType = ItemType.NONE
@export var is_multi_coin: bool = false

const MUSHROOM_SCENE = preload("res://scenes/items/super_mushroom.tscn")
const FIRE_FLOWER_SCENE = preload("res://scenes/items/fire_flower.tscn")
const START_SCENE = preload("res://scenes/items/super_star.tscn")

var is_empty = false
var timer_started = false

func _ready() -> void:
	animation_player.play("idle")
	
func _physics_process(_delta: float) -> void:
	var bodies = bump_detector.get_overlapping_bodies()
	
	for body in bodies:
		if body.is_in_group("players"):
			if body.velocity.y > 10 and not is_empty:
				handle_hit(body)
				break
				
func handle_hit(body: CharacterBody2D):
	match content:
		ItemType.COIN:
			give_coin()
		ItemType.POWER_UP:
			give_power_up(body)
		ItemType.STAR:
			give_power_up(body)
		ItemType.NONE:
			break_or_bump(body)

func give_power_up(player):
	is_empty = true
	animation_player.play("empty")
	
	move_sprite()
	var item_to_spawn
	
	if content == ItemType.STAR:
		item_to_spawn = START_SCENE.instantiate()
	else:
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

func give_coin():
	if is_empty: return
	
	spawn_coin_visual()
	move_sprite()
	
	if is_multi_coin:
		if not timer_started:
			timer_started = true
			timer.start()
	else:
		is_empty = true
		animation_player.play("empty")
	
func spawn_coin_visual():
	var coin_scene = preload("res://scenes/items/jumping_coin.tscn")
	var coin = coin_scene.instantiate()
	get_parent().add_child(coin)
	coin.global_position = global_position + Vector2(0, -16)
	
func move_sprite():
	var tween = create_tween()
	tween.tween_property(sprite, "position:y", -8, 0.1).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "position:y", 0, 0.1).set_trans(Tween.TRANS_QUAD)

func break_or_bump(_player: CharacterBody2D):
	pass
