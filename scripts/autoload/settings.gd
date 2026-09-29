extends Node

## Player-facing options: volumes and a reduced-motion switch that turns off
## camera shake and softens bright flashes. Saved to user://settings.cfg.
##
## Also owns the audio bus layout, so every channel exists before anything
## plays:
##   Master
##   ├─ Music    adaptive layers (AudioDirector); low-pass opens in combat
##   ├─ Ambient  cave ambience bed
##   └─ SFX      every sound effect
##       ├─ ReverbCorridor  short stone corridors
##       ├─ ReverbHall      larger rooms
##       ├─ ReverbCavern    tall chambers: long tail plus a distinct echo
##       └─ Foley           footsteps: dry, with only a faint short room tone
## Positional sounds reach a reverb bus through ReverbZone areas.

signal changed

const SETTINGS_PATH := "user://settings.cfg"
const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"
const AMBIENT_BUS := "Ambient"
const REVERB_BUSES := ["ReverbCorridor", "ReverbHall", "ReverbCavern"]
const FOLEY_BUS := "Foley"

var master_volume := 0.8
var music_volume := 0.7
var ambient_volume := 0.7
var sfx_volume := 0.8
var reduce_motion := false

## How much the game helps players find their way: the objective card and
## step pips (Light), plus links shown near switches, "you can use this"
## cues and hint stones that call out when you seem stuck (Full).
const GUIDANCE_OFF := 0
const GUIDANCE_LIGHT := 1
const GUIDANCE_FULL := 2
var guidance := GUIDANCE_FULL
var fullscreen := false
## Lighter effects for weaker graphics cards (no bloom, grain or shadows).
var effects_low := false

## Assist options, for anyone who wants the puzzles without the pressure:
## how much damage Echidna takes (1, 0.75, 0.5, 0.25; never less than 1 per
## hit), unlimited mana, sprinting by default (hold sprint to walk), and
## crouch as a toggle instead of a hold.
var assist_damage := 1.0
var assist_infinite_mana := false
var assist_auto_sprint := false
var assist_toggle_crouch := false
const ASSIST_KEYS := ["assist_damage", "assist_infinite_mana", "assist_auto_sprint", "assist_toggle_crouch"]
## Tests turn this off so they never overwrite a player's settings file.
var persist_to_disk := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_buses()
	_load()
	_apply()
	if fullscreen:
		_apply_window()


func _input(event: InputEvent) -> void:
	InputLabels.note_event(event)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		set_fullscreen(not fullscreen)
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ key bindings
# Each rebindable action's *primary* keyboard or mouse input can be changed
# (a second key such as an arrow, and every controller button, stay as they
# are). Saved as {action: {"key": physical keycode} or {"mouse": button}}.

var bindings := {}


func _primary_index(action: StringName) -> int:
	var events := InputMap.action_get_events(action)
	for i in events.size():
		if events[i] is InputEventKey or events[i] is InputEventMouseButton:
			return i
	return -1


func _event_from(spec: Dictionary) -> InputEvent:
	if spec.has("key"):
		var key := InputEventKey.new()
		key.physical_keycode = int(spec["key"])
		return key
	if spec.has("mouse"):
		var mouse := InputEventMouseButton.new()
		mouse.button_index = int(spec["mouse"])
		return mouse
	return null


func _spec_of(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"key": int(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode)}
	if event is InputEventMouseButton:
		return {"mouse": int(event.button_index)}
	return {}


func _set_primary(action: StringName, spec: Dictionary) -> void:
	var events := InputMap.action_get_events(action)
	var index := _primary_index(action)
	var replacement := _event_from(spec)
	if replacement == null:
		return
	InputMap.action_erase_events(action)
	for i in events.size():
		InputMap.action_add_event(action, replacement if i == index else events[i])
	if index == -1:
		InputMap.action_add_event(action, replacement)


func primary_spec(action: StringName) -> Dictionary:
	var index := _primary_index(action)
	return _spec_of(InputMap.action_get_events(action)[index]) if index != -1 else {}


## Binds `event` as the action's main key or mouse button. If another of
## `actions` already uses it, the two swap, so nothing is left unbound.
func rebind(action: StringName, event: InputEvent, actions: Array) -> void:
	var spec := _spec_of(event)
	if spec.is_empty():
		return
	var old := primary_spec(action)
	for other in actions:
		if other != action and primary_spec(other) == spec and not old.is_empty():
			_set_primary(other, old)
			bindings[String(other)] = old
	_set_primary(action, spec)
	bindings[String(action)] = spec
	changed.emit()
	_save()


func reset_bindings() -> void:
	InputMap.load_from_project_settings()
	bindings.clear()
	changed.emit()
	_save()


func _apply_bindings() -> void:
	for action in bindings:
		if InputMap.has_action(action) and bindings[action] is Dictionary:
			_set_primary(action, bindings[action])


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_window()
	changed.emit()
	_save()


func _apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


func _ensure_bus(bus_name: String, send_to: String) -> int:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, send_to)
	return index


