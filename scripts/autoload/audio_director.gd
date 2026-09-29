extends Node

## Adaptive music and ambience (autoload "AudioDirector").
##
## Three looping music layers start together and stay in step:
##   drone  a low, echoing cave drone in A          (always present)
##   piano  a sparse, melancholic piano melody      (the main theme)
##   pulse  a slow heartbeat and trembling strings  (combat only)
## plus a cave-ambience bed (drips and wind) on its own channel.
##
## Combat intensity (0..1) eases toward 1 while any combat source is active
## (a combat room, a CombatZone) and back to 0 when none is. As it rises the
## drone swells, the Music bus low-pass opens, the pulse fades in and the
## piano steps back a little: slightly more tense, never a hard switch.
##
## The loops are synthesised by tools/generate_music.gd (see its header for
## a prompt to generate a richer replacement with a music tool). Any
## replacement just needs the same file names and matching loop lengths.

const MUSIC_DIR := "res://assets/audio/music/"
const LAYERS := {
	# name: [file, explore dB, combat dB]
	&"drone": ["cave_drone.wav", -9.0, -3.5],
	&"piano": ["piano_lament.wav", -7.0, -12.0],
	&"pulse": ["combat_pulse.wav", -60.0, -8.0],
}
const AMBIENCE := "cave_ambience.wav"
const AMBIENCE_DB := -10.0
## Seconds for a full change of intensity.
const CROSSFADE := 2.5
const CUTOFF_EXPLORE := 2400.0
const CUTOFF_COMBAT := 9000.0

var intensity := 0.0
var players := {}
var ambience: AudioStreamPlayer
var _combat_sources := {}
var _fade_in := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for layer in LAYERS:
		var player := _looping_player(MUSIC_DIR + LAYERS[layer][0], Settings.MUSIC_BUS)
		if player:
			player.name = String(layer).capitalize()
			players[layer] = player
	ambience = _looping_player(MUSIC_DIR + AMBIENCE, Settings.AMBIENT_BUS)
	# Start every layer on the same sample so they stay in step
	for player in players.values():
		player.play()
	if ambience:
		ambience.play()
	_apply_mix()


func _looping_player(path: String, bus: String) -> AudioStreamPlayer:
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStreamWAV
	if stream == null:
		return null
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	player.volume_db = -80.0
	add_child(player)
	return player


## Marks a source (a room, a zone) as wanting combat music or not.
func set_combat(source: Object, active: bool) -> void:
	var key := source.get_instance_id()
	if active:
		_combat_sources[key] = true
	else:
		_combat_sources.erase(key)


func is_combat() -> bool:
	return not _combat_sources.is_empty()


## Clears every combat request (e.g. when a new level loads).
func reset_combat() -> void:
	_combat_sources.clear()


func _process(delta: float) -> void:
	# Drop requests from sources that no longer exist (a level was unloaded)
	for key in _combat_sources.keys():
		if not is_instance_id_valid(key):
			_combat_sources.erase(key)
	var target := 1.0 if is_combat() else 0.0
	intensity = move_toward(intensity, target, delta / CROSSFADE)
	_fade_in = minf(_fade_in + delta / 3.0, 1.0)
	_apply_mix()


func _apply_mix() -> void:
	# Ease the intensity so the swell starts and ends gently
	var k := intensity * intensity * (3.0 - 2.0 * intensity)
	var start := linear_to_db(maxf(_fade_in, 0.0001))
	for layer in players:
		var spec: Array = LAYERS[layer]
		var db: float = lerpf(spec[1], spec[2], k)
		players[layer].volume_db = maxf(db + start, -80.0)
	if ambience:
		ambience.volume_db = maxf(AMBIENCE_DB + start, -80.0)
	var music := AudioServer.get_bus_index(Settings.MUSIC_BUS)
	if music >= 0 and AudioServer.get_bus_effect_count(music) > 0:
		var lowpass := AudioServer.get_bus_effect(music, 0) as AudioEffectLowPassFilter
		if lowpass:
			lowpass.cutoff_hz = lerpf(CUTOFF_EXPLORE, CUTOFF_COMBAT, k)
