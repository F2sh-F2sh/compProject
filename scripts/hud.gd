extends CanvasLayer

<<<<<<< HEAD
@onready var status_bar: Control = $HUDRoot/StatusBar

## At or below this much health the screen's edges pulse red and a quiet
## heartbeat plays (a steady tint with reduced motion).
const LOW_HEALTH := 3

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float strength = 0.0;
void fragment() {
	vec2 d = (UV - 0.5) * vec2(1.0, 0.75);
	float edge = smoothstep(0.28, 0.62, length(d));
	COLOR = vec4(0.6, 0.02, 0.06, edge * strength);
}
"""

var _vignette: ColorRect
var _low := false
var _time := 0.0
var _beat := 0.0


func _ready() -> void:
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = VIGNETTE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_vignette.material = mat
	_vignette.visible = false
	add_child(_vignette)
	move_child(_vignette, 0)


func set_health(current: int, maximum: int) -> void:
	status_bar.set_health(current, maximum)
	_low = current > 0 and current <= LOW_HEALTH
	if not _low:
		_vignette.visible = false


func _process(delta: float) -> void:
	if not _low:
		return
	_time += delta
	_vignette.visible = true
	var strength := 0.4 if Settings.reduce_motion else 0.32 + 0.22 * (0.5 + 0.5 * sin(_time * 5.5))
	(_vignette.material as ShaderMaterial).set_shader_parameter("strength", strength)
	_beat -= delta
	if _beat <= 0.0:
		_beat = 1.0
		Sfx.play("heartbeat", null, -8.0, 0.0)


func set_mana(current: int, maximum: int, restoring: bool, progress: float) -> void:
	status_bar.set_mana(current, maximum, restoring, progress)


func set_mana_debt(debt: int) -> void:
	status_bar.set_mana_debt(debt)


func set_echo_state(recording: bool, remaining: float, count: int, max_count: int, seconds_left := -1.0) -> void:
	status_bar.set_echo_state(recording, remaining, count, max_count, seconds_left)
=======
@export var heart_scene: PackedScene
@export var health_per_heart: int = 2

@onready var hearts_container: HBoxContainer = $HUDRoot/Hearts

var hearts: Array[Node] = []


func set_hearts(current_health: int, max_health: int) -> void:
	current_health = clampi(current_health, 0, max_health)

	var heart_count := ceili(float(max_health) / health_per_heart)

	if hearts.size() != heart_count:
		create_hearts(heart_count)

	for i in range(heart_count):
		var health_in_this_heart := clampi(
			current_health - (i * health_per_heart),
			0,
			health_per_heart
		)

		hearts[i].set_health_amount(
			health_in_this_heart,
			health_per_heart
		)


func create_hearts(count: int) -> void:
	for heart in hearts:
		heart.queue_free()

	hearts.clear()

	for i in range(count):
		var heart = heart_scene.instantiate()
		hearts_container.add_child(heart)
		hearts.append(heart)
>>>>>>> ca7ff5e18fa8e215148f3f169007eba690423f12
