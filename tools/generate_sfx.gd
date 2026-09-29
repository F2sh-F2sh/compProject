extends SceneTree

## Synthesises the game's sound effects into res://assets/audio/sfx/*.wav.
## Everything is generated from sine waves and filtered noise, so there are
## no third-party licences involved. Re-run to regenerate:
##   godot --headless --path . --script res://tools/generate_sfx.gd

const RATE := 22050
const OUT := "res://assets/audio/sfx/"

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 77
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	# Puzzle feedback
	write("bell", mix([bell(330.0, 2.6), click(0.004, 0.6)]), 0.7)
	write("switch_on", mix([chime(660.0, 0.5), offset(chime(990.0, 0.5), 0.08)]), 0.45)
	write("power_down", mix([chime(784.0, 0.45), offset(chime(523.0, 0.5), 0.09)]), 0.35)
	write("receiver_on", mix([chime(1319.0, 0.8, 0.02), chime(1976.0, 0.7, 0.03)]), 0.35)
	write("puzzle_solved", mix([chime(523.0, 1.2), offset(chime(659.0, 1.1), 0.13),
		offset(chime(784.0, 1.0), 0.26), offset(bell(1047.0, 1.4), 0.39)]), 0.55)
	write("checkpoint", mix([pad(392.0, 1.4), pad(494.0, 1.4), pad(587.0, 1.4)]), 0.4)
	write("collect", mix([blip(1568.0, 0.18), offset(blip(2093.0, 0.18), 0.07), offset(blip(2637.0, 0.3), 0.14)]), 0.4)
	write("hint", mix([pad(294.0, 0.9), noise(0.9, 0.08, 0.35, 0.05, 0.3)]), 0.3)
	write("room_reset", mix([swell(0.55), offset(chime(880.0, 0.5), 0.5)]), 0.4)

	# Mechanisms
	write("lever", mix([thud(110.0, 0.35, 0.09), click(0.02, 0.5), noise(0.2, 0.05, 0.2, 0.0, 0.3)]), 0.55)
	write("plate_down", mix([thud(80.0, 0.25, 0.06), noise(0.15, 0.04, 0.15, 0.0, 0.4)]), 0.45)
	write("plate_up", thud(140.0, 0.14, 0.04), 0.3)
	write("gate_rumble", rumble(1.0), 0.45)
	write("gate_slam", mix([thud(60.0, 0.5, 0.15), noise(0.4, 0.1, 0.1, 0.0, 0.6)]), 0.5)
	write("mirror_rotate", mix([noise(0.22, 0.12, 0.25, 0.02, 0.5), offset(click(0.015, 0.4), 0.2)]), 0.4)
	write("brazier_ignite", mix([whoosh(0.7), crackle(0.8, 10)]), 0.5)
	write("crate_scrape", scrape(0.3), 0.3)

	# Traps
	write("piston_warn", mix([click(0.015, 0.7), offset(click(0.015, 0.6), 0.09)]), 0.4)
	write("piston_slam", mix([thud(55.0, 0.5, 0.2), noise(0.35, 0.12, 0.1, 0.0, 0.7)]), 0.55)
	write("bolt_charge", sweep(200.0, 900.0, 0.55, true), 0.3)
	write("bolt_fire", mix([sweep(1200.0, 300.0, 0.22, false), noise(0.12, 0.05, 0.7, 0.0, 0.4)]), 0.4)
	write("bolt_impact", mix([noise(0.15, 0.06, 0.4, 0.0, 0.6), thud(300.0, 0.15, 0.05)]), 0.35)
	write("vent_warn", noise(0.35, 0.3, 0.8, 0.05, 0.15), 0.18)
	write("vent_burst", mix([noise(0.7, 0.4, 0.85, 0.03, 0.35), chime(1760.0, 0.6, 0.05)]), 0.35)
	write("crumble_crack", crackle(0.4, 8), 0.4)
	write("crumble_fall", mix([noise(0.5, 0.35, 0.12, 0.0, 0.5), offset(thud(90.0, 0.3, 0.08), 0.15)]), 0.45)

	# Creatures
	write("wisp_call", mix([blip(988.0, 0.25), offset(blip(1319.0, 0.25), 0.08), offset(blip(1760.0, 0.4), 0.16)]), 0.35)
	write("wisp_arrive", bell(1175.0, 0.9), 0.3)
	write("gargoyle_windup", growl(0.55), 0.5)
	write("gargoyle_attack", whoosh(0.28), 0.45)
	write("gargoyle_freeze", mix([crackle(0.5, 12), sweep(1400.0, 700.0, 0.6, false)]), 0.4)
	write("gargoyle_wake", rumble(0.5), 0.4)
	write("slime_alert", sweep(300.0, 720.0, 0.18, false), 0.35)
	write("slime_hurt", sweep(520.0, 240.0, 0.16, false), 0.35)
	write("slime_die", mix([sweep(420.0, 110.0, 0.35, false), noise(0.3, 0.12, 0.3, 0.0, 0.4)]), 0.4)

	# Player / UI
	write("player_hurt", mix([sweep(190.0, 85.0, 0.25, false), noise(0.2, 0.06, 0.25, 0.0, 0.5)]), 0.5)
	write("echo_start", mix([chime(587.0, 0.4, 0.03), noise(0.3, 0.1, 0.6, 0.02, 0.15)]), 0.3)
	write("echo_spawn", mix([swell(0.35), offset(bell(784.0, 0.9), 0.3)]), 0.35)
	write("ui_click", blip(1500.0, 0.05), 0.25)
	write("ui_open", sweep(800.0, 1200.0, 0.1, false), 0.25)

	# Echidna's body (routed through the room reverb like every positional sound)
	write("footstep", mix([noise(0.12, 0.035, 0.22, 0.002, 0.2), thud(160.0, 0.1, 0.03)]), 0.35)
	write("land", mix([thud(95.0, 0.3, 0.07), noise(0.25, 0.06, 0.18, 0.0, 0.3)]), 0.45)
	write("jump", mix([whoosh(0.16), sweep(260.0, 420.0, 0.12, false)]), 0.25)
	write("spell_cast", mix([whoosh(0.32), sweep(300.0, 900.0, 0.25, false), offset(crackle(0.3, 6), 0.05)]), 0.4)
	print("SFX DONE")
	quit()


