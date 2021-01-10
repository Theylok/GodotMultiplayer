extends Node


onready var main_menu: CanvasLayer = $MainMenu


func _ready() -> void:
	Network.connect("server_created", self, "_on_ready_to_play")
	Network.connect("join_success", self, "_on_ready_to_play")
	Network.connect("join_fail", self, "_on_join_fail")


func _on_ready_to_play() -> void:
	remove_child(main_menu)
	main_menu.queue_free()
	
	var world = load("res://world/world.tscn").instance()
	add_child(world)
	
	
func _on_join_fail():
	print("Failed to join server")
