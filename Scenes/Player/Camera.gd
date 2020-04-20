extends Position3D

export var camera_speed : float = 2.5
export var cam_invert : bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if cam_invert:
			rotate_y(event.relative.x * camera_speed * 0.001)
		else:
			rotate_y(-event.relative.x * camera_speed * 0.001)
	
	if event.is_action_pressed("mirror"):
		cam_invert = not cam_invert

# Camera rotation
func _process(delta: float) -> void:
	var cam_movement : float = Input.get_action_strength("cam_right") - Input.get_action_strength("cam_left")
	if cam_invert:
		cam_movement *= -1
	
	rotate_y(cam_movement * delta * camera_speed)
