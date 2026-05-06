extends Control

@onready var players_list = $MarginContainer/PlayerListMenu/PlayersList
@onready var start_btn = $MarginContainer/PlayerListMenu/StartButton
@onready var name_input = $MarginContainer/SetupMenu/NameInput
@onready var ip_input = $MarginContainer/SetupMenu/IPInput
@onready var setup_menu = $MarginContainer/SetupMenu
@onready var player_list_menu = $MarginContainer/PlayerListMenu

func _ready() -> void:
	NetManager.player_list_changed.connect(_update_player_list)
	NetManager.server_shut_down.connect(_on_host_disconnected)
	start_btn.visible = false
	
@rpc("call_local", "reliable")
func start_game():
	get_tree().change_scene_to_file("res://scenes/levels/singleplayer/world_1_1.tscn")
	
func _update_player_list():
	players_list.clear()
	for id in NetManager.players:
		var n = NetManager.players[id]
		var suffix = ""
		if id == multiplayer.get_unique_id(): suffix = " (Tú)"
		if id == 1: suffix += " [HOST]"
		
		players_list.add_item(n + suffix)
		
	if multiplayer.is_server():
		start_btn.disabled = NetManager.players.size() < 2
	
func _on_host_btn_pressed() -> void:
	var player_name = name_input.text
	if player_name == "": player_name = "Host"
	NetManager.create_game(player_name)
	setup_menu.visible = false
	player_list_menu.visible = true
	start_btn.visible = true
	_update_player_list()
	
func _on_join_btn_pressed() -> void:
	var player_name = name_input.text
	var ip = ip_input.text
	if player_name == "": player_name = "Player"
	NetManager.join_game(ip, player_name)
	setup_menu.visible = false
	player_list_menu.visible = true

func _on_start_button_pressed() -> void:
	start_game.rpc()

func _on_back_button_pressed() -> void:
	NetManager.disconnect_game()
	players_list.clear()
	player_list_menu.visible = false
	setup_menu.visible = true
	start_btn.visible = false
	
func _on_host_disconnected():
	player_list_menu.visible = false
	setup_menu.visible = true
	players_list.clear()
