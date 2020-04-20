extends MeshInstance

onready var top : Spatial = $Top
onready var stem : Spatial = $Stem
onready var bar : ProgressBar = $ProgressBar
onready var tween : Tween = $Tween
onready var status : Label = $StatusLabel
onready var health_label : Label = $Health
onready var pot_hit : AudioStreamPlayer = $PotHit
onready var pot_broken : AudioStreamPlayer = $PotBroken

export var moist : Color
export var dry : Color
export var soaked : Color

var total_growth : float = 0
var moisture : float = 70
var rain_count : int = 0
var health : float = 100
var can_plant : bool = false

var bar_box : StyleBoxFlat

signal flower_spawned
signal cargo_down

func _ready() -> void:
	bar_box = bar.get_stylebox("fg")
	bar_box.set("bg_color", moist)
	update_cargo_health()
	set_process(false)

func get_top() -> float:
	return $Top.transform.origin.y

func _process(delta: float) -> void:
	if moisture < 75 and moisture > 30:
		stem.scale.y += delta * 1
		#stem.scale.y += delta * 5
	else:
		stem.scale.y -= delta * 0.25
		stem.scale.y = max(0.1, stem.scale.y)
	
	top.transform.origin.y = stem.scale.y * 0.3 - 0.005

func pot_hurt(body: Node) -> void:
	health -= 1
	if not $Timer.is_stopped():
		pot_hit.play()
	$Hurtbox/CollisionShape.disabled = true
	$Hurtbox/IFrames.start()
	update_cargo_health()
	
	health_test()

func rain_entered(area: Area) -> void:
	rain_count += 1

func rain_exited(area: Area) -> void:
	rain_count -= 1

func update_cargo_health() -> void:
	health = clamp(health, 0, 100)
	health_label.text = "CARGO HEALTH\n" + ("%1.1f" % health) + "%"
	health_label.modulate.g = health / 100.0
	health_label.modulate.b = health / 100.0

func plant_update() -> void:
	if $AnimationPlayer.is_playing():
		return
	
	if rain_count > 0:
		moisture += 3
		if moisture >= 75 and moisture < 78:
			tween.interpolate_property(bar_box, "bg_color", bar_box.bg_color, soaked, 2, Tween.TRANS_LINEAR)
			status.text = "SOAKED"
			var status_a : float = status.modulate.a
			status.modulate = soaked
			status.modulate.a = status_a
			tween.interpolate_property(status, "modulate:a", status.modulate.a, 1.0, 1, Tween.TRANS_LINEAR)
			tween.start()
		if moisture >= 26 and moisture < 29:
			tween.interpolate_property(bar_box, "bg_color", bar_box.bg_color, moist, 2, Tween.TRANS_LINEAR)
			tween.interpolate_property(status, "modulate:a", status.modulate.a, 0.0, 1, Tween.TRANS_LINEAR)
			tween.start()
	else:
		moisture -= 1
		if moisture == 74:
			tween.interpolate_property(bar_box, "bg_color", bar_box.bg_color, moist, 2, Tween.TRANS_LINEAR)
			tween.interpolate_property(status, "modulate:a", status.modulate.a, 0.0, 1, Tween.TRANS_LINEAR)
			tween.start()
		if moisture == 25:
			tween.interpolate_property(bar_box, "bg_color", bar_box.bg_color, dry, 2, Tween.TRANS_LINEAR)
			status.text = "DRY"
			var status_a : float = status.modulate.a
			status.modulate = dry
			status.modulate.a = status_a
			tween.interpolate_property(status, "modulate:a", status.modulate.a, 1.0, 1, Tween.TRANS_LINEAR)
			tween.start()
	
	moisture = clamp(moisture, 0, 100)
	bar.value = moisture
	
	if moisture >= 75:
		health -= 0.2
	if moisture <= 25:
		health -= 0.5
	
	update_cargo_health()
	health_test()

func planted() -> void:
	$Timer.stop()
	set_process(false)
	$Hurtbox/CollisionShape.disabled = true
	$Rainbox/CollisionShape.disabled = true
	$Plantbox/CollisionShape.disabled = true

func bloom() -> void:
	$AnimationPlayer.play("bloom")

func get_score() -> int:
	var ret : int = int(floor(stem.scale.y * 100 * health))
	ret += 10000 * max(0, 25 - abs(75 - health))
	return ret

func health_test() -> void:
	if health == 0:
		if not $Timer.is_stopped():
			pot_broken.play()
		$Timer.stop()
		emit_signal("cargo_down")

func plant_entered(area: Area) -> void:
	can_plant = true
	$Plant.visible = true

func plant_exited(area: Area) -> void:
	can_plant = false
	$Plant.visible = false
