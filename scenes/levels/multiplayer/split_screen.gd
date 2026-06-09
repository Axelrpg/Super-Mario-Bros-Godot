extends Control

@onready var left = $HBoxContainer/Left
@onready var right = $HBoxContainer/Right
@onready var divider = $HBoxContainer/Divider

@onready var viewport_left = $HBoxContainer/Left/SubViewport
@onready var viewport_right = $HBoxContainer/Right/SubViewport

@onready var mario = $"HBoxContainer/Left/SubViewport/World 1-2/Mario"
@onready var luigi = $"HBoxContainer/Left/SubViewport/World 1-2/Luigi"

@onready var camera_left = $HBoxContainer/Left/SubViewport/CameraMultiplayer
@onready var camera_right = $HBoxContainer/Right/SubViewport/CameraMultiplayer

@onready var hud = $HUD
@onready var multiplayer_hud = $MultiplayerHUD

func _ready() -> void:
	if not GameControl.is_multiplayer:
		right.visible = false
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		divider.visible = false
		camera_left.target_player = mario
		hud.visible = true
		return
		
	viewport_right.world_2d = viewport_left.world_2d
	await get_tree().process_frame
	camera_left.target_player = mario
	camera_right.target_player = luigi
	multiplayer_hud.visible = true
