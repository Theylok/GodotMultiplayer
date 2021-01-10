extends Spatial


func _ready() -> void:
	if get_tree().is_network_server():
		Network.connect("player_removed", self, "_on_player_removed")
	
	if get_tree().is_network_server():
		spawn_players(GameState.player_info)
	else:
		rpc_id(1, "spawn_players", GameState.player_info)


remote func spawn_players(player_info: Dictionary):
	if get_tree().is_network_server() and player_info.network_id != 1:
		for id in Network.players:
			if id != player_info.network_id:
				rpc_id(player_info.network_id, "spawn_players", Network.players[id])
				
			if id != 1:
				rpc_id(id, "spawn_players", player_info)
				
	var player_scene = load("res://player/local_player.tscn")
	var player = player_scene.instance()
	
	if player_info.network_id != 1:
		player.set_network_master(player_info.network_id)
		
	player.set_name(str(player_info.network_id))
	
	add_child(player)


remote func despawn_player(player_info: Dictionary) -> void:
	if get_tree().is_network_server():
		for id in Network.players:
			if id == player_info.network_id or id == 1:
				continue
				
			rpc_id(id, "despawn_player", player_info)
			
	var player = get_node(str(player_info.network_id))
	player.queue_free()


func _on_player_removed(player_info: Dictionary) -> void:
	despawn_player(player_info)
