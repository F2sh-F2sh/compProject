extends SceneTree

## Synthesises the adaptive music loops into res://assets/audio/music/:
##   cave_drone.wav     32 s  low A drone: detuned partials that beat slowly,
##                            a breathing swell, wind, a long cave echo
##   piano_lament.wav   32 s  8 bars at 60 bpm in A minor
##                            (Am | F | Dm | E | Am | F | Dm E | Am): broken
##                            left-hand chords, a sparse falling melody
##   combat_pulse.wav   16 s  a slow heartbeat (75 bpm) and trembling low
##                            strings with a faint dissonant shimmer
##   cave_ambience.wav  24 s  water drips with echoes over a low wind
## Every loop is seamless: tones complete whole cycles in the loop, note
## tails and reverb wrap around to the start, and noise is crossfaded.
## The layers are designed to play together (AudioDirector).
##   godot --headless --path . --script res://tools/generate_music.gd
##
## To replace them with richer recordings, keep the file names and lengths.
## A prompt for a music generation tool that matches this brief:
##   "Dark fantasy dungeon ambience, 60 bpm, A minor. A lonely, melancholic
##    solo piano melody, sparse and slow with long sustain, played over a low
##    echoing cave drone on A with a huge stone reverb. Quiet, cold,
##    hand-drawn gothic ruins mood. Seamless 32-second loop, no percussion."
##   Combat layer: "Same key and tempo feel: slow heartbeat drum at 75 bpm,
##    tremolo low strings on A, faint dissonant high shimmer, tense but
##    restrained. Seamless 16-second loop that layers under the piano."

const RATE := 22050
const OUT := "res://assets/audio/music/"

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 2601
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	write("cave_drone", drone(32.0), 0.8)
	write("piano_lament", piano(32.0), 0.85)
	write("combat_pulse", pulse(16.0), 0.8)
	write("cave_ambience", ambience(24.0), 0.7)
	print("MUSIC DONE")
	quit()


# ================================================================ layers

func drone(seconds: float) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var fade := int(3.0 * RATE)
	var b := buffer(seconds + 3.0)
	# Frequencies are k / seconds so every partial completes whole cycles
	var partials := [[55.0, 0.5], [55.25, 0.34], [82.40625, 0.26], [82.5, 0.18], [110.03125, 0.17],
		[164.8125, 0.05], [220.0625, 0.03]]
	var lp := 0.0
	for i in b.size():
		var t := i / float(RATE)
		var v := 0.0
		for p in partials:
			v += p[1] * sin(TAU * p[0] * t)
		v *= 0.72 + 0.28 * sin(TAU * t / 16.0)
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.02
		v += lp * (0.9 + 0.5 * sin(TAU * t / 8.0 + 1.0))
		b[i] = v
	var looped := crossfade_loop(b, n, fade)
	return reverb(looped, 0.45, 1.7, 0.86)


func piano(seconds: float) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var b := buffer(seconds + 7.0)
	# [start beat, midi note, beats held, velocity]; one beat = 1 s
	var left := []
	var chords := [[45, 52, 57, 60], [41, 48, 53, 57], [38, 45, 50, 53], [40, 47, 52, 56],
		[45, 52, 57, 60], [41, 48, 53, 57], [], [45, 52, 57, 64]]
	for bar in chords.size():
		var chord: Array = chords[bar]
		for k in chord.size():
			left.append([bar * 4 + k, chord[k], 3.5, 0.34 - k * 0.02])
	# Bar 7 splits Dm and E
	left.append_array([[24, 38, 1.8, 0.34], [25, 45, 1.8, 0.3], [26, 40, 1.8, 0.34], [27, 56, 1.8, 0.3]])
	var melody := [
		[0, 76, 2, 0.62], [2, 72, 1, 0.52], [3, 71, 1, 0.5],
		[4, 69, 3, 0.58], [7, 72, 1, 0.48],
		[8, 74, 2, 0.6], [10, 77, 1, 0.55], [11, 76, 1, 0.5],
		[12, 74, 2, 0.56], [14, 71, 1, 0.5], [15, 68, 1, 0.52],
		[16, 76, 1.5, 0.6], [17.5, 74, 0.5, 0.45], [18, 72, 1, 0.5], [19, 71, 1, 0.48],
		[20, 69, 2, 0.56], [22, 72, 1, 0.5], [23, 69, 1, 0.46],
		[24, 65, 1, 0.5], [25, 69, 1, 0.52], [26, 68, 1, 0.52], [27, 71, 1, 0.55],
		[28, 69, 4, 0.58],
	]
	for note in left + melody:
		# A touch of human timing and touch
		var start: float = note[0] + rng.randf_range(-0.012, 0.012)
		var vel: float = note[3] * rng.randf_range(0.92, 1.08)
		piano_note(b, maxf(start, 0.0), note[1], note[2], vel)
	var looped := fold(b, n)
	return reverb(looped, 0.38, 1.35, 0.8)


