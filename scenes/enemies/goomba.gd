extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

@export var activation_range: float = 300.0

var SPEED = 50
var direction = -1

var is_dying = false
var has_spawned = false

func _ready() -> void:
	if NetManager.is_online and multiplayer.is_server():
		set_multiplayer_authority(1)
	
	set_physics_process(false)
	
func _process(_delta: float) -> void:
	if NetManager.is_online and not multiplayer.is_server():
		return
	if has_spawned:
		return
		
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if global_position.distance_to(player.global_position) < activation_range:
			set_physics_process(true)
			has_spawned = true
			break

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if not is_dying:
		animation_player.play("walk")
		
	if is_on_wall():
		direction *= -1
		sprite.flip_h = not sprite.flip_h
		
	velocity.x = direction * SPEED
	
	move_and_slide()

func die(attacker_id: int = 0):
	if NetManager.is_online:
		if multiplayer.is_server():
			die_rpc.rpc(attacker_id)
		else:
			die_rpc.rpc_id(1, attacker_id)
	else:
		die_execute(attacker_id)
		
@rpc("any_peer", "call_local", "reliable")
func die_rpc(attacker_id: int):
	if not multiplayer.is_server():
		return
		
	die_execute.rpc(attacker_id)
	
@rpc("call_local", "reliable")
func die_execute(attacker_id: int = 0):
	GameControl.spawn_score(100, global_position, attacker_id)
	GameControl.play_stomp_swim_sound()
	is_dying = true
	set_physics_process(false)
	collision.queue_free()
	synchronizer.get_parent().remove_child(synchronizer)
	
	if animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
	
	queue_free()
	
func die_special(hit_direction: float = 1.0, attacker_id: int = 0):
	if is_dying:
		return
		
	if NetManager.is_online:
		if multiplayer.is_server():
			die_special_rpc.rpc(hit_direction, attacker_id)
		else:
			die_special_rpc.rpc_id(1, hit_direction, attacker_id)
	else:
		die_special_execute(hit_direction, attacker_id)
			
@rpc("any_peer", "reliable")
func die_special_rpc(hit_direction: float, attacker_id: int):
	if not multiplayer.is_server():
		return
	die_special_execute.rpc(hit_direction, attacker_id)
	
@rpc("call_local", "reliable")
func die_special_execute(hit_direction: float = 1.0, attacker_id: int = 0):
	if is_dying: return
	GameControl.spawn_score(100, global_position, attacker_id)
	GameControl.play_kick_kill_sound()
	
	is_dying = true
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	sprite.flip_v = true
	synchronizer.get_parent().remove_child(synchronizer)
	
	var tween = create_tween().set_parallel(true)
	var jump_height = global_position.y - 50
	var fall_depth = global_position.y + 500
	
	var x_target = global_position.x + (50 * hit_direction)
	
	var y_tween = create_tween()
	y_tween.tween_property(self, "global_position:y", jump_height, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	y_tween.tween_property(self, "global_position:y", fall_depth, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_property(self, "global_position:x", x_target, 0.9)
	tween.tween_property(sprite, "rotation_degrees", 180 * hit_direction, 0.5)

	await y_tween.finished
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dying: return
	
	if body.is_in_group("players") and velocity.y <= 0:
		if body.has_method("take_damage"):
			body.take_damage()