func _build_buses() -> void:
	_ensure_bus(MUSIC_BUS, "Master")
	_ensure_bus(AMBIENT_BUS, "Master")
	_ensure_bus(SFX_BUS, "Master")
	var music := AudioServer.get_bus_index(MUSIC_BUS)
	if AudioServer.get_bus_effect_count(music) == 0:
		var lowpass := AudioEffectLowPassFilter.new()
		lowpass.cutoff_hz = 2400.0
		AudioServer.add_bus_effect(music, lowpass)
	# name: [room size, damping, wet, dry, predelay ms, echo delay ms or 0]
	var presets := {
		"ReverbCorridor": [0.5, 0.62, 0.26, 0.9, 28.0, 0.0],
		"ReverbHall": [0.78, 0.5, 0.34, 0.85, 55.0, 0.0],
		"ReverbCavern": [0.94, 0.38, 0.42, 0.8, 85.0, 260.0],
	}
	for bus_name in REVERB_BUSES:
		var index := _ensure_bus(bus_name, SFX_BUS)
		if AudioServer.get_bus_effect_count(index) > 0:
			continue
		var p: Array = presets[bus_name]
		var reverb := AudioEffectReverb.new()
		reverb.room_size = p[0]
		reverb.damping = p[1]
		reverb.wet = p[2]
		reverb.dry = p[3]
		reverb.predelay_msec = p[4]
		reverb.hipass = 0.15
		AudioServer.add_bus_effect(index, reverb)
		if p[5] > 0.0:
			# A distinct slap back off the far walls, for the cavernous rooms
			var echo := AudioEffectDelay.new()
			echo.dry = 1.0
			echo.tap1_active = true
			echo.tap1_delay_ms = p[5]
			echo.tap1_level_db = -11.0
			echo.tap2_active = true
			echo.tap2_delay_ms = p[5] * 1.9
			echo.tap2_level_db = -17.0
			echo.feedback_active = false
			AudioServer.add_bus_effect(index, echo)
	# Close, quiet body sounds (footsteps): a short, faint room tone instead of
	# the big room reverbs, so steps never trail an echo
	var foley := _ensure_bus(FOLEY_BUS, SFX_BUS)
	if AudioServer.get_bus_effect_count(foley) == 0:
		var room := AudioEffectReverb.new()
		room.room_size = 0.25
		room.damping = 0.8
		room.wet = 0.08
		room.dry = 1.0
		room.predelay_msec = 8.0
		room.hipass = 0.3
		AudioServer.add_bus_effect(foley, room)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply()
	_save()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply()
	_save()


func set_ambient_volume(value: float) -> void:
	ambient_volume = clampf(value, 0.0, 1.0)
	_apply()
	_save()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply()
	_save()


func set_reduce_motion(value: bool) -> void:
	reduce_motion = value
	_apply()
	_save()


## Scales a flash's strength when reduced motion is on.
func flash_strength(full: float) -> float:
	return full * (0.3 if reduce_motion else 1.0)


func _apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(AMBIENT_BUS), linear_to_db(maxf(ambient_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), linear_to_db(maxf(sfx_volume, 0.0001)))
	changed.emit()


func set_assist(key: String, value: Variant) -> void:
	if not ASSIST_KEYS.has(key):
		return
	set(key, clampf(float(value), 0.25, 1.0) if key == "assist_damage" else bool(value))
	changed.emit()
	_save()


func set_effects_low(value: bool) -> void:
	effects_low = value
	changed.emit()
	_save()


func set_guidance(value: int) -> void:
	guidance = clampi(value, GUIDANCE_OFF, GUIDANCE_FULL)
	_apply()
	_save()


func _save() -> void:
	if not persist_to_disk:
		return
	var file := ConfigFile.new()
	file.set_value("audio", "master", master_volume)
	file.set_value("audio", "music", music_volume)
	file.set_value("audio", "ambient", ambient_volume)
	file.set_value("audio", "sfx", sfx_volume)
	file.set_value("accessibility", "reduce_motion", reduce_motion)
	file.set_value("accessibility", "guidance", guidance)
	file.set_value("display", "fullscreen", fullscreen)
	file.set_value("display", "effects_low", effects_low)
	file.set_value("controls", "bindings", bindings)
	for key in ASSIST_KEYS:
		file.set_value("assist", key, get(key))
	file.save(SETTINGS_PATH)


func _load() -> void:
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		return
	# Anything of the wrong type (a damaged file) keeps its default
	master_volume = _number(file.get_value("audio", "master", master_volume), master_volume)
	music_volume = _number(file.get_value("audio", "music", music_volume), music_volume)
	ambient_volume = _number(file.get_value("audio", "ambient", ambient_volume), ambient_volume)
	sfx_volume = _number(file.get_value("audio", "sfx", sfx_volume), sfx_volume)
	var motion = file.get_value("accessibility", "reduce_motion", reduce_motion)
	reduce_motion = motion if motion is bool else reduce_motion
	guidance = clampi(int(_number(file.get_value("accessibility", "guidance", guidance), guidance)), GUIDANCE_OFF, GUIDANCE_FULL)
	var full = file.get_value("display", "fullscreen", fullscreen)
	fullscreen = full if full is bool else false
	var low = file.get_value("display", "effects_low", false)
	effects_low = low if low is bool else false
	var saved = file.get_value("controls", "bindings", {})
	bindings = saved if saved is Dictionary else {}
	_apply_bindings()
	assist_damage = clampf(_number(file.get_value("assist", "assist_damage", 1.0), 1.0), 0.25, 1.0)
	for key in ["assist_infinite_mana", "assist_auto_sprint", "assist_toggle_crouch"]:
		var v = file.get_value("assist", key, false)
		set(key, v if v is bool else false)


func _number(value: Variant, fallback: float) -> float:
	return clampf(float(value), 0.0, 2.0) if value is float or value is int else fallback
