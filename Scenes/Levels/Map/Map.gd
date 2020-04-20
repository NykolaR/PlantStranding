extends StaticBody

const rain_scene : PackedScene = preload("res://Scenes/Environment/Rain/Rain.tscn")

onready var rains : Spatial = $Rains

func _ready() -> void:
	randomize()
	
	for i in 30:
		spawn_rain()

func spawn_rain() -> void:
	if rains.get_child_count() >= 25 or randf() < 0.1:
		return
	
	var rain : Spatial = rain_scene.instance()
	
	var pos : Vector3 = Vector3(rand_range(-50, 50), 0, rand_range(-100, 100))
	
	rains.add_child(rain)
	rain.transform.origin = pos
	rain.initialize()
