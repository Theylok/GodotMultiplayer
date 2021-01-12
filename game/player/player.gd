extends KinematicBody


export var movement_speed := 200.0


var owner_network_id: int = 0


var _velocity := Vector3.ZERO
var _movement_input := Vector2.ZERO


func _ready() -> void:
	rset_config("translation", MultiplayerAPI.RPC_MODE_PUPPET)
	
	if get_tree().get_network_unique_id() == owner_network_id:
		Network.connect("network_tick", self, "_on_network_tick")


func _physics_process(delta: float) -> void:
	if get_tree().is_network_server():
		var movement_input = _movement_input.clamped(1.0)
		
		_velocity.x = movement_input.x * movement_speed * delta
		_velocity.z = movement_input.y * movement_speed * delta
		
		_velocity.y += 9.81 * Vector3.DOWN.y * delta
		
		_velocity = move_and_slide(_velocity, Vector3.UP)
		
		rset_unreliable("translation", translation)

func _on_network_tick() -> void:
	if get_tree().get_network_unique_id() == owner_network_id:
		var movement_input := Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
		)
		if get_tree().is_network_server():
			_movement_input = movement_input
		else:
			rpc_unreliable_id(1, "_server_set_movement_input", movement_input)


remote func _server_set_movement_input(input: Vector2) -> void:
	if get_tree().get_rpc_sender_id() != owner_network_id:
		return
		
	_movement_input = input
