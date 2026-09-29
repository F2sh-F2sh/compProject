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
##       └─ ReverbCavern    tall chambers: long tail plus a distinct echo
## Positional sounds reach a reverb bus through ReverbZone areas.

signal changed

const SETTINGS_PATH := "user://settings.cfg"
const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"
const AMBIENT_BUS := "Ambient"
const REVERB_BUSES := ["ReverbCorridor", "ReverbHall", "ReverbCavern"]

var master_volume := 0.8
var music_volume := 0.7
var ambient_volume := 0.7
var sfx_volume := 0.8
var reduce_motion := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_buses()
	_load()
	_apply()


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


func _save() -> void:
	var file := ConfigFile.new()
	file.set_value("audio", "master", master_volume)
	file.set_value("audio", "music", music_volume)
	file.set_value("audio", "ambient", ambient_volume)
	file.set_value("audio", "sfx", sfx_volume)
	file.set_value("accessibility", "reduce_motion", reduce_motion)
	file.save(SETTINGS_PATH)


func _load() -> void:
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		return
	master_volume = file.get_value("audio", "master", master_volume)
	music_volume = file.get_value("audio", "music", music_volume)
	ambient_volume = file.get_value("audio", "ambient", ambient_volume)
	sfx_volume = file.get_value("audio", "sfx", sfx_volume)
	reduce_motion = file.get_value("accessibility", "reduce_motion", reduce_motion)
