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

	# Added later: always append below, so every sound above stays identical.
	# Footsteps: a soft heel on stone, a short scuff of the sole and a whisper
	# of cloth, low-passed so they sit under everything else. Four variants
	# (played in a shuffled order) keep them from sounding mechanical.
	for i in 4:
		var heel := thud(rng.randf_range(105.0, 140.0), 0.09, rng.randf_range(0.012, 0.018))
		var scuff := noise(0.1, rng.randf_range(0.018, 0.03), rng.randf_range(0.12, 0.2), 0.003, 0.35)
		var cloth := scaled(noise(0.16, 0.045, 0.45, rng.randf_range(0.012, 0.025), 0.6), 0.25)
		write("step_stone_%d" % (i + 1), soften(mix([heel, offset(scuff, 0.004), offset(cloth, 0.01)]), 0.35), 0.3)
	# The iron grate: a small metallic tick over the same soft heel
	for i in 2:
		var ring := partials(rng.randf_range(1350.0, 1650.0), [1.0, 2.76, 5.4], [1.0, 0.45, 0.2],
			[0.05, 0.03, 0.015], 0.2, 0.0005)
		var heel := thud(rng.randf_range(140.0, 170.0), 0.09, 0.015)
		write("step_grate_%d" % (i + 1), mix([scaled(ring, 0.35), heel, noise(0.06, 0.02, 0.3, 0.002, 0.4)]), 0.28)
	# A puzzle slime's ward turning a hit aside
	write("ward_clink", mix([partials(2093.0, [1.0, 2.4, 3.9], [1.0, 0.4, 0.2], [0.12, 0.06, 0.03], 0.35, 0.0005),
		offset(chime(1568.0, 0.4), 0.03)]), 0.3)
	# Healing is a short channel: a rising shimmer, then a warm chord
	write("heal_charge", mix([rising_pad(392.0, 587.0, 1.2), offset(scaled(blip(2349.0, 0.12), 0.3), 0.2),
		offset(scaled(blip(2637.0, 0.12), 0.3), 0.45), offset(scaled(blip(3136.0, 0.12), 0.3), 0.7),
		offset(scaled(blip(3520.0, 0.12), 0.3), 0.95)]), 0.28)
	write("heal_done", mix([chime(784.0, 0.9), offset(chime(1175.0, 0.8), 0.06), offset(scaled(bell(1568.0, 0.9), 0.5), 0.12)]), 0.4)
	write("heal_cancel", sweep(620.0, 300.0, 0.18, false), 0.22)
	# Echoes: a soft clock tick for the last seconds of a recording, and a
	# falling shimmer when an Echo lets go
	write("echo_tick", mix([blip(1760.0, 0.08), scaled(click(0.01, 0.3), 0.5)]), 0.22)
	write("echo_fade", mix([sweep(880.0, 330.0, 0.5, false), scaled(noise(0.45, 0.15, 0.4, 0.02, 0.3), 0.4)]), 0.28)
	# The great bell: a deep, long toll with a bright strike and a low hum
	write("great_bell", mix([bell(98.0, 7.0), scaled(bell(147.0, 5.5), 0.5), scaled(bell(392.0, 3.0), 0.25),
		scaled(thud(65.0, 1.2, 0.3), 0.6), click(0.006, 0.5)]), 0.85)
	# Feel pass: a fireball bursting, a spell with no mana behind it, the
	# mana refill, Echidna falling, a low-health heartbeat, a room cleared
	write("fireball_hit", mix([noise(0.3, 0.07, 0.55, 0.0, 0.3), thud(120.0, 0.25, 0.06), offset(crackle(0.25, 5), 0.02)]), 0.45)
	write("fizzle", mix([noise(0.25, 0.08, 0.3, 0.005, 0.5), sweep(420.0, 180.0, 0.18, false)]), 0.25)
	write("reload_start", mix([swell(0.35), offset(blip(880.0, 0.12), 0.25)]), 0.25)
	write("reload_done", mix([chime(988.0, 0.5), offset(chime(1319.0, 0.5), 0.07)]), 0.3)
	write("player_death", mix([sweep(330.0, 70.0, 0.9, false), scaled(noise(0.9, 0.4, 0.2, 0.05, 0.3), 0.5),
		offset(scaled(bell(196.0, 1.6), 0.4), 0.2)]), 0.5)
	write("heartbeat", mix([thud(58.0, 0.2, 0.05), offset(scaled(thud(52.0, 0.2, 0.05), 0.7), 0.18)]), 0.4)
	write("room_clear", mix([chime(659.0, 0.9), offset(chime(784.0, 0.9), 0.1), offset(chime(988.0, 1.0), 0.2),
		offset(scaled(pad(330.0, 1.4), 0.5), 0.05)]), 0.4)
	# Rune cubes: stone set down and picked up, a rune waking and going
	# quiet, a refusal, a fragment learned, mana running dry
	write("rune_select", mix([blip(1320.0, 0.09), scaled(click(0.01, 0.4), 0.6)]), 0.22)
	write("rune_place", mix([thud(120.0, 0.22, 0.05), click(0.012, 0.35), noise(0.12, 0.03, 0.2, 0.0, 0.4)]), 0.4)
	write("rune_socket", mix([chime(523.0, 0.7), thud(90.0, 0.2, 0.05), offset(scaled(chime(784.0, 0.6), 0.6), 0.08)]), 0.35)
	write("rune_activate", mix([swell(0.3), offset(chime(880.0, 0.6), 0.2), offset(chime(1319.0, 0.5), 0.28)]), 0.35)
	write("rune_deactivate", mix([chime(659.0, 0.4), offset(sweep(700.0, 300.0, 0.25, false), 0.05)]), 0.26)
	write("rune_blocked", mix([thud(90.0, 0.15, 0.04), sweep(300.0, 200.0, 0.14, false), scaled(click(0.01, 0.3), 0.5)]), 0.3)
	write("rune_learn", mix([chime(587.0, 1.0), offset(chime(880.0, 0.9), 0.1), offset(bell(1175.0, 1.2), 0.2),
		scaled(pad(294.0, 1.2), 0.5)]), 0.4)
	write("rune_exhaust", mix([sweep(600.0, 150.0, 0.7, false), scaled(noise(0.6, 0.3, 0.25, 0.02, 0.4), 0.5),
		offset(thud(70.0, 0.3, 0.1), 0.1)]), 0.45)
	# Their magic: wind, stone breaking, portals, ice, light and fire
	write("wind_gust", mix([whoosh(0.5), scaled(noise(0.5, 0.18, 0.4, 0.03, 0.2), 0.6)]), 0.45)
	write("wind_loop", fade_ends(soften(noise(2.0, 60.0, 0.22, 0.0, 0.1), 0.2), 0.06), 0.22)
	write("crate_thud", mix([thud(100.0, 0.25, 0.06), noise(0.12, 0.04, 0.2, 0.0, 0.4)]), 0.4)
	write("wall_break", mix([noise(1.0, 0.4, 0.15, 0.0, 0.5), thud(55.0, 0.8, 0.25), offset(crackle(0.8, 16), 0.05),
		offset(noise(0.8, 0.3, 0.1, 0.0, 0.6), 0.25)]), 0.6)
	write("portal_open", mix([rising_pad(220.0, 440.0, 0.8), offset(chime(880.0, 0.8), 0.5)]), 0.35)
	write("portal_close", sweep(700.0, 250.0, 0.35, false), 0.25)
	write("portal_warp", mix([sweep(300.0, 1400.0, 0.25, true), offset(sweep(1400.0, 500.0, 0.25, false), 0.2),
		scaled(noise(0.4, 0.1, 0.6, 0.02, 0.3), 0.4)]), 0.35)
	write("ice_form", mix([crackle(0.5, 14), chime(1760.0, 0.6, 0.02), scaled(sweep(900.0, 1800.0, 0.3, false), 0.5)]), 0.35)
	write("ice_freeze", mix([crackle(0.4, 10), sweep(1400.0, 900.0, 0.4, false)]), 0.33)
	write("ice_crack", mix([crackle(0.35, 9), noise(0.3, 0.08, 0.5, 0.0, 0.5)]), 0.33)
	write("ice_melt", mix([noise(0.8, 0.3, 0.35, 0.05, 0.4), scaled(sweep(600.0, 300.0, 0.6, false), 0.4)]), 0.3)
	write("beam_on", mix([chime(1319.0, 0.7, 0.02), scaled(sweep(600.0, 1300.0, 0.3, false), 0.5)]), 0.3)
	write("fire_blast", mix([noise(0.6, 0.15, 0.5, 0.0, 0.2), thud(80.0, 0.5, 0.12), crackle(0.6, 12)]), 0.55)
	write("brambles_burn", mix([whoosh(0.8), crackle(1.2, 24)]), 0.45)
	write("ui_hover", blip(2000.0, 0.03), 0.12)
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


