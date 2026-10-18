extends Node

## Adaptive music and ambience (autoload "AudioDirector").
##
## Three looping music layers start together and stay in step:
##   drone  a low, echoing cave drone in A          (always present)
##   piano  a sparse, melancholic piano melody      (the main theme)
##   pulse  a slow heartbeat and trembling strings  (combat only)
## plus a cave-ambience bed (drips and wind) on its own channel, and under it
## each level's own bed (forge roar, water, lamp hum...: set_bed()).
##
## Combat intensity (0..1) eases toward 1 while any combat source is active
## (a combat room, a CombatZone) and back to 0 when none is. As it rises the
## drone swells, the Music bus low-pass opens, the pulse fades in and the
## piano steps back a little: slightly more tense, never a hard switch.
##
## The loops are synthesised by tools/audio/generate_music.gd (see its header for
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
## Extra music attenuation (see duck()).
var duck_db := 0.0
var _duck_tween: Tween
## The ambience level (see fade_ambience()).
var ambience_db := AMBIENCE_DB
var _ambience_tween: Tween
## Each level's own ambience bed (see set_bed()), under the cave ambience.
const BED_DIR := "res://assets/audio/sfx/"
const BED_DB := -9.0
## The bed playing now ("" for none): LevelTheme picks it per level.
var bed_name := ""
var _bed: AudioStreamPlayer
var _bed_level := 0.0
var _bed_tween: Tween
## The story cue playing now, if any (see play_cue()).
var cue: AudioStreamPlayer
var is_quitting := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	get_tree().scene_changed.connect(_on_scene_changed)
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


## Stop playback while the audio server can still retire its mixing voices.
## Releasing streams during _exit_tree is too late for that asynchronous work.
func quit_game(exit_code := 0) -> void:
	if is_quitting:
		return
	is_quitting = true
	_stop_audio(get_tree().root)
	# Use wall time: fixed-fps tests and paused menus must also allow the audio
	# thread to finish its fade-out and release the stopped playback streams.
	var deadline := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	get_tree().quit(exit_code)


func _stop_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		node.stop()
		node.stream = null
	for child in node.get_children():
		_stop_audio(child)


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


## Lowers the music by `db` (0 = normal) over `seconds`, e.g. so a great
## moment can ring out on its own.
func duck(db: float, seconds := 1.0) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(self, "duck_db", db, seconds)


## Fades the cave ambience to `db` (AMBIENCE_DB is normal), e.g. out under
## the open sky, where cave drips would sound wrong.
func fade_ambience(db: float, seconds := 1.5) -> void:
	if _ambience_tween:
		_ambience_tween.kill()
	_ambience_tween = create_tween()
	_ambience_tween.tween_property(self, "ambience_db", db, seconds)


## Clears every combat request (e.g. when a new level loads).
func reset_combat() -> void:
	_combat_sources.clear()


func _process(delta: float) -> void:
	if is_quitting:
		return
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
		players[layer].volume_db = maxf(db + start + duck_db, -80.0)
	if ambience:
		ambience.volume_db = maxf(ambience_db + start, -80.0)
	if _bed:
		_bed.volume_db = maxf(ambience_db - AMBIENCE_DB + BED_DB + start + linear_to_db(maxf(_bed_level, 0.0001)), -80.0)
	var music := AudioServer.get_bus_index(Settings.MUSIC_BUS)
	if music >= 0 and AudioServer.get_bus_effect_count(music) > 0:
		var lowpass := AudioServer.get_bus_effect(music, 0) as AudioEffectLowPassFilter
		if lowpass:
			lowpass.cutoff_hz = 16000.0 if is_instance_valid(cue) else lerpf(CUTOFF_EXPLORE, CUTOFF_COMBAT, k)


## Plays a story cue once (a file in MUSIC_DIR, e.g. the lullaby): the music
## steps back for it and the Music bus's low-pass opens so it rings clear,
## then the music comes back when it ends (or stop_cue() is called).
func play_cue(file: String, db := 0.0, duck_to := -26.0) -> AudioStreamPlayer:
	if is_quitting:
		return null
	stop_cue(0.6)
	var path := MUSIC_DIR + file
	if not ResourceLoader.exists(path):
		return null
	var player := AudioStreamPlayer.new()
	player.name = "Cue"
	player.stream = load(path)
	player.bus = Settings.MUSIC_BUS
	player.volume_db = db
	add_child(player)
	player.play()
	cue = player
	duck(duck_to, 1.5)
	player.finished.connect(func() -> void:
		if cue == player:
			cue = null
			duck(0.0, 3.0)
		player.queue_free())
	return player


## Fades out the story cue playing now, if any, and brings the music back.
func stop_cue(seconds := 1.5) -> void:
	if not is_instance_valid(cue):
		cue = null
		return
	var player := cue
	cue = null
	var t := create_tween()
	t.tween_property(player, "volume_db", -60.0, seconds)
	t.tween_callback(player.queue_free)
	duck(0.0, 3.0)


## Crossfades to a level's ambience bed (assets/audio/sfx/bed_<name>.wav),
## or out to none with "". Follows fade_ambience() like the cave ambience.
func set_bed(bed: String, seconds := 2.0) -> void:
	if is_quitting:
		return
	if bed == bed_name:
		return
	bed_name = bed
	if _bed:
		var old := _bed
		var t := create_tween()
		t.tween_property(old, "volume_db", -60.0, seconds)
		t.tween_callback(old.queue_free)
	_bed = null
	if _bed_tween:
		_bed_tween.kill()
	_bed_level = 0.0
	if bed == "":
		return
	_bed = _looping_player(BED_DIR + "bed_%s.wav" % bed, Settings.AMBIENT_BUS)
	if _bed:
		_bed.name = "Bed"
		_bed.play()
		_bed_tween = create_tween()
		_bed_tween.tween_property(self, "_bed_level", 1.0, seconds)


## A scene that isn't a themed level (the title, a story scene) has no bed.
func _on_scene_changed() -> void:
	await get_tree().create_timer(0.3).timeout
	var scene := get_tree().current_scene
	if scene == null or not scene.has_meta("level_theme"):
		set_bed("")
