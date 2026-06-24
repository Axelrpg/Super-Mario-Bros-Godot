extends Control

@onready var name_input: LineEdit = $VBoxContainer/NameInput
@onready var address_input: LineEdit = $VBoxContainer/AddressInput
@onready var players_list: VBoxContainer = $VBoxContainer/PlayersList
@onready var btn_start: Button = $VBoxContainer/BtnStart
@onready var btn_host: Button = $VBoxContainer/BtnHost
@onready var btn_join: Button = $VBoxContainer/BtnJoin

func _ready() -> void:
	NetManager.player_list_changed.connect(refresh_player_list)
	btn_start.hide()
	
func refresh_player_list() -> void:
	for child in players_list.get_children():
		child.queue_free()
		
	for id in NetManager.players:
		var role = "Host" if id == 1 else "Cliente"
		var label = Label.new()
		label.text = "• %s (%s)" % [NetManager.players[id]["name"], role]
		players_list.add_child(label)
		
	if multiplayer.is_server():
		btn_start.disabled = NetManager.players.size() < 2
	
func _on_btn_host_pressed() -> void:
	NetManager.my_name = name_input.text.strip_edges()
	if NetManager.my_name.is_empty():
		NetManager.my_name = "Host"
	NetManager.host_game()
	name_input.editable = false
	btn_host.hide()
	btn_join.hide()
	address_input.hide()
	btn_start.show()

func _on_btn_join_pressed() -> void:
	NetManager.my_name = name_input.text.strip_edges()
	if NetManager.my_name.is_empty():
		NetManager.my_name = "Player"
	NetManager.join_game()
	name_input.editable = false
	btn_host.hide()
	btn_join.hide()

func _on_btn_start_pressed() -> void:
	NetManager.start_game()
