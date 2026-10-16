extends CanvasLayer

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
