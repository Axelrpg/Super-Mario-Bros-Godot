extends StaticBody2D
class_name BaseBlocks

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bump_detector: Area2D = $BumpDetector
@onready var top_checker: Area2D = $TopChecker
@onready var timer: Timer = $Timer

enum ItemType {
	COIN,
	POWER_UP,
	STAR,
	EXTRA_LIFE,
	NONE,
}
@export var content: ItemType = ItemType.NONE
@export var is_multi_coin: bool = false

enum ItemSpawn {
	MUSHROOM,
	FIRE_FLOWER,
	STAR,
	EXTRA_LIFE
}

const MUSHROOM_SCENE = preload("res://scenes/items/super_mushroom.tscn")
const FIRE_FLOWER_SCENE = preload("res://scenes/items/fire_flower.tscn")
const START_SCENE = preload("res://scenes/items/super_star.tscn")
const EXTRA_LIFE_SCENE = preload("res://scenes/items/extra_life.tscn")

var is_empty = false
var timer_started = false
var is_hidden_block = false
var is_revealed = true
var is_hitting = false

func _ready() -> void:
	animation_player.play("idle")
	
func _physics_process(_delta: float) -> void:
	if is_empty or is_hitting: return
	
	var bodies = bump_detector.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("players"):
			var is_below = body.global_position.y > global_position.y
			
			if is_hidden_block:
				if is_below and body.velocity.y < -10:
					handle_hit(body)
			else:
				if is_below and body.velocity.y > 10:
					handle_hit(body)

func handle_hit(player: CharacterBody2D):
	if is_empty or is_hitting: return
	
	var is_small = player.current_state == player.MarioState.SMALL
	var player_position = player.global_position
	
	if NetManager.is_online:
		if multiplayer.is_server():
			handle_hit_execute.rpc(is_small, player_position)
		else:
			handle_hit_rpc.rpc_id(1, is_small, player_position)
	else:
		handle_hit_execute(is_small, player_position)

@rpc("any_peer", "reliable")
func handle_hit_rpc(is_small: bool, player_position: Vector2):
	if not multiplayer.is_server():
		return
	handle_hit_execute.rpc(is_small, player_position)

@rpc("call_local", "reliable")
func handle_hit_execute(is_small: bool, player_position: Vector2):
	if is_empty or is_hitting: return
	
	if is_hidden_block:
		set_collision_layer_value(1, true)
		set_collision_layer_value(5, false)
		sprite.modulate.a = 1
		
	if content == ItemType.COIN:
		give_coin()
	elif content == ItemType.NONE:
		break_or_bump(is_small)
	else:
		give_power_up(is_small, player_position)

func give_power_up(is_small: bool, player_position: Vector2):
	if is_empty or is_hidden_block: return
	
	var item_type: int
	if content == ItemType.STAR:
		item_type = ItemSpawn.STAR
	elif content == ItemType.EXTRA_LIFE:
		item_type = ItemType.EXTRA_LIFE
	elif is_small:
		item_type = ItemSpawn.MUSHROOM
	else:
		item_type = ItemSpawn.FIRE_FLOWER
		
	var hit_dir = 1.0 if player_position.x < global_position.x else -1.0
	give_power_up_execute(item_type, hit_dir)
		
func give_power_up_execute(item_type: int, hit_dir: float):
	is_empty = true
	animation_player.play("empty")
	move_sprite()
	GameControl.play_item_sound()
	
	if not NetManager.is_online or multiplayer.is_server():
		var item_to_spawn
		match item_type:
			ItemSpawn.STAR:
				item_to_spawn = START_SCENE.instantiate()
			ItemSpawn.EXTRA_LIFE:
				item_to_spawn = EXTRA_LIFE_SCENE.instantiate()
			ItemSpawn.MUSHROOM:
				item_to_spawn = MUSHROOM_SCENE.instantiate()
			ItemSpawn.FIRE_FLOWER:
				item_to_spawn = FIRE_FLOWER_SCENE.instantiate()
				
		if item_to_spawn.has_method("set_direction"):
			item_to_spawn.direction = hit_dir
			
		item_to_spawn.global_position = global_position + Vector2(0, -8)
		get_parent().add_child.call_deferred(item_to_spawn)

@rpc("call_local", "reliable")
func give_coin():
	if is_empty or is_hitting: return
	is_hitting = true
	
	move_sprite()
	spawn_coin_visual()
	var attacker_id = multiplayer.get_unique_id() if NetManager.is_online else 0
	GameControl.spawn_score(200, global_position, attacker_id)
	GameControl.add_coin(false)
	GameControl.play_coin_sound()
	
	if is_multi_coin:
		if not timer_started:
			timer_started = true
			timer.start()
		
		await get_tree().create_timer(0.1).timeout
		is_hitting = false
	else:
		is_empty = true
		is_hitting = false
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
	check_objects_above()
	
func check_objects_above():
	var bodies = top_checker.get_overlapping_bodies()
	
	for body in bodies:
		if body.is_in_group("enemies"):
			var attacker_id = multiplayer.get_unique_id() if NetManager.is_online else 0
			if body.global_position.x > global_position.x:
				if body.has_method("die_special"):
					body.die_special(1, attacker_id)
			else:
				if body.has_method("die_special"):
					body.die_special(-1, attacker_id)
				
		if body.is_in_group("power_ups"):
			if body is CharacterBody2D:
				body.velocity.y = -200
				
				if body.global_position.x > global_position.x:
					if body.has_method("set_direction"):
						body.set_direction(1)
				else:
					if body.has_method("set_direction"):
						body.set_direction(-1)

func break_or_bump(_is_small: bool):
	pass
