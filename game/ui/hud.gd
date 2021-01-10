extends CanvasLayer


onready var local_player_name: Label = find_node("LocalPlayerName")
onready var player_list: VBoxContainer = find_node("PlayerList")

func _ready() -> void:
	Network.connect("player_list_changed", self, "_on_player_list_changed")
	
	local_player_name.text = GameState.player_info.name
	
	
func _on_player_list_changed() -> void:
	for child in player_list.get_children():
		child.queue_free()
		
	for id in Network.players:
		if id != GameState.player_info.network_id:
			var label = Label.new()
			label.text = Network.players[id].name
			player_list.add_child(label)
