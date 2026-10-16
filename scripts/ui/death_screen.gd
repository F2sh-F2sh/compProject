extends Control

## Full death sequence: the frozen game is dimmed and desaturated, a soft black
## band fades in with "You Died" (in the blackletter title face), then a fresh press of the restart key reloads
## the level from its normal start.

@export var restart_action := "jump"
@export var dim_time := 0.9
@export var band_delay := 0.3
@export var band_fade_time := 1.0
@export var title_delay := 0.5
@export var title_fade_time := 1.0
## The title creeps toward this scale while it is on screen.
@export var title_zoom := 1.06
@export var prompt_delay := 1.1
@export var prompt_fade_time := 0.4

var can_restart := false
var _pulse: Tween

@onready var dim: ColorRect = $Dim
@onready var band: ColorRect = $Band
@onready var title: Label = $Title
@onready var prompt: Label = $Prompt


func _ready() -> void:
	# Keeps running while the game is paused so it can take the restart input
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputLabels.watch(prompt, func(): prompt.text = "Press %s to Continue" % InputLabels.primary(restart_action))
	title.text = "You Died"
	title.add_theme_font_override("font", Fonts.TITLE)
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color(0.72, 0.1, 0.14))
	prompt.add_theme_font_override("font", Fonts.UI)
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.add_theme_color_override("font_color", DungeonUI.INK)


func show_death_screen() -> void:
	can_restart = false
	show()
	Crosshair.arrow()

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
	tween.tween_callback(Sfx.play.bind("death_sting", null, -3.0, 0.0)).set_delay(title_delay)
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
	Sfx.play("respawn", null, -4.0, 0.0)
	SceneFade.restart(get_tree())


func _set_dim(amount: float) -> void:
	(dim.material as ShaderMaterial).set_shader_parameter("amount", amount)
