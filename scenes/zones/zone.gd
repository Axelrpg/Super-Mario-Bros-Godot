extends Area2D

@export var environment = GameControl.LevelEnvironment.OVERWORLD

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("set_environment"):
		area.set_environment(environment)

func _on_body_entered(body: Node) -> void:
	if body.has_method("set_environment"):
		body.set_environment(environment)
