extends CharacterBody2D
class_name BaseMushroom

var SPEED = 50
var direction = -1
var active = false

var can_be_collected: bool = true

func _ready() -> void:
	set_physics_process(false)
	modulate.a = 0
	
	if has_method("disable_collection"):
		disable_collection(0.5)
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:y", global_position.y - 8, 1.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	await tween.finished
	if is_instance_valid(self):
		set_physics_process(true)

func  _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.x = direction * SPEED
		
	velocity += get_gravity() * delta
	move_and_slide()
	
	if is_on_wall():
		direction *= -1
	
func set_direction(new_dir: int = 1):
	direction = new_dir
	
func disable_collection(duration: float):
	can_be_collected = false
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(duration).timeout
	can_be_collected = true
