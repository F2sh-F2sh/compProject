extends SceneTree

## Synthesises the story's music cues into res://assets/audio/music/ (they are
## played once, by the story reels and the Eye, not looped):
##   lullaby.wav       ~19 s  the four notes (E C D A), Ilse's lullaby for Wren,
##                            on a music box over soft piano chords
##   bell_peal.wav     ~12 s  the same four notes as the great bell rings them
##                            (Lowbell grew up with this peal)
##   ending_swell.wav  ~46 s  the four notes slowly on piano, a pad rising under
##                            them, and at the end the tune turning to A major
## The motif is the story's leitmotif: Nan hums it, the bell rings it, Ilse
## sang it, and it plays when the held moment lets go.
##   godot --headless --path . --script res://tools/audio/generate_story_music.gd

const RATE := 22050
const OUT := "res://assets/audio/music/"
## The four notes (MIDI): E5, C5, D5, A4.
const MOTIF := [76, 72, 74, 69]

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 1960
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	write("lullaby", lullaby(), 0.8)
	write("bell_peal", peal(), 0.8)
	write("ending_swell", ending(), 0.85)
	print("STORY MUSIC DONE")
	quit()


# ================================================================ cues

func lullaby() -> PackedFloat32Array:
	var b := buffer(19.0)
	var beat := 0.9
	var t := 0.6
	for phrase in 2:
		for k in 4:
			music_box(b, t + k * beat, MOTIF[k], 1.6 if k == 3 else 0.9, 0.5)
		t += 4 * beat + 0.9
	# The answer: E D C A, slower, ending on the tonic
	var answer := [76, 74, 72, 69]
	for k in 4:
		music_box(b, t + k * beat * 1.2, answer[k], 2.5 if k == 3 else 1.0, 0.46)
	# Soft piano chords under it: Am, F, Am, E, Am
	var chords := [[0.6, [45, 52, 57]], [2.4, [41, 48, 53]], [5.1, [45, 52, 57]], [6.9, [40, 47, 52]], [9.6, [45, 52, 57]], [12.0, [41, 48, 57]], [14.0, [45, 52, 57]]]
	for c in chords:
		for k in c[1].size():
			piano_note(b, c[0] + k * 0.08, c[1][k], 2.4, 0.18)
	return reverb(b, 0.45, 1.4, 0.82)


func peal() -> PackedFloat32Array:
	var b := buffer(12.0)
	for k in 4:
		bell(b, 0.3 + k * 1.6, MOTIF[k] - 12, 0.6)
	bell(b, 7.2, 57 - 12, 0.5)
	return reverb(b, 0.5, 1.6, 0.84)


func ending() -> PackedFloat32Array:
	var b := buffer(46.0)
	# 1. The motif on piano, slow and alone (Am)
	for k in 4:
		piano_note(b, 1.0 + k * 1.5, MOTIF[k], 1.4, 0.5)
	piano_note(b, 1.0, 45, 6.0, 0.22)
	piano_note(b, 1.0, 52, 6.0, 0.18)
	# 2. A pad rises; the motif again, an octave up on the music box
	pad(b, 8.0, 10.0, [45, 52, 57], 0.12)
	pad(b, 18.0, 6.0, [41, 48, 53], 0.13)
	for k in 4:
		music_box(b, 9.0 + k * 1.3, MOTIF[k] + 12, 1.0, 0.36)
		piano_note(b, 9.0 + k * 1.3, MOTIF[k], 1.2, 0.34)
	pad(b, 24.0, 5.0, [48, 55, 60], 0.14)
	pad(b, 29.0, 4.0, [43, 50, 55, 59], 0.14)
	# 3. It turns to A major: E, C sharp, D, A, and the long, open chord
	var turn := [76, 73, 74, 69]
	for k in 4:
		piano_note(b, 24.5 + k * 1.6, turn[k], 1.5 if k < 3 else 6.0, 0.5)
		music_box(b, 24.5 + k * 1.6, turn[k] + 12, 1.0 if k < 3 else 4.0, 0.3)
	pad(b, 33.0, 12.0, [45, 52, 57, 61, 64], 0.16)
	for k in [45, 52, 57, 61, 64]:
		piano_note(b, 33.0 + (k - 45) * 0.03, k, 6.0, 0.22)
	return reverb(b, 0.42, 1.5, 0.82)


# ================================================================ voices

