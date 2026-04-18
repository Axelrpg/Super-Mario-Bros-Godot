extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var speed = 250
var bounce_force = -150
var direction = 1

func _ready() -> void:
	add_to_group("fireballs")
	velocity.x = speed * direction
	animation_player.play("idle")
	
func  _physics_process(delta: float) -> void:
	velocity.y += get_gravity().y * delta
	
	if is_on_floor():
		velocity.y = bounce_force
		
	if is_on_wall():
		explode()
		
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("enemies"):
			if collider.has_method("die_special"):
				collider.die_special(self.direction)
			explode()
			
	move_and_slide()
			
func explode():
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	
	animation_player.play("explode")
	await animation_player.animation_finished
	queue_free()

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
