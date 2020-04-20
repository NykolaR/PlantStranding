extends RigidBody

onready var visual : Spatial = $Visual
onready var rotation_node : Spatial = $Visual/Rotation
onready var player : Spatial = $Visual/Rotation/Player
onready var camera_pivot : Camera = $Camera
onready var camera_rot : Spatial = $Visual/Camera
onready var eyes : Sprite = $Visual/Rotation/Player/HeadTex/Eyes
onready var ground_ray : RayCast = $GroundRay
onready var feet : Spatial = $Visual/Rotation/Player/Feet
onready var pot : Spatial = $Visual/Rotation/Player/Pot
onready var tween : Tween = $Tween
onready var jump : AudioStreamPlayer = $Jump

onready var animation : AnimationPlayer = $Visual/AnimationPlayer
onready var animtree : AnimationTree = $Visual/AnimationTree2
var statemachine : AnimationNodeStateMachinePlayback

export var movement_speed : float = 3.0
export var jump_velocity : float = 6.0

var p_curr : Vector3 = Vector3()
var p_prev : Vector3 = Vector3()

var input_vector : Vector2 = Vector2()
var movement_vector : Vector3 = Vector3()

var game_win : bool = false

signal game_over

func _ready() -> void:
	camera_pivot.current = true
	var head_shader : SpatialMaterial = $Visual/Rotation/Player/Head.get_surface_material(0)
	head_shader.albedo_texture = $Visual/Rotation/Player/HeadTex.get_texture()
	
	visual.set_as_toplevel(true)
	
	statemachine = animtree.get("parameters/StateMachine/playback")
	animtree.active = true
	
	statemachine.start("Stand")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#set_process_input(false)

func _input(event: InputEvent) -> void:
	if game_win and event.is_action_pressed("jump"):
		emit_signal("game_over")
	
	if event.is_action_pressed("esc"):
		emit_signal("game_over")

func get_camera_target() -> Spatial:
	return $Visual/Camera/CameraWant as Spatial

func set_camera(camera : Spatial) -> void:
	camera_pivot = camera

func freeze_player() -> void:
	mode = RigidBody.MODE_STATIC

func cargo_down() -> void:
	mode = RigidBody.MODE_STATIC
	$AnimationPlayer.play("cargodown")

func warp_visual() -> void:
	p_curr = global_transform.origin
	p_prev = global_transform.origin
	visual.global_transform.origin = global_transform.origin

func _physics_process(delta: float) -> void:
	eye_rotation()
	if mode == MODE_STATIC:
		return
	
	p_prev = p_curr
	p_curr = global_transform.origin
	
	#rotation_node.rotation.x = rotation.rotated(Vector3.UP, rotation.y).x
	#rotation_node.rotation.z = rotation.rotated(Vector3.UP, rotation.y).z
	rotation_node.transform.basis = transform.basis
	
	rotation_update(delta)
	
	if ground_ray.is_colliding():
		feet.update_feet()
	
	movement(delta)
	
	if transform.origin.y < -50:
		# game over
		pass

func camera_rotation() -> float:
	return camera_rot.rotation.y

func eye_rotation() -> void:
	var dot : float = camera_pivot.global_transform.basis.z.dot(player.global_transform.basis.z)
	var dot2 : float = camera_pivot.global_transform.basis.z.dot(player.global_transform.basis.x)
	
	if dot <= 0:
		dot += 1
		if dot2 >= 0:
			eyes.position.x = 5 + (dot * 6)
		else:
			eyes.position.x = 5 - (dot * 6)
	else:
		eyes.position.x = 16

func _process(delta: float) -> void:
	poll_inputs()
	var f = Engine.get_physics_interpolation_fraction()
	var i_origin : Vector3 = lerp(p_prev, p_curr, f)
	
	visual.global_transform.origin = i_origin

# ew
func poll_inputs() -> void:
	input_vector.x = max(Input.get_action_strength("right"), float(Input.is_action_pressed("dpad_right"))) - max(Input.get_action_strength("left"), float(Input.is_action_pressed("dpad_left")))
	input_vector.y = max(Input.get_action_strength("down"), float(Input.is_action_pressed("dpad_down"))) - max(Input.get_action_strength("up"), float(Input.is_action_pressed("dpad_up")))
	
	movement_vector = Vector3(input_vector.x, 0, input_vector.y)
	#movement_vector = movement_vector.rotated(Vector3.UP, camera_pivot.rotation.y).rotated(Vector3.UP, rotation.y).normalized() * min(movement_vector.length_squared(), 1)
	movement_vector = movement_vector.rotated(Vector3.UP, camera_pivot.rotation.y).rotated(Vector3.UP, rotation.y).normalized() * min(movement_vector.length_squared(), 1)

# Handle character movement
func movement(delta : float) -> void:
	if not movement_vector.length() < 0.01 and ground_ray.is_colliding():
		animtree["parameters/TimeScale/scale"] = max(movement_vector.length_squared() * 2, 0.5)
		if statemachine.is_playing():
			statemachine.travel("Walk")
	else:
		if statemachine.is_playing():
			statemachine.travel("Stand")

func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	if ground_ray.is_colliding():
		state.linear_velocity.x = (movement_vector * movement_speed).x
		state.linear_velocity.z = (movement_vector * movement_speed).z
		
		if Input.is_action_just_pressed("jump"):
			if pot.can_plant:
				mode = RigidBody.MODE_STATIC
				finish_game()
			else:
				jump.play()
				state.linear_velocity.y = jump_velocity

func finish_game() -> void:
	pot.global_transform = get_tree().get_nodes_in_group("FlowerPos")[0].global_transform
	pot.plant_exited(null)
	pot.planted()
	
	tween.interpolate_property(camera_rot, "translation:y", camera_rot.translation.y, pot.get_top(), 7, Tween.TRANS_LINEAR)
	tween.interpolate_property($Control, "modulate:a", 0, 1, 1, Tween.TRANS_LINEAR)
	tween.interpolate_method(self, "set_score", 1, pot.get_score(), 7, Tween.TRANS_SINE, Tween.EASE_OUT_IN)
	tween.start()
	yield(tween, "tween_all_completed")
	pot.bloom()
	$Control/Label.visible = true
	game_win = true
	set_process_input(true)

func set_score(new : int) -> void:
	$Control/Score2.text = str(new)

func rotation_update(delta : float, instant : bool = false) -> void:
	if mode == MODE_STATIC:
		return
	#player.global_transform = player.global_transform.looking_at(player.transform.origin + movement_vector, Vector3.UP)
	#player.transform = player.transform.looking_at(movement_vector + player.transform.origin, Vector3.UP)
	if movement_vector == Vector3() or not ground_ray.is_colliding():
		return
	
	#var t : Transform = player.transform.looking_at(movement_vector + player.transform.origin, Vector3.UP)
	var t : Transform = player.transform.looking_at(movement_vector.rotated(Vector3.UP, -rotation.y) + player.transform.origin, Vector3.UP)
	#player.transform = t
	
	var old_quat : Quat = Quat(player.transform.basis)
	var new_quat : Quat = Quat(t.basis)
	
	var newer_quat : Quat = new_quat
	
	if not instant:
		newer_quat = old_quat.slerp(new_quat, 1 - pow(0.0000000000000001, delta))
	
	player.transform.basis = Basis(newer_quat)

func flower_spawned() -> void:
	mode = MODE_RIGID
