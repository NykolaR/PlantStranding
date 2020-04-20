extends Spatial

const player_scene : PackedScene = preload("res://Scenes/Player/Player.tscn")

onready var player : Spatial# = $Player
onready var player_indicator : Sprite = $Minimap/Player

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen

func _process(delta: float) -> void:
	if player:
		player_indicator.rotation = -player.camera_rotation()
		player_indicator.visible = true
		update_minimap()
	else:
		player_indicator.visible = false

func update_minimap() -> void:
	player_indicator.position.x = player.transform.origin.x + 50
	player_indicator.position.y = player.transform.origin.z + 100

func end_game() -> void:
	$Camera.current = true
	for child in $PlayerHolder.get_children():
		$PlayerHolder.remove_child(child)
	
	$MainMenu.begin_menu()

func begin_game() -> void:
	var player_s : Spatial = player_scene.instance()
	
	for child in $PlayerHolder.get_children():
		$PlayerHolder.remove_child(child)
	
	$PlayerHolder.add_child(player_s)
	player = player_s
	player_s.global_transform.origin = $PlayerSpawnPos.global_transform.origin
	player.warp_visual()
	player.connect("game_over", self, "end_game")
	#player.set_camera($Camera)
	#$Camera.set_target(player.get_camera_target())
	$Camera.current = false
