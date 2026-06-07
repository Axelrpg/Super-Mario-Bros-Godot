extends CharacterBody2D

@export var current_env = GameControl.LevelEnvironment.OVERWORLD
@export var texture_overworld: Texture2D
@export var texture_underworld: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var speed = 120
var jump_force = -250

var direction: int = 1

func _ready() -> void:
	animation_player.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.y = jump_force
		
	if is_on_wall():
		direction *= -1
	
	velocity.x = direction * speed
	
	move_and_slide()
	
func set_environment(env) -> void:
	current_env = env
	update_texture()

func update_texture() -> void:
	match current_env:
		GameControl.LevelEnvironment.OVERWORLD:
			sprite.texture = texture_overworld
		GameControl.LevelEnvironment.UNDERWORLD:
			sprite.texture = texture_underworld
	
func set_direction():
	pass

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		if body.has_method("become_starman"):
			GameControl.spawn_score(1000, global_position, body)
			body.become_starman()
		queue_free()
