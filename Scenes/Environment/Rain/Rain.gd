extends Area

onready var raycast : RayCast = $RayCast

func initialize() -> void:
	raycast.force_raycast_update()
	if raycast.is_colliding():
		global_transform.origin.y = raycast.get_collision_point().y
	
	raycast.enabled = false
	
	$LifeSpan.wait_time = 45 + rand_range(-15, 15)