## A music box tine: a bright fundamental, a fainter octave and twelfth, a
## quick ring that fades over a couple of seconds.
func music_box(b: PackedFloat32Array, start: float, midi: int, beats: float, vel: float) -> void:
	var f := 440.0 * pow(2.0, (midi - 69) / 12.0)
	var first := int(start * RATE)
	var length := mini(int((beats + 2.4) * RATE), b.size() - first)
	for i in length:
		var t := i / float(RATE)
		var env := minf(t / 0.002, 1.0) * exp(-t / 1.1)
		var s := sin(TAU * f * t) + 0.35 * sin(TAU * f * 2.0 * t) * exp(-t / 0.4) + 0.12 * sin(TAU * f * 3.0 * t) * exp(-t / 0.2)
		b[first + i] += s * env * vel


## A struck bell: inharmonic partials with long, separate decays.
func bell(b: PackedFloat32Array, start: float, midi: int, vel: float) -> void:
	var f := 440.0 * pow(2.0, (midi - 69) / 12.0)
	var first := int(start * RATE)
	var partials := [[0.5, 1.0, 4.5], [1.0, 0.8, 3.2], [1.19, 0.45, 2.4], [1.56, 0.35, 1.8], [2.0, 0.3, 1.6], [2.51, 0.2, 1.0], [3.0, 0.12, 0.8]]
	for p in partials:
		var fh: float = f * p[0]
		var length := mini(int(p[2] * 6.0 * RATE), b.size() - first)
		var phase := rng.randf() * TAU
		for i in length:
			var t := i / float(RATE)
			b[first + i] += sin(phase + TAU * fh * t) * vel * p[1] * minf(t / 0.004, 1.0) * exp(-t / p[2])


## A soft pad: slightly detuned sines that swell in and fade out.
func pad(b: PackedFloat32Array, start: float, seconds: float, notes: Array, vel: float) -> void:
	var first := int(start * RATE)
	var length := mini(int((seconds + 3.0) * RATE), b.size() - first)
	for midi in notes:
		var f := 440.0 * pow(2.0, (midi - 69) / 12.0)
		for detune in [0.997, 1.003]:
			var fh: float = f * detune
			for i in length:
				var t := i / float(RATE)
				var env := clampf(t / 2.5, 0.0, 1.0) * clampf((seconds + 3.0 - t) / 3.0, 0.0, 1.0)
				b[first + i] += sin(TAU * fh * t) * vel * env * 0.5


func piano_note(b: PackedFloat32Array, start: float, midi: int, beats: float, vel: float) -> void:
	var f := 440.0 * pow(2.0, (midi - 69) / 12.0)
	var ring := clampf(5.0 - (midi - 40) * 0.07, 1.4, 5.0)
	var held := beats
	var first := int(start * RATE)
	var count := mini(int((held + ring) * RATE), b.size() - first)
	var inharmonic := 0.00035
	for h in range(1, 7):
		var fh := h * f * sqrt(1.0 + inharmonic * h * h)
		if fh > RATE * 0.45:
			break
		var amp := vel / pow(h, 1.15) * (1.0 if h == 1 else 0.8)
		var decay := ring / (1.0 + 0.55 * (h - 1))
		var phase := rng.randf() * TAU
		var step := TAU * fh / RATE
		var audible := mini(count, int(decay * 9.2 * RATE))
		for i in audible:
			var t := i / float(RATE)
			var env := minf(t / 0.003, 1.0) * exp(-t / decay)
			if t > held:
				env *= exp(-(t - held) / 0.9)
			b[first + i] += amp * sin(phase + step * i) * env


# ================================================================ helpers (as in generate_music.gd)

func buffer(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


func _delay_line(ms: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(maxi(int(ms * RATE / 1000.0), 1))
	return buf


## Schroeder reverb (four damped combs, two allpasses). The cues end in
## silence, so the tail that wraps round to the start is inaudible.
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
		out[s] = x * (1.0 - wet * 0.5) + acc * wet
	return out


func write(sound_name: String, samples: PackedFloat32Array, gain: float) -> void:
	var peak := 0.0001
	for s in samples:
		peak = maxf(peak, absf(s))
	# A short fade at the very end, so the cue never clicks off
	var fade := int(0.5 * RATE)
	for i in fade:
		samples[samples.size() - 1 - i] *= float(i) / fade
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
