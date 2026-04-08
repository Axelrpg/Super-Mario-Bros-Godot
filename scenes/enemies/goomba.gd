extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var SPEED = 50
var direction = -1

var is_dying = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if not is_dying:
		animation_player.play("walk")
		
	if is_on_wall():
		direction *= -1
		sprite.flip_h = not sprite.flip_h
		
	velocity.x = direction * SPEED
	
	move_and_slide()

func die():
	is_dying = true
	set_physics_process(false)
	collision.queue_free()
	
	if animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
		
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dying: return
	
	if body.is_in_group("players") and velocity.y <= 0:
		if body.has_method("take_damage"):
			body.take_damage()
