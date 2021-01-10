extends Node


signal server_created
signal join_success
signal join_fail
signal player_list_changed
signal player_removed(player_info)


var players := {}


func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_disconnected_from_server")
	
	
func create_server(port: int, max_players: int) -> void:
	var net = NetworkedMultiplayerENet.new()
	
	if net.create_server(port, max_players) != OK:
		print("Failed to create server")
		return
		
	get_tree().network_peer = net
	
	emit_signal("server_created")
	register_player(GameState.player_info)


func join_server(ip_address: String, port: int) -> void:
	var net = NetworkedMultiplayerENet.new()
	
	if net.create_client(ip_address, port) != OK:
		print("Failed to create client")
		emit_signal("join_fail")
		return
		
	get_tree().network_peer = net


remote func register_player(info: Dictionary) -> void:
	if get_tree().is_network_server():
		for id in players:
			rpc_id(info.network_id, "register_player", players[id])
			if id != 1:
				rpc_id(id, "register_player", info)
				
	print("Player registered: " + info.name)
	players[info.network_id] = info
	emit_signal("player_list_changed")
	
	
remote func unregister_player(id: int) -> void:
	print("Player unregistered: " + players[id].name)
	var player_info = players[id]
	players.erase(id)
	emit_signal("player_list_changed")
	emit_signal("player_removed", player_info)


func _on_player_connected(id):
	pass


func _on_player_disconnected(id):
	print("Player ", players[id].name, " disconnected form the server")
	
	if get_tree().is_network_server():
		unregister_player(id)
		rpc("unregister_player", id)


func _on_connected_to_server():
	GameState.player_info.network_id = get_tree().get_network_unique_id()
	
	rpc_id(1, "register_player", GameState.player_info)
	register_player(GameState.player_info)

	emit_signal("join_success")

func _on_connection_failed():
	emit_signal("join_fail")
	get_tree().network_peer = null


func _on_disconnected_from_server():
	players.clear()
	GameState.player_info.network_id = 1
