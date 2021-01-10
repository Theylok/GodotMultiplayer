extends KinematicBody


export var movement_speed := 200.0


onready var _camera: Camera = $Pitch/SpringArm/Camera


var _velocity := Vector3.ZERO


func _ready() -> void:
	rset_config("translation", MultiplayerAPI.RPC_MODE_PUPPET)
	
	if is_network_master():
		_camera.current = true


func _physics_process(delta: float) -> void:
	if is_network_master():
		var movement_input := Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
		)
		movement_input = movement_input.clamped(1.0)
		
		_velocity.x = movement_input.x * movement_speed * delta
		_velocity.z = movement_input.y * movement_speed * delta
		
		_velocity.y += 9.81 * Vector3.DOWN.y * delta
		
		_velocity = move_and_slide(_velocity, Vector3.UP)
		
		rset("translation", translation)
		
