extends Control

var active : bool = false
onready var tween : Tween = $Tween

signal begin_game

func _ready() -> void:
	begin_menu()

func begin_menu() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	tween.interpolate_property(self, "modulate:a", modulate.a, 1.0, 1.0, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_all_completed")
	active = true

func close_menu() -> void:
	$AudioStreamPlayer.play()
	active = false
	tween.interpolate_property(self, "modulate:a", modulate.a, 0.0, 1.0, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_all_completed")
	emit_signal("begin_game")

func _input(event: InputEvent) -> void:
	if active and event.is_action_pressed("jump"):
		close_menu()
	
	if active and event.is_action_pressed("esc"):
		get_tree().quit()

func start_gui_input(event: InputEvent) -> void:
	if active and event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			close_menu()

func _on_Start2_mouse_entered() -> void:
	$Start2.modulate.a = 0.8

func _on_Start2_mouse_exited() -> void:
	$Start2.modulate.a = 0.0


func _on_Start3_gui_input(event: InputEvent) -> void:
	if active and event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			OS.shell_open("https://twitter.com/NykolaR")
