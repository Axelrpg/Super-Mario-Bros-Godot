extends CharacterBody2D

@export var fire_scene: PackedScene
@export var bridge: Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var fire_spawn: Marker2D = $FireSpawnPoint

@onready var sfx_fire: AudioStreamPlayer = $Sounds/SFXFire
@onready var sfx_bowser_fall: AudioStreamPlayer = $Sounds/SFXBowserFall

var jump_interval: float = 3.0
var fire_interval: float = 2.0
var health: int = 10
var walk_speed: float = 40.0
var jump_velocity: float = -300
var is_dying: bool = false
var bridge_left: float = 0.0
var bridge_right: float = 0.0
var move_timer: float = 0.0
var move_interval: float = 0.0
var is_hitting: bool = false
var direction: int = -1

func _ready() -> void:
	if bridge:
		var node = bridge.get_node("Tiles")
		var tiles = node.get_children()
		if tiles.size() > 0:
			bridge_left = min(tiles[0].global_position.x, tiles[-1].global_position.x)
			bridge_right = max(tiles[0].global_position.x, tiles[-1].global_position.x)
			
	start_routines()
	
func _physics_process(delta: float) -> void:
	if is_dying: return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	move_timer -= delta
	if move_timer <= 0:
		direction = [-1, 1].pick_random()
		move_timer = randf_range(1.0, 3.0)
	
	if global_position.x <= bridge_left:
		direction = 1
		move_timer = randf_range(1.0, 3.0)
	elif global_position.x >= bridge_right:
		direction = -1
		move_timer = randf_range(1.0, 3.0)
		
	velocity.x = direction * walk_speed
	animation_player.play("idle")
	
	move_and_slide()

func start_routines():
	jump_routine()
	fire_routine()

func jump_routine():
	while not is_dying:
		await get_tree().create_timer(jump_interval).timeout
		if not is_dying and is_on_floor():
			velocity.y = jump_velocity
	
func fire_routine():
	while not is_dying:
		await get_tree().create_timer(fire_interval).timeout
		if not is_dying:
			shoot_fire()
	
func shoot_fire():
	var fire = fire_scene.instantiate()
	get_parent().add_child(fire)
	fire.global_position = fire_spawn.global_position
	fire.global_position.y += randf_range(0, 8.0)
	sfx_fire.play()
	
func take_hit():
	if is_hitting: return
	is_hitting = true
	
	health -= 1
	if health <= 0:
		die()
	else:
		var tween = create_tween()
		for i in 4:
			tween.tween_property(self, "modulate:a", 0.0, 0.1)
			tween.tween_property(self, "modulate:a", 1.0, 0.1)
			
		tween.finished.connect(func(): is_hitting = false)
	
func die():
	is_dying = true
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	
	var tween = create_tween().set_parallel(true)
	var jump_height = global_position.y - 50
	var fall_depth = global_position.y + 500
	
	var x_target = global_position.x + 50
	
	var y_tween = create_tween()
	y_tween.tween_property(self, "global_position:y", jump_height, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	y_tween.tween_property(self, "global_position:y", fall_depth, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_property(self, "global_position:x", x_target, 0.9)
	tween.tween_property(sprite, "rotation_degrees", 180, 0.5)

	await y_tween.finished
	queue_free()
	
func die_by_axe() -> Tween:
	sfx_bowser_fall.play()
	var fall_velocity = Vector2(0, 0)
	
	var tween = create_tween()
	tween.tween_method(func(delta: float):
		fall_velocity.y += 200 * delta
		global_position += fall_velocity * delta
	, 0.0, 1.0, 2.0)
	
	tween.finished.connect(func(): queue_free())
	return tween
	
func disable():
	if is_dying: return
	is_dying = true
	set_physics_process(false)
	hitbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage()