func scaled(samples: PackedFloat32Array, k: float) -> PackedFloat32Array:
	var b := samples.duplicate()
	for i in b.size():
		b[i] *= k
	return b


## One-pole low-pass over a finished sound (0..1, lower is darker).
func soften(samples: PackedFloat32Array, a: float) -> PackedFloat32Array:
	var b := samples.duplicate()
	var lp := 0.0
	for i in b.size():
		lp += (b[i] - lp) * a
		b[i] = lp
	return b


## A soft pad that glides upward and swells, for a charging spell.
func rising_pad(f0: float, f1: float, seconds: float) -> PackedFloat32Array:
	var b := length(seconds)
	var phase := 0.0
	for i in b.size():
		var t := i / float(RATE)
		var k := t / seconds
		phase += TAU * lerpf(f0, f1, k * k) / RATE
		var amp := k * minf((seconds - t) / 0.05, 1.0)
		b[i] = (sin(phase) + 0.4 * sin(phase * 2.0) + 0.2 * sin(phase * 3.0)) * amp
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


## Short fades at both ends, so a looping sound wraps without a click.
func fade_ends(samples: PackedFloat32Array, seconds: float) -> PackedFloat32Array:
	var b := samples.duplicate()
	var n := mini(int(seconds * RATE), b.size() / 2)
	for i in n:
		var k := float(i) / n
		b[i] *= k
		b[b.size() - 1 - i] *= k
	return b
