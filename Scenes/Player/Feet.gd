extends Spatial

onready var lcast : RayCast = $FootLeftRay
onready var rcast : RayCast = $FootRightRay

onready var lfoot : Spatial = $FootLeft
onready var rfoot : Spatial = $FootRight

func update_feet() -> void:
	if lcast.is_colliding():
		lfoot.transform.origin = to_local(lcast.get_collision_point())
	
	if rcast.is_colliding():
		rfoot.transform.origin = to_local(rcast.get_collision_point())