func pulse(seconds: float) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var b := buffer(seconds + 1.0)
	var beat := 0.8  # 75 bpm: 20 beats in 16 s
	var beats := int(seconds / beat)
	for k in beats:
		thump(b, k * beat, 1.0)
		thump(b, k * beat + 0.19, 0.55)
	for i in n:
		var t := i / float(RATE)
		# Low strings on A with tremolo (6.25 Hz: whole cycles in 16 s)
		var saw := 0.0
		for h in range(1, 7):
			saw += sin(TAU * 110.0 * h * t) / h
		var tremolo := 0.55 + 0.45 * sin(TAU * 6.25 * t)
		var swell := 0.6 + 0.4 * sin(TAU * t / 16.0 - PI / 2.0)
		var shimmer := (sin(TAU * 880.0 * t) + sin(TAU * 932.3125 * t)) * 0.035 * (0.5 + 0.5 * sin(TAU * t / 8.0))
		b[i] += saw * 0.13 * tremolo * swell + shimmer
	var looped := fold(b, n)
	return reverb(looped, 0.3, 1.2, 0.78)


func ambience(seconds: float) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var fade := int(2.0 * RATE)
	var b := buffer(seconds + 2.0)
	var lp := 0.0
	var lp2 := 0.0
	for i in b.size():
		var t := i / float(RATE)
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.012
		lp2 += (lp - lp2) * 0.3
		b[i] = lp2 * (1.4 + 0.8 * sin(TAU * t / 12.0))
	var looped := crossfade_loop(b, n, fade)
	var drips := buffer(seconds + 1.0)
	for d in 16:
		drip(drips, rng.randf_range(0.0, seconds), rng.randf_range(1300.0, 2600.0), rng.randf_range(0.15, 0.5))
	var drip_loop := fold(drips, n)
	drip_loop = echo(drip_loop, 0.31, 0.42, 0.5)
	for i in n:
		looped[i] += drip_loop[i]
	return reverb(looped, 0.4, 1.6, 0.85)


# ================================================================ instruments

func piano_note(b: PackedFloat32Array, start: float, midi: int, beats: float, vel: float) -> void:
	var f := 440.0 * pow(2.0, (midi - 69) / 12.0)
	# Low strings ring longer; everything rings on a little (sustain pedal)
	var ring := clampf(5.0 - (midi - 40) * 0.07, 1.4, 5.0)
	var held := beats
	var length := held + ring
	var first := int(start * RATE)
	var count := mini(int(length * RATE), b.size() - first)
	var inharmonic := 0.00035
	for h in range(1, 7):
		var fh := h * f * sqrt(1.0 + inharmonic * h * h)
		if fh > RATE * 0.45:
			break
		var amp := vel / pow(h, 1.15) * (1.0 if h == 1 else 0.8)
		var decay := ring / (1.0 + 0.55 * (h - 1))
		var phase := rng.randf() * TAU
		var step := TAU * fh / RATE
		# Stop once this partial has died away (about -80 dB)
		var audible := mini(count, int(decay * 9.2 * RATE))
		for i in audible:
			var t := i / float(RATE)
			var env := minf(t / 0.003, 1.0) * exp(-t / decay)
			if t > held:
				# Key released: the damper settles the string
				env *= exp(-(t - held) / 0.9)
			b[first + i] += amp * sin(phase + step * i) * env
	# Hammer: a tiny muffled knock at the start
	var knock_lp := 0.0
	for i in mini(int(0.012 * RATE), b.size() - first):
		knock_lp += (rng.randf_range(-1.0, 1.0) - knock_lp) * 0.25
		b[first + i] += knock_lp * vel * 0.05 * (1.0 - i / (0.012 * RATE))


func thump(b: PackedFloat32Array, start: float, strength: float) -> void:
	var first := int(start * RATE)
	var phase := 0.0
	for i in mini(int(0.35 * RATE), b.size() - first):
		var t := i / float(RATE)
		phase += TAU * (44.0 + 30.0 * exp(-t / 0.03)) / RATE
		b[first + i] += sin(phase) * exp(-t / 0.13) * strength * 0.9


