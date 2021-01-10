extends CanvasLayer


onready var player_name: LineEdit = find_node("PlayerName")

onready var server_port: LineEdit = find_node("ServerPort")
onready var max_players: SpinBox = find_node("MaxPlayers")

onready var ip_address: LineEdit = find_node("IpAddress")
onready var join_port: LineEdit = find_node("JoinPort")


func _on_CreateServerButton_pressed() -> void:
	GameState.player_info.name = player_name.text
	Network.create_server(int(server_port.text), int(max_players.value))


func _on_JoinServerButton_pressed() -> void:
	GameState.player_info.name = player_name.text
	Network.join_server(ip_address.text, int(join_port.text))
