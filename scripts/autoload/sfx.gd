extends Node

## Plays short sound effects by name from res://assets/audio/sfx/<name>.wav.
## Rapid repeats of the same sound are throttled and capped so overlapping
## events can never stack into a loud burst.

const SOUND_DIR := "res://assets/audio/sfx/"
const MIN_INTERVAL_MS := 70
const MAX_VOICES_PER_SOUND := 3

var _streams := {}
var _last_played := {}
var _voices := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## at: a world position for positional sound, or null for UI/global sound.
func play(sound: String, at: Variant = null, volume_db := 0.0, pitch_variation := 0.05) -> void:
	var stream := _stream(sound)
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sound, -100000)) < MIN_INTERVAL_MS:
		return
	if int(_voices.get(sound, 0)) >= MAX_VOICES_PER_SOUND:
		return
	_last_played[sound] = now
	_voices[sound] = int(_voices.get(sound, 0)) + 1

	var player: Node
	if at is Vector2:
		var positional := AudioStreamPlayer2D.new()
		positional.global_position = at
		positional.max_distance = 1100.0
		positional.attenuation = 1.4
		positional.stream = stream
		positional.bus = Settings.SFX_BUS
		# A ReverbZone around the sound's origin reroutes it through that
		# space's reverb bus (Area2D audio bus override)
		positional.area_mask = ReverbZone.AUDIO_LAYER
		positional.volume_db = volume_db
		positional.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
		player = positional
	else:
		var flat := AudioStreamPlayer.new()
		flat.stream = stream
		flat.bus = Settings.SFX_BUS
		flat.volume_db = volume_db
		flat.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
		player = flat
	add_child(player)
	player.finished.connect(_on_finished.bind(player, sound))
	player.play()


func _on_finished(player: Node, sound: String) -> void:
	_voices[sound] = maxi(int(_voices.get(sound, 1)) - 1, 0)
	player.queue_free()


func _stream(sound: String) -> AudioStream:
	if not _streams.has(sound):
		var path := SOUND_DIR + sound + ".wav"
		_streams[sound] = load(path) if ResourceLoader.exists(path) else null
	return _streams[sound]
