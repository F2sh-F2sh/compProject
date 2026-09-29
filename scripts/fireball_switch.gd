@tool
class_name FireballSwitch
extends Area2D

## A rune target triggered by a fireball. On activation it calls target_method
## on every target (e.g. "stop" on pistons) and becomes a powered source
## (`power_changed`, `is_powered`) for circuits. Three readable states:
## idle (pulsing red, waiting to be hit), active (steady blue) and disabled
## (dark, chained) when `disabled` is set or a circuit powers it off.

signal activated
signal power_changed(powered: bool)

@export var targets: Array[Node] = []
@export var target_method := "stop"
@export var radius := 12.0:
	set(value):
		radius = value
		queue_redraw()
@export var idle_color := Color(0.95, 0.35, 0.3)
@export var active_color := Color(0.45, 0.75, 1.0)
@export var disabled := false:
	set(value):
		disabled = value
		queue_redraw()
## If set, stays activated across deaths and reloads.
@export var persist_id := ""

var is_active := false
var _light: PointLight2D
var _sparks: CPUParticles2D
var _time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # fireballs live on layer 1
	monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = radius + 2.0
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)

	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(160)
	_light.color = idle_color
	_light.energy = 0.6
	add_child(_light)

	_sparks = CPUParticles2D.new()
	_sparks.emitting = false
	_sparks.one_shot = true
	_sparks.explosiveness = 1.0
	_sparks.amount = 24
	_sparks.lifetime = 0.6
	_sparks.spread = 180.0
	_sparks.gravity = Vector2(0, 40)
	_sparks.initial_velocity_min = 40.0
	_sparks.initial_velocity_max = 90.0
	_sparks.scale_amount_min = 1.5
	_sparks.scale_amount_max = 2.5
	_sparks.color = active_color
	add_child(_sparks)

	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	area_entered.connect(_on_area_entered)
	if persist_id != "" and GameState.has_flag(persist_id):
		_set_active(true, true)


func is_powered() -> bool:
	return is_active


## A circuit can enable or disable the switch.
func set_powered(powered: bool) -> void:
	disabled = not powered


func activate() -> void:
	if is_active or disabled:
		return
	_set_active(true)


func reset_state() -> void:
	if persist_id != "" and GameState.has_flag(persist_id):
		return
	is_active = false
	_light.color = idle_color
	power_changed.emit(false)
	queue_redraw()


func _set_active(on: bool, silent := false) -> void:
	is_active = on
	_light.color = active_color
	if not silent:
		_sparks.restart()
		Sfx.play("switch_on", global_position)
		if persist_id != "":
			GameState.set_flag(persist_id)
	for target in targets:
		if is_instance_valid(target) and target.has_method(target_method):
			target.call(target_method)
	activated.emit()
	power_changed.emit(true)
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("fireball") and not is_active and not disabled:
		area.queue_free()
		activate()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	# Pulses while waiting to be hit so it reads as something to shoot
	if disabled:
		_light.energy = 0.15
	else:
		_light.energy = 1.3 if is_active else 0.55 + 0.35 * (0.5 + 0.5 * sin(_time * 4.0))
	queue_redraw()


func _draw() -> void:
	var r := radius
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	var rune := active_color if is_active else idle_color.lerp(Color.WHITE, 0.25 * pulse)
	if disabled and not is_active:
		rune = Color(0.3, 0.26, 0.4)
	# Iron bracket and stone disc
	draw_rect(Rect2(-3, -r - 8.0, 6, 8), Color("2b2838"))
	draw_circle(Vector2.ZERO, r + 2.0, Color("231d38"))
	draw_circle(Vector2.ZERO, r, Color("3b3358"))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color("6a5f92"), 1.0)
	# Rune: an eye-like sigil
	draw_arc(Vector2.ZERO, r * 0.55, 0.0, TAU, 16, rune, 2.0)
	draw_circle(Vector2.ZERO, 2.5, rune)
	for a in [0.0, PI / 2.0, PI, PI * 1.5]:
		var d := Vector2.from_angle(a)
		draw_line(d * (r * 0.7), d * (r - 1.0), rune, 2.0)
	if disabled and not is_active:
		# Chains across the disc mark it as unusable
		draw_line(Vector2(-r, -r * 0.4), Vector2(r, r * 0.4), Color("5b5773"), 2.0)
		draw_line(Vector2(-r, r * 0.4), Vector2(r, -r * 0.4), Color("5b5773"), 2.0)
