extends Node


onready var _main_menu: CanvasLayer = $MainMenu

var _world: Spatial


func _ready() -> void:
	Network.connect("server_created", self, "_on_ready_to_play")
	Network.connect("join_success", self, "_on_ready_to_play")
	Network.connect("join_fail", self, "_on_join_fail")
	Network.connect("disconnected", self, "_on_disconnected")


func _on_ready_to_play() -> void:
	remove_child(_main_menu)
	_main_menu.queue_free()
	
	_world = load("res://world/world.tscn").instance()
	add_child(_world)
	
	
func _on_join_fail():
	print("Failed to join server")
	
	
func _on_disconnected():
	remove_child(_world)
	_world.queue_free()
	
	_main_menu = load("res://ui/main_menu.tscn").instance()
	add_child(_main_menu)	
