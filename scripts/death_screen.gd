extends Control

## Full death sequence: the frozen game is dimmed and desaturated, a soft black
## band fades in with "YOU DIED", then a fresh press of the restart key reloads
## the level from its normal start.

@export var restart_action := "jump"
@export var dim_time := 1.2
@export var band_delay := 0.3
@export var band_fade_time := 1.0
@export var title_delay := 0.5
@export var title_fade_time := 1.4
## The title creeps toward this scale while it is on screen.
@export var title_zoom := 1.06
@export var prompt_delay := 2.6
@export var prompt_fade_time := 0.6

var can_restart := false
var _pulse: Tween

@onready var dim: ColorRect = $Dim
@onready var band: ColorRect = $Band
@onready var title: Label = $Title
@onready var prompt: Label = $Prompt


func _ready() -> void:
	# Keeps running while the game is paused so it can take the restart input
	process_mode = Node.PROCESS_MODE_ALWAYS
	prompt.text = "Press %s to Continue" % InputLabels.primary(restart_action)


func show_death_screen() -> void:
	can_restart = false
	show()

	for node in get_tree().get_nodes_in_group("gameplay_ui"):
		node.visible = false
	get_tree().paused = true

	_set_dim(0.0)
	band.modulate.a = 0.0
	title.modulate.a = 0.0
	prompt.modulate.a = 0.0
	title.pivot_offset = title.size / 2.0
	title.scale = Vector2.ONE

	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	tween.tween_method(_set_dim, 0.0, 1.0, dim_time)
	tween.tween_property(band, "modulate:a", 1.0, band_fade_time).set_delay(band_delay)
	tween.tween_property(title, "modulate:a", 1.0, title_fade_time).set_delay(title_delay)
	tween.tween_property(title, "scale", Vector2.ONE * title_zoom, 6.0).set_delay(title_delay)
	tween.tween_property(prompt, "modulate:a", 1.0, prompt_fade_time).set_delay(prompt_delay)
	tween.tween_callback(_arm_restart).set_delay(prompt_delay + prompt_fade_time)


func _arm_restart() -> void:
	can_restart = true
	_pulse = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_loops()
	_pulse.tween_property(prompt, "modulate:a", 0.55, 1.1).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(prompt, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)


func _input(event: InputEvent) -> void:
	if not can_restart:
		return
	# Only a new press counts; holding the key from before the prompt does nothing
	if event.is_action_pressed(restart_action, false):
		get_viewport().set_input_as_handled()
		restart_level()


func restart_level() -> void:
	can_restart = false
	if _pulse:
		_pulse.kill()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _set_dim(amount: float) -> void:
	(dim.material as ShaderMaterial).set_shader_parameter("amount", amount)