# ------------------------------------------------------------------ output

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


# ------------------------------------------------------------------ building blocks

func length(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


func env(t: float, attack: float, decay: float) -> float:
	var a := clampf(t / maxf(attack, 0.0001), 0.0, 1.0)
	return a * exp(-maxf(t - attack, 0.0) / maxf(decay, 0.0001))


func partials(base: float, ratios: Array, amps: Array, decays: Array, seconds: float, attack := 0.002) -> PackedFloat32Array:
	var b := length(seconds)
	for i in b.size():
		var t := i / float(RATE)
		var v := 0.0
		for p in ratios.size():
			v += amps[p] * sin(TAU * base * ratios[p] * t) * env(t, attack, decays[p])
		b[i] = v
	return b


func bell(base: float, seconds: float) -> PackedFloat32Array:
	return partials(base, [0.5, 1.0, 1.19, 1.5, 2.0, 2.52, 3.0, 4.1],
		[0.45, 1.0, 0.55, 0.4, 0.35, 0.22, 0.18, 0.08],
		[seconds * 0.8, seconds * 0.6, seconds * 0.45, seconds * 0.35, seconds * 0.28, seconds * 0.2, seconds * 0.15, seconds * 0.1], seconds)


func chime(base: float, seconds: float, attack := 0.004) -> PackedFloat32Array:
	return partials(base, [1.0, 2.01, 3.0], [1.0, 0.35, 0.12], [seconds * 0.5, seconds * 0.3, seconds * 0.15], seconds, attack)


func pad(base: float, seconds: float) -> PackedFloat32Array:
	return partials(base, [1.0, 2.0], [1.0, 0.25], [seconds * 0.6, seconds * 0.3], seconds, 0.08)


func blip(freq: float, seconds: float) -> PackedFloat32Array:
	return partials(freq, [1.0, 2.0], [1.0, 0.2], [seconds * 0.35, seconds * 0.15], seconds)


func thud(freq: float, seconds: float, decay: float) -> PackedFloat32Array:
	var b := length(seconds)
	var phase := 0.0
	for i in b.size():
		var t := i / float(RATE)
		# Pitch drops slightly for a weighty impact
		phase += TAU * freq * (1.0 + 0.6 * exp(-t / 0.03)) / RATE
		b[i] = sin(phase) * env(t, 0.002, decay)
	return b


func click(decay: float, brightness: float) -> PackedFloat32Array:
	return partials(1800.0, [1.0, 1.5, 2.3], [1.0, 0.6 * brightness, 0.4 * brightness], [decay, decay * 0.8, decay * 0.6], decay * 6.0 + 0.02, 0.0005)


## lowpass: 0..1 (higher is brighter); highpass removes low rumble when > 0.
func noise(seconds: float, decay: float, lowpass: float, attack := 0.0, highpass := 0.0) -> PackedFloat32Array:
	var b := length(seconds)
	var lp := 0.0
	var hp_prev := 0.0
	for i in b.size():
		var t := i / float(RATE)
		var n := rng.randf_range(-1.0, 1.0)
		lp += (n - lp) * lowpass
		var v := lp - hp_prev * highpass
		hp_prev = lp
		b[i] = v * env(t, attack, decay)
	return b


func sweep(f0: float, f1: float, seconds: float, rising_amp: bool) -> PackedFloat32Array:
	var b := length(seconds)
	var phase := 0.0
	for i in b.size():
		var t := i / float(RATE)
		var k := t / seconds
		phase += TAU * lerpf(f0, f1, k) / RATE
		var amp := k if rising_amp else env(t, 0.004, seconds * 0.45)
		b[i] = (sin(phase) + 0.3 * sin(phase * 2.0)) * amp * (1.0 - k * 0.2)
	return b


func whoosh(seconds: float) -> PackedFloat32Array:
	var b := length(seconds)
	var lp := 0.0
	for i in b.size():
		var t := i / float(RATE)
		var k := t / seconds
		lp += (rng.randf_range(-1.0, 1.0) - lp) * lerpf(0.03, 0.4, k)
		b[i] = lp * sin(PI * k)
	return b


func crackle(seconds: float, pops: int) -> PackedFloat32Array:
	var b := length(seconds)
	for p in pops:
		var start := rng.randi_range(0, b.size() - 400)
		var strength := rng.randf_range(0.4, 1.0)
		for j in 380:
			b[start + j] += rng.randf_range(-1.0, 1.0) * strength * exp(-j / 60.0)
	return b


func rumble(seconds: float) -> PackedFloat32Array:
	var b := length(seconds)
	var lp := 0.0
	for i in b.size():
		var t := i / float(RATE)
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.03
		var fade := minf(t / 0.08, 1.0) * minf((seconds - t) / 0.2, 1.0)
		b[i] = lp * (0.6 + 0.4 * sin(TAU * 9.0 * t)) * fade + sin(TAU * 48.0 * t) * 0.15 * fade
	return b


func scrape(seconds: float) -> PackedFloat32Array:
	var b := length(seconds)
	var lp := 0.0
	for i in b.size():
		var t := i / float(RATE)
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.15
		var fade := minf(t / 0.03, 1.0) * minf((seconds - t) / 0.08, 1.0)
		b[i] = lp * (0.5 + 0.5 * absf(sin(TAU * 23.0 * t))) * fade
	return b


func growl(seconds: float) -> PackedFloat32Array:
	var b := length(seconds)
	var phase := 0.0
	for i in b.size():
		var t := i / float(RATE)
		var mod := sin(TAU * 23.0 * t) * 3.0
		phase += TAU * 70.0 / RATE
		b[i] = sin(phase + mod) * minf(t / (seconds * 0.7), 1.0) * minf((seconds - t) / 0.08, 1.0) \
			+ rng.randf_range(-0.15, 0.15) * t / seconds
	return b


func swell(seconds: float) -> PackedFloat32Array:
	var b := length(seconds)
	var lp := 0.0
	for i in b.size():
		var t := i / float(RATE)
		var k := t / seconds
		lp += (rng.randf_range(-1.0, 1.0) - lp) * lerpf(0.02, 0.3, k)
		b[i] = lp * k * k
	return b


func offset(samples: PackedFloat32Array, seconds: float) -> PackedFloat32Array:
	var pad_len := int(seconds * RATE)
	var b := PackedFloat32Array()
	b.resize(pad_len + samples.size())
	for i in samples.size():
		b[pad_len + i] = samples[i]
	return b


func mix(parts: Array) -> PackedFloat32Array:
	var n := 0
	for p in parts:
		n = maxi(n, p.size())
	var b := PackedFloat32Array()
	b.resize(n)
	for p in parts:
		for i in p.size():
			b[i] += p[i]
	return b