func drip(b: PackedFloat32Array, start: float, f: float, amp: float) -> void:
	var first := int(start * RATE)
	var phase := 0.0
	for i in mini(int(0.2 * RATE), b.size() - first):
		var t := i / float(RATE)
		phase += TAU * f * (1.0 + 0.7 * exp(-t / 0.012)) / RATE
		b[first + i] += sin(phase) * exp(-t / 0.05) * amp


# ================================================================ processing

func buffer(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## Adds everything past the loop length back onto the start (ringing tails).
func fold(b: PackedFloat32Array, n: int) -> PackedFloat32Array:
	var out := b.slice(0, n)
	for i in range(n, b.size()):
		out[(i - n) % n] += b[i]
	return out


## Blends the overshoot into the start, for material that isn't periodic.
func crossfade_loop(b: PackedFloat32Array, n: int, fade: int) -> PackedFloat32Array:
	var out := b.slice(0, n)
	for i in fade:
		var k := float(i) / fade
		out[i] = b[i] * k + b[n + i] * (1.0 - k)
	return out


func _delay_line(ms: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(maxi(int(ms * RATE / 1000.0), 1))
	return buf


## Schroeder reverb (four damped combs, two allpasses) run over the loop
## twice, so its tail wraps seamlessly into the start. Delay lines are plain
## locals: packed arrays copy on write, so they are never passed around.
func reverb(b: PackedFloat32Array, wet: float, size: float, feedback: float) -> PackedFloat32Array:
	var n := b.size()
	var c0 := _delay_line(37.1 * size)
	var c1 := _delay_line(40.3 * size)
	var c2 := _delay_line(43.7 * size)
	var c3 := _delay_line(47.9 * size)
	var a0 := _delay_line(5.0)
	var a1 := _delay_line(1.7)
	var i0 := 0
	var i1 := 0
	var i2 := 0
	var i3 := 0
	var j0 := 0
	var j1 := 0
	var l0 := 0.0
	var l1 := 0.0
	var l2 := 0.0
	var l3 := 0.0
	var out := PackedFloat32Array()
	out.resize(n)
	for pass_i in 2:
		for s in n:
			var x := b[s]
			var y0 := c0[i0]
			l0 = y0 * 0.7 + l0 * 0.3
			c0[i0] = x + l0 * feedback
			i0 = (i0 + 1) % c0.size()
			var y1 := c1[i1]
			l1 = y1 * 0.7 + l1 * 0.3
			c1[i1] = x + l1 * feedback
			i1 = (i1 + 1) % c1.size()
			var y2 := c2[i2]
			l2 = y2 * 0.7 + l2 * 0.3
			c2[i2] = x + l2 * feedback
			i2 = (i2 + 1) % c2.size()
			var y3 := c3[i3]
			l3 = y3 * 0.7 + l3 * 0.3
			c3[i3] = x + l3 * feedback
			i3 = (i3 + 1) % c3.size()
			var acc := (y0 + y1 + y2 + y3) * 0.25
			var d0 := a0[j0]
			a0[j0] = acc + d0 * 0.5
			acc = -acc * 0.5 + d0
			j0 = (j0 + 1) % a0.size()
			var d1 := a1[j1]
			a1[j1] = acc + d1 * 0.5
			acc = -acc * 0.5 + d1
			j1 = (j1 + 1) % a1.size()
			if pass_i == 1:
				out[s] = x * (1.0 - wet * 0.5) + acc * wet
	return out


## A circular feedback echo.
func echo(b: PackedFloat32Array, delay: float, feedback: float, wet: float) -> PackedFloat32Array:
	var n := b.size()
	var d := int(delay * RATE)
	var out := b.duplicate()
	for pass_i in 3:
		for i in n:
			out[i] = b[i] + out[posmod(i - d, n)] * feedback
	for i in n:
		out[i] = b[i] * (1.0 - wet) + out[i] * wet
	return out


func write(sound_name: String, samples: PackedFloat32Array, gain: float) -> void:
	var peak := 0.0001
	for s in samples:
		peak = maxf(peak, absf(s))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] / peak * gain, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.save_to_wav(ProjectSettings.globalize_path(OUT + sound_name + ".wav"))
	print("  ", sound_name, ": ", samples.size() / float(RATE), " s")
