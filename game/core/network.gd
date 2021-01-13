extends Node


signal server_created
signal join_success
signal join_fail
signal player_list_changed
signal player_removed(player_info)
signal disconnected
signal network_tick
signal ping_updated(peer_id, value)


const NETWORK_TICK_RATE: float = 1.0 / 30.0
const PING_INTERVAL: float = 1.0
const PING_TIMEOUT: float = 5.0


var players := {}
var ping_data := {}


var _network_tick_timer: Timer


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
	
	_network_tick_timer = Timer.new()
	add_child(_network_tick_timer)
	_network_tick_timer.connect("timeout", self, "_on_network_tick_timer_timeout")
	_network_tick_timer.start(NETWORK_TICK_RATE)
	
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
	
	
func request_ping(peer_id) -> void:
	ping_data[peer_id].timer.connect("timeout", self, "_on_ping_timeout", [peer_id], CONNECT_ONESHOT)
	ping_data[peer_id].timer.start(PING_TIMEOUT)
	
	rpc_unreliable_id(peer_id, "on_ping", ping_data[peer_id].signature, ping_data[peer_id].last_ping)
	
	
remote func on_ping(signature, last_ping) -> void:
	rpc_unreliable_id(1, "on_pong", signature)
	
	
remote func on_pong(signature) -> void:
	if not get_tree().is_network_server():
		return
		
	var peer_id = get_tree().get_rpc_sender_id()
	
	if ping_data[peer_id].signature == signature:
		ping_data[peer_id].last_ping = (PING_TIMEOUT - ping_data[peer_id].timer.time_left) * 1000.0
		
		ping_data[peer_id].timer.stop()
		ping_data[peer_id].timer.disconnect("timeout", self, "_on_ping_timeout")
		ping_data[peer_id].timer.connect("timeout", self, "_on_ping_interval", [peer_id], CONNECT_ONESHOT)
		ping_data[peer_id].timer.start(PING_INTERVAL)
		
		rpc_unreliable("ping_value_changed", peer_id, ping_data[peer_id].last_ping)
		
		
remotesync func ping_value_changed(peer_id, value) -> void:
	emit_signal("ping_updated", peer_id, value)
	
	
func _on_ping_timeout(peer_id) -> void:
	ping_data[peer_id].packets_lost += 1
	ping_data[peer_id].signature += 1
	
	call_deferred("request_ping", peer_id)
	
	
func _on_ping_interval(peer_id) -> void:
	ping_data[peer_id].signature += 1
	request_ping(peer_id)
	
	
remotesync func _network_tick() -> void:
	emit_signal("network_tick")


func _on_player_connected(id):
	if get_tree().is_network_server():
		var ping_entry := {
			timer = Timer.new(),
			signature = 0,
			packets_lost = 0,
			last_ping = 0,
		}
		
		ping_entry.timer.one_shot = true
		ping_entry.timer.wait_time = PING_INTERVAL
		ping_entry.timer.process_mode = Timer.TIMER_PROCESS_IDLE
		ping_entry.timer.connect("timeout", self, "_on_ping_interval", [id], CONNECT_ONESHOT)
		ping_entry.timer.name = "ping_timer_" + str(id)
		
		add_child(ping_entry.timer)
		ping_data[id] = ping_entry
		ping_entry.timer.start()


func _on_player_disconnected(id):
	print("Player ", players[id].name, " disconnected form the server")
	
	if get_tree().is_network_server():
		ping_data[id].timer.stop()
		ping_data[id].timer.queue_free()
		ping_data.erase(id)
		
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
	print("Disconnected from server")
	
	get_tree().network_peer = null
	emit_signal("disconnected")	
	players.clear()
	GameState.player_info.network_id = 1
	
	
func _on_network_tick_timer_timeout() -> void:
	rpc_unreliable("_network_tick")
