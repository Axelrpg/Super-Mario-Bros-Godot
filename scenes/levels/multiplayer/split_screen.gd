extends Control

var level_scene: PackedScene

@onready var left = $HBoxContainer/Left
@onready var right = $HBoxContainer/Right
@onready var divider = $HBoxContainer/Divider

@onready var viewport_left = $HBoxContainer/Left/SubViewport
@onready var viewport_right = $HBoxContainer/Right/SubViewport

@onready var camera_left = $HBoxContainer/Left/SubViewport/CameraMultiplayer
@onready var camera_right = $HBoxContainer/Right/SubViewport/CameraMultiplayer

@onready var hud = $HUD
@onready var multiplayer_hud = $MultiplayerHUD

var world_instance: Node2D
var mario: CharacterBody2D
var luigi: CharacterBody2D

func _ready() -> void:
	level_scene = GameControl.next_level_scene
	world_instance = level_scene.instantiate()
	viewport_left.add_child(world_instance)
	
	await get_tree().process_frame
	
	mario = world_instance.get_node("Mario")
	luigi = world_instance.get_node("Luigi")
	camera_left.setup(world_instance, mario)
	
	if GameControl.player_states.has(mario.player_id):
		mario.set_state(GameControl.player_states[mario.player_id])
		GameControl.player_states.erase(mario.player_id)
	
	if not GameControl.is_multiplayer:
		right.visible = false
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		divider.visible = false
		hud.visible = true
		return
		
	if GameControl.player_states.has(luigi.player_id):
		luigi.set_state(GameControl.player_states[luigi.player_id])
		
	viewport_right.world_2d = viewport_left.world_2d
	await get_tree().process_frame
	camera_right.setup(world_instance, luigi)
	multiplayer_hud.visible = true
