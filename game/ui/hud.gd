extends CanvasLayer


onready var player_list: VBoxContainer = find_node("PlayerList")


func _ready() -> void:
	Network.connect("player_list_changed", self, "_on_player_list_changed")
	Network.connect("ping_updated", self, "_on_ping_updated")
	
	
func _on_player_list_changed() -> void:
	for child in player_list.get_children():
		child.queue_free()
		
	for id in Network.players:
		var label := Label.new()
		label.name = str(id)
		label.text = Network.players[id].name
		player_list.add_child(label)
			
			
func _on_ping_updated(peer_id, value) -> void:
	var label: Label =  player_list.get_node(str(peer_id))
	if label:
		label.text = Network.players[peer_id].name + " (" + str(int(value)) + "ms)"
