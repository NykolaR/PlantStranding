extends StaticBody

onready var mesh : MeshInstance = $MeshInstance

var mesh_material : ShaderMaterial

export var simplex : OpenSimplexNoise

func _ready() -> void:
	mesh_material = mesh.get_surface_material(0)
	
	mesh_material.get_shader_param("noise").noise = simplex

func randomize_map() -> void:
	var s : int = randi()
	simplex.set_seed(s)
	
	var shape : HeightMapShape = $CollisionShape.shape
	
	var real_array : PoolRealArray = PoolRealArray()
	
	var height_data : Image = mesh_material.get_shader_param("noise").get_data()
	height_data.lock()
	
	shape.map_width = height_data.get_width()
	shape.map_depth = height_data.get_height()
	
	var i : int = 0
	for y in height_data.get_height():
		for x in height_data.get_width():
			real_array.append(height_data.get_pixel(x, y).r)
			i += 1
	height_data.unlock()
	
	shape.map_data = real_array
