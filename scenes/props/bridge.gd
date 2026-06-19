extends Node2D

@onready var tiles = $Tiles
@onready var axe: Area2D = $Axe
@onready var axe_sprite: Sprite2D = $Axe/Sprite2D
@onready var axe_animation_player: AnimationPlayer = $Axe/AnimationPlayer

func _ready() -> void:
	axe_animation_player.play("idle")

func destroy_bridge():
	var bowser = get_tree().get_first_node_in_group("bowser")
	if bowser:
		bowser.disable()
	
	var tile_list = tiles.get_children()
	tile_list.reverse()
	
	for tile in tile_list:
		await get_tree().create_timer(0.1).timeout
		GameControl.play_brick_sound()
		tile.queue_free()
		
	await get_tree().process_frame
	if bowser:
		await bowser.die_by_axe().finished
		
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		walk_to_toad(player)
		
func walk_to_toad(player: CharacterBody2D):
	GameControl.play_level_complete_music()
	var toad_pos = get_tree().get_first_node_in_group("toad").global_position
	player.auto_walking_finished.connect(func(): drain_time_bonus(), CONNECT_ONE_SHOT)
	player.start_auto_walking(toad_pos.x - 32)
	
func drain_time_bonus():
	while GameControl.time_left > 0:
		var reduction = min(GameControl.time_left, 2.0)
		GameControl.time_left -= reduction
		
		if GameControl.is_multiplayer:
			for p in get_tree().get_nodes_in_group("players"):
				GameControl.add_score(int(50 * reduction), p.player_id)
		else:
			GameControl.total_score += 50 * reduction
		
		GameControl.update_ui()
		await get_tree().create_timer(0.01).timeout
	
	show_victory_ui()
		
func show_victory_ui():
	await get_tree().create_timer(5).timeout
	
	for p in get_tree().get_nodes_in_group("players"):
		GameControl.save_player_state(p)
	
	get_tree().change_scene_to_file("res://scenes/levels/singleplayer/thank_you_screen.tscn")

func _on_axe_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		axe.set_deferred("monitoring", false)
		axe_sprite.visible = false
		
		body.start_cutscene()
		
		var all_players = get_tree().get_nodes_in_group("players")
		for p in all_players:
			if p != body:
				p.set_physics_process(false)
				p.velocity = Vector2.ZERO
				p.play_anim("die")
		
		GameControl.stop_level_song_music()
		GameControl.spawn_score(5000, body.global_position, body)
		
		while not body.is_on_floor():
			await get_tree().process_frame
		
		destroy_bridge()
