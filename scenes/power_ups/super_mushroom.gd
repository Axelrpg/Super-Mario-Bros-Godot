extends BaseMushroom

func _on_detection_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("players") or not can_be_collected:
		return
		
	if NetManager.is_multiplayer_online:
		if not body.is_multiplayer_authority():
			return
			
		if multiplayer.is_server():
			request_collect(body.get_path())
		else:
			request_collect.rpc_id(1, body.get_path())
	else:
		apply_collection(body)

@rpc("any_peer", "reliable")
func request_collect(mario_path: NodePath) -> void:
	if not multiplayer.is_server():
		return
	if not can_be_collected:
		return
		
	var mario = get_node_or_null(mario_path)
	if not mario:
		return
		
	can_be_collected = false
	apply_collection_rpc.rpc(mario_path)
	
@rpc("authority", "call_local", "reliable")
func apply_collection_rpc(mario_path: NodePath) -> void:
	var mario = get_node_or_null(mario_path)
	if not mario:
		return
	apply_collection(mario)
	
func apply_collection(body: Node2D) -> void:
	if body.current_state != body.PlayerState.SMALL:
		GameControl.spawn_score(1000, global_position, body)
	else:
		if body.has_method("take_power_up"):
			body.take_power_up(body.PlayerState.SUPER)
			GameControl.spawn_score(1000, global_position, body)
			GameControl.play_power_up_sound()
		collect_rpc.rpc()
