extends Node

## Tests for the presentation layer: Echidna's sprite pipeline and animation
## feel, the damped camera, parallax, light shafts, the post pass, glows and
## the adaptive audio. Run through tests/run_tests.gd:  -- presentation [scenario]

const CHAPTER := "res://scenes/chapter/chapter_1.tscn"
const TUTORIAL := "res://scenes/tutorial_level.tscn"
const FRAMES := "res://assets/sprites/Echidna/echidna_frames.tres"
const SHEETS := "res://assets/sprites/Echidna/"
const SHOTS := "user://test_shots/"
const DT := 1.0 / 60.0
const FLOOR := 530.0

var lvl: Node
var player: CharacterBody2D
var passed := 0
var failed := 0


func run_suite(filter: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOTS))
	await get_tree().process_frame
	var scenarios := {
		"frames": scenario_frames,
		"motion": scenario_motion,
		"charge": scenario_charge,
		"camera": scenario_camera,
		"parallax": scenario_parallax,
		"light": scenario_light,
		"post": scenario_post,
		"brightness": scenario_brightness,
		"glow": scenario_glow,
		"audio": scenario_audio,
		"hazards": scenario_hazards,
		"look": scenario_look,
	}
	for key in scenarios:
		if filter == key or (filter == "" and key != "look"):
			await scenarios[key].call()
	_release_all()
	get_tree().paused = false
	print("presentation suite: passed=%d failed=%d" % [passed, failed])


# ================================================================ helpers

func check(label: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
		print("  PASS ", label, "  ", detail)
	else:
		failed += 1
		print("  FAIL ", label, "  ", detail)


func _release_all() -> void:
	for a in ["move_left", "move_right", "jump", "crouch", "sprint", "shoot", "interact"]:
		Input.action_release(a)


func load_level(path: String) -> void:
	_release_all()
	get_tree().paused = false
	get_tree().root.get_node("GameState").clear_all()
	if is_instance_valid(get_tree().current_scene):
		get_tree().current_scene.queue_free()
	await get_tree().process_frame
	lvl = load(path).instantiate()
	get_tree().root.add_child(lvl)
	get_tree().current_scene = lvl
	await get_tree().process_frame
	await get_tree().physics_frame
	player = lvl.get_node("Player")
	await frames(10)


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func seconds(s: float) -> void:
	await frames(int(s * 60.0))


func wait_until(cond: Callable, timeout_s: float) -> bool:
	var t := 0.0
	while not cond.call():
		await get_tree().physics_frame
		t += DT
		if t > timeout_s:
			return false
	return true


func place(pos: Vector2) -> void:
	player.teleport_to(pos)
	await frames(8)


func camera() -> Camera2D:
	return player.get_node("Camera2D")


func screen_image() -> Image:
	await get_tree().process_frame
	await get_tree().process_frame
	return get_tree().root.get_texture().get_image()


func world_to_screen(p: Vector2) -> Vector2:
	return lvl.get_viewport().get_canvas_transform() * p


func region_luma(img: Image, center: Vector2, half: Vector2) -> float:
	var sum := 0.0
	var count := 0
	for y in range(int(center.y - half.y), int(center.y + half.y)):
		for x in range(int(center.x - half.x), int(center.x + half.x)):
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				var c := img.get_pixel(x, y)
				sum += c.r * 0.299 + c.g * 0.587 + c.b * 0.114
				count += 1
	return sum / maxf(count, 1)


func shot(file_name: String) -> void:
	var img := await screen_image()
	img.save_png(ProjectSettings.globalize_path(SHOTS + file_name + ".png"))


# ================================================================ sprite pipeline

func _canvas_rect(tex: AtlasTexture) -> Rect2:
	return Rect2(tex.margin.position, tex.region.size)


func _eyes_in_canvas(tex: AtlasTexture) -> Variant:
	var img: Image = tex.atlas.get_image()
	var sum := Vector2.ZERO
	var count := 0
	var r := tex.region
	for y in int(r.size.y):
		for x in int(r.size.x):
			var c := img.get_pixel(int(r.position.x) + x, int(r.position.y) + y)
			if c.a > 0.5 and c.r > 0.8 and c.g > 0.8 and c.b > 0.8:
				sum += Vector2(x, y) + tex.margin.position
				count += 1
	return sum / count if count >= 8 else null


func scenario_frames() -> void:
	print("SCENARIO Echidna's sprite pipeline")
	var frames_res: SpriteFrames = load(FRAMES)
	var needed := [&"idle", &"run", &"sprint", &"run_stop", &"crouch", &"land", &"jump", &"apex", &"fall",
		&"JumpCharge", &"JumpChargeWisps"]
	var missing := needed.filter(func(a): return not frames_res.has_animation(a))
	check("every clip exists", missing.is_empty(), str(missing))

	var sizes_ok := true
	var ground_ok := true
	var bad := ""
	for anim in frames_res.get_animation_names():
		for i in frames_res.get_frame_count(anim):
			var tex := frames_res.get_frame_texture(anim, i) as AtlasTexture
			if tex == null or tex.get_size() != Vector2(80, 80):
				sizes_ok = false
				bad += " %s:%d size" % [anim, i]
				continue
			# Ground clips stand exactly on the pivot row (71)
			if anim in [&"idle", &"run", &"sprint", &"run_stop", &"JumpCharge", &"crouch", &"land"]:
				if int(_canvas_rect(tex).end.y) - 1 != 71:
					ground_ok = false
					bad += " %s:%d feet@%d" % [anim, i, int(_canvas_rect(tex).end.y) - 1]
	check("every frame shares one 80x80 canvas", sizes_ok, bad)
	check("ground poses stand on the bottom-centre pivot", ground_ok, bad)
	check("clips carry their pivot offset", frames_res.get_meta(&"sprite_offset", Vector2.ZERO) == Vector2(0, -32))

	# Snappy timing: per-frame holds, quick blinks and recoveries
	var clip_seconds := func(anim: StringName) -> float:
		var total := 0.0
		for i in frames_res.get_frame_count(anim):
			total += frames_res.get_frame_duration(anim, i)
		return total / frames_res.get_animation_speed(anim)
	var idle_durations := []
	for i in frames_res.get_frame_count(&"idle"):
		idle_durations.append(frames_res.get_frame_duration(&"idle", i))
	check("idle uses custom per-frame holds", idle_durations.max() >= 3.0 * idle_durations.min(), str(idle_durations))
	check("walk cycle is brisk (0.3-0.5 s)", clip_seconds.call(&"run") >= 0.3 and clip_seconds.call(&"run") <= 0.5,
		"%.2f s" % clip_seconds.call(&"run"))
	check("sprint cycle is faster than the walk", clip_seconds.call(&"sprint") < clip_seconds.call(&"run"))
	check("landing and stop recoveries are fast (<= 0.12 s)",
		clip_seconds.call(&"land") <= 0.12 and clip_seconds.call(&"run_stop") <= 0.12,
		"land %.2f stop %.2f" % [clip_seconds.call(&"land"), clip_seconds.call(&"run_stop")])
	check("walk strides hold longer than passing poses",
		frames_res.get_frame_duration(&"run", 0) > frames_res.get_frame_duration(&"run", 1))
	var unique := {}
	for i in frames_res.get_frame_count(&"idle"):
		unique[frames_res.get_frame_texture(&"idle", i)] = true
	check("duplicate source frames share one texture", unique.size() < 18, "%d textures" % unique.size())

	# The art is untouched: body + wisps rebuild the original hold-jump sheet
	var hold := Image.load_from_file(ProjectSettings.globalize_path(SHEETS + "EchidnaHoldJump.png"))
	var body := Image.load_from_file(ProjectSettings.globalize_path(SHEETS + "EchidnaCharge.png"))
	var wisps := Image.load_from_file(ProjectSettings.globalize_path(SHEETS + "EchidnaChargeWisps.png"))
	var mismatches := 0
	for y in hold.get_height():
		for x in hold.get_width():
			var w := wisps.get_pixel(x, y)
			var rebuilt := w if w.a > 0.0 else body.get_pixel(x, y)
			if not rebuilt.is_equal_approx(hold.get_pixel(x, y)):
				mismatches += 1
	check("charge body + wisp layer == original hold-jump art, pixel for pixel", mismatches == 0, "%d differ" % mismatches)
	var region_ok := true
	for anim in [&"idle", &"run", &"JumpCharge", &"jump"]:
		var tex := frames_res.get_frame_texture(anim, 0) as AtlasTexture
		var src: Image = tex.atlas.get_image()
		var r := Rect2i(tex.region)
		var cell := Rect2i((r.position.x / 64) * 64, (r.position.y / 64) * 64, 64, 64)
		region_ok = region_ok and cell.encloses(r) and src.get_region(r).get_used_rect().size == r.size
	check("frames are clean trims of the original cells", region_ok)

	# Switching clips keeps her head in place
	var eyes := {}
	for anim in [&"idle", &"run", &"JumpCharge", &"crouch"]:
		eyes[anim] = _eyes_in_canvas(frames_res.get_frame_texture(anim, 0) as AtlasTexture)
	var xs := []
	for e in eyes.values():
		if e != null:
			xs.append(e.x)
	check("head stays put between idle, walk, charge and crouch (<= 3 px)", xs.size() == 4 and xs.max() - xs.min() <= 3.0,
		str(eyes))


# ================================================================ motion feel

func scenario_motion() -> void:
	print("SCENARIO motion and footfalls")
	await load_level(TUTORIAL)
	var sprite: AnimatedSprite2D = player.animated_sprite
	await place(Vector2(400, FLOOR))
	check("sprite sits on her feet (pivot at the node)", absf(sprite.position.y) < 0.5 and sprite.offset == Vector2(0, -32),
		"pos %s offset %s" % [sprite.position, sprite.offset])
	check("she wears the lighting material", sprite.material is ShaderMaterial
		and (sprite.material as ShaderMaterial).shader.resource_path.ends_with("character_lit.gdshader"))
	var steps := [0]
	player.footstep.connect(func(_p): steps[0] += 1)
	Input.action_press("move_right")
	await seconds(1.2)
	Input.action_release("move_right")
	check("walking plants a foot about five times a second", steps[0] >= 4 and steps[0] <= 8, "%d steps in 1.2 s" % steps[0])
	check("walking into a stop plays the recovery", await wait_until(func(): return sprite.animation == &"run_stop", 0.4))
	check("recovery hands back to idle quickly", await wait_until(func(): return sprite.animation == &"idle", 0.4))
	# A tap still shows a stride
	var tap_steps: int = steps[0]
	Input.action_press("move_right")
	await frames(3)
	Input.action_release("move_right")
	var strode := await wait_until(func(): return sprite.animation == &"run", 0.2)
	check("a tap shows a stride", strode or steps[0] > tap_steps)
	await seconds(0.6)
	# Jump and land
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	await wait_until(func(): return not player.is_on_floor(), 0.4)
	await wait_until(func(): return player.is_on_floor(), 2.0)
	var landed_anim := sprite.animation
	check("landing plays a one-frame recovery", landed_anim == &"land", str(landed_anim))
	check("landing recovery is over within 0.15 s", await wait_until(func(): return sprite.animation != &"land", 0.15))
	var shadow: Sprite2D = player.get_node("ContactShadow")
	check("contact shadow sits under her feet", shadow.modulate.a > 0.3 and absf(shadow.position.y) < 0.5)
	# Sprinting is a faster cadence
	steps[0] = 0
	Input.action_press("move_right")
	Input.action_press("sprint")
	await seconds(1.0)
	_release_all()
	check("sprinting plants feet faster than walking", steps[0] >= 5, "%d steps in 1 s" % steps[0])


func scenario_charge() -> void:
	print("SCENARIO charge glow, breeze and bar (no lines)")
	await load_level(TUTORIAL)
	await place(Vector2(400, FLOOR))
	check("no wind streaks or wisp lines on her", player.get_node_or_null("ChargeWisps") == null
		and player.get_node_or_null("ChargeWindBack") == null and player.get_node_or_null("ChargeWindFront") == null
		and player.find_children("*", "Line2D", true, false).is_empty())
	var light: PointLight2D = player.get_node("WispLight")
	var sparks: CPUParticles2D = player.get_node("WispSparks")
	var bar: ChargeBar = player.get_node_or_null("ChargeBar")
	var breeze: ChargeBreeze = player.get_node_or_null("ChargeBreeze")
	check("she has a charge bar and a charge breeze", bar != null and breeze != null)
	if bar == null or breeze == null:
		return
	check("no glow, breeze or bar while idle", light.energy < 0.05 and breeze.strength == 0.0 and not bar.visible,
		"%.2f %.2f %s" % [light.energy, breeze.strength, bar.visible])
	# A quick dip never flashes the bar
	Input.action_press("crouch")
	await seconds(0.3)
	Input.action_release("crouch")
	await seconds(0.3)
	check("a quick crouch shows no bar", not bar.visible)
	var chimes: int = Sfx.played.get("charge_full", 0)
	Input.action_press("crouch")
	await seconds(0.6)
	check("no glow before the charge pose", light.energy < 0.05, "%.2f" % light.energy)
	await seconds(0.8)
	check("the charge pose plays", player.animated_sprite.animation == &"JumpCharge")
	check("the bar shows over her head as the charge builds", bar.visible and bar.fill > 0.1 and bar.fill < 0.6
		and bar.global_position.y < player.global_position.y - 44.0, "fill %.2f" % bar.fill)
	check("not full yet", not bar.full)
	check("a light breeze gathers at her feet", breeze.visible and breeze.strength > 0.1, "%.2f" % breeze.strength)
	var early := light.energy
	var early_breeze := breeze.strength
	await seconds(1.4)
	check("the glow builds with the charge", light.energy > early + 0.3 and light.energy > 0.8, "%.2f -> %.2f" % [early, light.energy])
	check("the breeze grows with the charge", breeze.strength > early_breeze + 0.3, "%.2f -> %.2f" % [early_breeze, breeze.strength])
	check("sparks show the charge is full", sparks.emitting)
	check("the bar is full and marked as full", bar.full and is_equal_approx(bar.fill, 1.0), "fill %.2f" % bar.fill)
	await seconds(0.6)
	check("full power chimes once, not over and over", bar.times_full == 1 and Sfx.played.get("charge_full", 0) == chimes + 1,
		"%d times, %d chimes" % [bar.times_full, Sfx.played.get("charge_full", 0) - chimes])
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	Input.action_release("crouch")
	await frames(3)
	check("the sparks stop as she leaps", not sparks.emitting)
	check("the breeze puffs out where she stood", breeze.strength == 0.0 and breeze._scatter > 0.0)
	await seconds(0.5)
	check("the bar fades away after the leap", not bar.visible)
	await wait_until(func(): return player.is_on_floor(), 2.0)
	await seconds(0.6)
	check("the puff has settled", not breeze.visible)
	# Standing up part-way drops the charge: the bar goes, nothing chimes
	Input.action_press("crouch")
	await seconds(1.5)
	Input.action_release("crouch")
	await seconds(0.5)
	check("standing up part-way clears the bar and breeze", not bar.visible and not bar.full and breeze.strength == 0.0)
	check("no chime for a part charge", bar.times_full == 1)


# ================================================================ camera

func scenario_camera() -> void:
	print("SCENARIO damped camera")
	await load_level(TUTORIAL)
	var cam: Camera2D = camera()
	await place(Vector2(700, FLOOR))
	# (She settles a few px onto the floor after the teleport; the camera eases that)
	check("camera snaps onto the player after a teleport", absf(cam.global_position.x - player.global_position.x) < 1.0
		and absf(cam.global_position.y - player.global_position.y) < 8.0,
		"%s vs %s" % [cam.global_position.round(), player.global_position.round()])
	check("the camera trails on its own (top level)", cam.top_level)
	# Shift the player without teleporting: the camera eases after her
	player.global_position.x += 120.0
	await get_tree().process_frame
	await get_tree().process_frame
	var lag := player.global_position.x - cam.global_position.x
	check("camera lags a sudden move (damped, not rigid)", lag > 60.0, "lag %.0f px" % lag)
	await seconds(1.2)
	check("camera settles on the player within a second", absf(player.global_position.x - cam.global_position.x) < 3.0,
		"%.1f px" % absf(player.global_position.x - cam.global_position.x))
	Input.action_press("move_right")
	await seconds(1.0)
	var lead := cam.global_position.x - player.global_position.x
	Input.action_release("move_right")
	check("camera leans a little ahead of her movement", lead > 5.0 and lead < 40.0, "lead %.1f px" % lead)
	check("vertical follow is softer than horizontal", cam.follow_damping.y < cam.follow_damping.x)
	await seconds(1.0)
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	var worst := 0.0
	for i in 30:
		await get_tree().physics_frame
		worst = maxf(worst, cam.global_position.y - player.global_position.y)
	check("camera trails her up into a jump", worst > 5.0, "%.1f px" % worst)


# ================================================================ parallax

func scenario_parallax() -> void:
	print("SCENARIO parallax planes")
	await load_level(CHAPTER)
	var atmos = lvl.get_node("Atmosphere")
	var far: Parallax2D = atmos.planes["FarFog"]
	var mid: Parallax2D = atmos.planes["MidRuins"]
	var front: Parallax2D = atmos.planes["FrontVines"]
	check("three depth planes: fog, ruins, vines", far and mid and front)
	check("depth order: far < mid < world < front", far.scroll_scale.x < mid.scroll_scale.x and mid.scroll_scale.x < 1.0
		and front.scroll_scale.x > 1.0 and far.z_index < mid.z_index and front.z_index > 30)
	# Move the camera sideways inside one room and watch each plane's picture
	await place(Vector2(400, FLOOR))
	await seconds(0.3)
	var before := {}
	for plane in [far, mid, front]:
		before[plane] = plane.get_node("Picture").global_position
	var cam_before := camera().get_screen_center_position()
	await place(Vector2(1000, FLOOR))
	await seconds(0.3)
	var cam_move := camera().get_screen_center_position().x - cam_before.x
	for plane in [far, mid, front]:
		var moved: float = plane.get_node("Picture").global_position.x - before[plane].x
		# Repeating planes wrap every 1024 px
		var expected: float = cam_move * (1.0 - plane.scroll_scale.x)
		var err := absf(fposmod(moved - expected + 512.0, 1024.0) - 512.0)
		check("%s drifts at %.2fx the camera" % [plane.name, plane.scroll_scale.x], err < 1.5,
			"camera %.0f px, plane %.1f px, expected %.1f" % [cam_move, moved, expected])
	# Far and mid line up with the world at the reference camera height
	var c := camera().get_screen_center_position()
	var far_y: float = far.get_node("Picture").global_position.y
	var expect_far: float = atmos.far_top + (c.y - atmos.reference_center.y) * (1.0 - far.scroll_scale.y)
	check("far plane placed from the reference camera", absf(far_y - expect_far) < 1.5, "%.1f vs %.1f" % [far_y, expect_far])
	# Foreground pinned to the edges of the view
	var view_top := c.y - get_viewport().get_visible_rect().size.y / camera().zoom.y / 2.0
	var vines_y: float = front.get_node("Picture").global_position.y
	check("vines hang from the top edge of the view", absf(vines_y - view_top) < 1.5, "%.1f vs %.1f" % [vines_y, view_top])
	# Breaches
	var holes := 0
	var decor_broken := 0
	var wall: TileMapLayer = lvl.get_node("Background")
	var decor: TileMapLayer = lvl.get_node("BackDecor")
	for rect in atmos.breaches:
		for y in rect.size.y:
			for x in rect.size.x:
				var cell: Vector2i = rect.position + Vector2i(x, y)
				if atmos.is_open(cell):
					holes += 1
					if decor.get_cell_source_id(cell) != -1 or wall.get_cell_source_id(cell) != -1:
						decor_broken += 1
	check("breaches open the back wall", holes >= atmos.breaches.size() * 2, "%d cells" % holes)
	check("breaches never break torches or windows", decor_broken == 0)


# ================================================================ light shafts

func scenario_light() -> void:
	print("SCENARIO light shafts")
	await load_level(CHAPTER)
	var atmos = lvl.get_node("Atmosphere")
	check("every breach pours a light shaft", atmos.shafts.size() == atmos.breaches.size())
	var ends_ok := true
	for s in atmos.shafts:
		ends_ok = ends_ok and absf(s.get_end_position().y - 534.0) < 2.0
	check("shafts reach down to the floor", ends_ok)
	var shaft: LightShaft = atmos.shafts[1]
	check("shafts carry a real light, lit from above the plane", shaft.light and shaft.light.height > 0.0 and shaft.light.shadow_enabled)
	check("shafts carry drifting dust", shaft.motes and shaft.motes.emitting)
	# Echidna standing in the beam is lit by it
	var foot := shaft.get_end_position() - shaft.direction() * 40.0
	await place(Vector2(foot.x, FLOOR))
	await seconds(1.0)
	check("her spot is inside the beam", shaft.contains_point(player.global_position + Vector2(0, -20)))
	lvl.get_node("PostFX").visible = false
	var on := region_luma(await screen_image(), world_to_screen(player.global_position + Vector2(0, -14)), Vector2(6, 9))
	shaft.light.enabled = false
	shaft.visible = false
	var off := region_luma(await screen_image(), world_to_screen(player.global_position + Vector2(0, -14)), Vector2(6, 9))
	shaft.light.enabled = true
	shaft.visible = true
	lvl.get_node("PostFX").visible = true
	check("the shaft brightens Echidna", on > off * 1.08, "luma %.3f in the beam vs %.3f without" % [on, off])
	await shot("presentation_shaft")


# ================================================================ brightness

func scenario_brightness() -> void:
	print("SCENARIO brightness: Dim, Normal and Bright, dark rooms, the unlit brazier")
	var settings = get_tree().root.get_node("Settings")
	await load_level(CHAPTER)
	var post = lvl.get_node("PostFX")
	var mat: ShaderMaterial = post.get_node("Screen").material
	var aura: PointLight2D = player.get_node("PlayerLight")
	var seen := {}
	for level in [settings.Brightness.DIM, settings.Brightness.NORMAL, settings.Brightness.BRIGHT]:
		settings.set_brightness(level)
		await frames(3)
		var ambient: Color = lvl.get_node("Darkness").color
		seen[level] = {
			"ambient": ambient.get_luminance(), "gloom": float(mat.get_shader_parameter("lantern_darkness")),
			"light": aura.energy * aura.texture_scale, "lift": float(mat.get_shader_parameter("shadow_lift")),
		}
	var dim: Dictionary = seen[settings.Brightness.DIM]
	var normal: Dictionary = seen[settings.Brightness.NORMAL]
	var bright: Dictionary = seen[settings.Brightness.BRIGHT]
	check("the ambient light rises from Dim to Normal to Bright",
		dim["ambient"] < normal["ambient"] and normal["ambient"] < bright["ambient"], str(seen))
	check("Dim is the original gloom (ambient about 0.2, lantern gloom 0.42)",
		absf(dim["ambient"] - Color(0.2, 0.18, 0.3).get_luminance()) < 0.04 and is_equal_approx(dim["gloom"], 0.42))
	check("the lantern's gloom and shadows ease as it gets brighter",
		dim["gloom"] > normal["gloom"] and normal["gloom"] > bright["gloom"] and dim["lift"] > normal["lift"] and normal["lift"] > bright["lift"])
	check("her own light grows with the setting", dim["light"] < normal["light"] and normal["light"] < bright["light"])
	settings.set_brightness(settings.Brightness.NORMAL)
	await frames(3)
	# Normal is clearly brighter than Dim on screen (same spot)
	await place(Vector2(380, FLOOR))
	await seconds(0.6)
	var lit := _mean_luma(await screen_image())
	settings.set_brightness(settings.Brightness.DIM)
	await seconds(0.3)
	var gloomy := _mean_luma(await screen_image())
	settings.set_brightness(settings.Brightness.NORMAL)
	await frames(3)
	check("Normal is at least 40% brighter than Dim on screen", lit > gloomy * 1.4, "mean luma %.3f vs %.3f" % [lit, gloomy])
	# Rooms where the dark is part of the puzzle keep a darker ambient
	var base: float = lvl.get_node("Darkness").color.get_luminance()
	await place(lvl.get_node("R4").entry_spawn)
	await seconds(2.2)
	var in_watcher: float = lvl.get_node("Darkness").color.get_luminance()
	check("the watcher room is darker than the rest", in_watcher < base * 0.7, "%.3f vs %.3f" % [in_watcher, base])
	await place(lvl.get_node("R1").entry_spawn)
	await seconds(2.2)
	check("and the ambient returns on leaving it", absf(lvl.get_node("Darkness").color.get_luminance() - base) < 0.01)
	# The old tutorial now has the same lantern as the chapters
	await load_level(TUTORIAL)
	await frames(10)
	check("the tutorial's Echidna carries a lantern light too", player.has_node("PlayerLight")
		and player.get_node("PlayerLight").energy > 1.0, "has=%s energy=%s brightness=%s" % [player.has_node("PlayerLight"), str(player.get_node_or_null("PlayerLight").energy if player.has_node("PlayerLight") else -1), str(get_tree().root.get_node("Settings").brightness)])
	# An unlit brazier is a visible pilot flame, not a dim smudge
	await load_level(CHAPTER)
	var brazier: Brazier = lvl.get_node("R3/Brazier")
	check("an unlit brazier glows (light energy at least 0.6)", not brazier.is_lit and brazier._light.energy >= 0.6,
		"energy %.2f" % brazier._light.energy)
	check("the unlit light is a warm gold, unlike the blue torches", brazier._light.color.r > brazier._light.color.b)
	brazier.ignite()
	await frames(4)
	check("lit, it is the blue fire again", brazier._light.color.b > brazier._light.color.r)


func _mean_luma(img: Image) -> float:
	var sum := 0.0
	var n := 0
	for y in range(0, img.get_height(), 4):
		for x in range(0, img.get_width(), 4):
			sum += img.get_pixel(x, y).get_luminance()
			n += 1
	return sum / float(maxi(n, 1))


# ================================================================ post pass

func scenario_post() -> void:
	print("SCENARIO lantern falloff and post pass")
	await load_level(CHAPTER)
	# A torch about 260 px away, still on screen
	await place(Vector2(540, FLOOR))
	await seconds(0.8)
	var post = lvl.get_node("PostFX")
	var mat: ShaderMaterial = post.get_node("Screen").material
	var uv: Vector2 = mat.get_shader_parameter("lantern_uv")
	var expect := world_to_screen(player.global_position + Vector2(0, -20)) / get_viewport().get_visible_rect().size
	check("the lantern follows Echidna", uv.distance_to(expect) < 0.01, "%s vs %s" % [uv, expect])
	# Isolate the lantern: no vignette, mist or grain while measuring
	var saved := {}
	for p in ["vignette", "fog_strength", "grain"]:
		saved[p] = mat.get_shader_parameter(p)
		mat.set_shader_parameter(p, 0.0)
	# It is the falloff itself that is measured, so use the original (Dim)
	# gloom and reach and no shadow lift, whatever the Brightness setting is
	var falloff := {"lantern_darkness": 0.42, "lantern_outer": 440.0, "shadow_lift": 1.0}
	for p in falloff:
		saved[p] = mat.get_shader_parameter(p)
		mat.set_shader_parameter(p, falloff[p])
	var on := await screen_image()
	post.visible = false
	var off := await screen_image()
	post.visible = true
	var size := Vector2(on.get_width(), on.get_height())
	var ratio := func(point: Vector2, half: Vector2) -> float:
		return region_luma(on, point, half) / maxf(region_luma(off, point, half), 0.0001)
	# Beside her the stone stays readable; far off it sinks into the gloom
	var near: float = ratio.call(world_to_screen(player.global_position + Vector2(-40, -60)), Vector2(8, 8))
	var far: float = ratio.call(world_to_screen(player.global_position + Vector2(-250, -60)), Vector2(8, 8))
	check("the gloom deepens away from the lantern", far < near * 0.9, "far %.2f vs near %.2f of unprocessed" % [far, near])
	var torch: Node2D = lvl.get_node("R1/Decor/Torch12_6")
	var torch_ratio: float = ratio.call(world_to_screen(torch.global_position + Vector2(0, -4)), Vector2(3, 3))
	check("a lit torch far away keeps its brightness", torch_ratio > near * 0.9 and torch_ratio > far,
		"torch %.2f, far stone %.2f (%.0f px away)" % [torch_ratio, far, torch.global_position.distance_to(player.global_position)])
	# The vignette on its own
	var corner := Vector2(10, size.y / 2.0)
	mat.set_shader_parameter("vignette", saved["vignette"])
	var with_vignette := region_luma(await screen_image(), corner, Vector2(6, 30))
	check("cinematic vignette darkens the edges", with_vignette < region_luma(on, corner, Vector2(6, 30)) * 0.9)
	for p in saved:
		mat.set_shader_parameter(p, saved[p])


# ================================================================ glows

func scenario_glow() -> void:
	print("SCENARIO glows and embers")
	await load_level(CHAPTER)
	var torch: Node2D = lvl.get_node("R1/Decor/Torch12_6")
	check("torches carry a pulsing halo", torch.has_node("Halo")
		and (torch.get_node("Halo").material as ShaderMaterial).shader.resource_path.ends_with("glow_pulse.gdshader"))
	check("torches shed embers", torch.has_node("Embers") and torch.get_node("Embers").emitting)
	var brazier = lvl.get_node("R3/Brazier")
	var embers: CPUParticles2D = brazier.get_node("Embers")
	check("an unlit brazier has no embers", not embers.emitting and not brazier.get_node("Halo").visible)
	brazier.set_powered(true)
	await frames(2)
	check("a lit brazier glows and sheds embers", embers.emitting and brazier.get_node("Halo").visible)
	await place(Vector2(3000, FLOOR))
	# (aimed along the open floor, whatever the real mouse is doing)
	get_tree().root.warp_mouse(world_to_screen(player.global_position + Vector2(220, -14)))
	await frames(2)
	player.shoot_fireball()
	await frames(2)
	var fireballs := get_tree().get_nodes_in_group("fireball")
	check("fireballs glow and trail embers", not fireballs.is_empty() and fireballs[0].has_node("Halo")
		and fireballs[0].has_node("Embers"))


# ================================================================ audio

func _bus(bus_name: String) -> int:
	return AudioServer.get_bus_index(bus_name)


## Loop seam check: a click is a jump at the join that is out of keeping with
## how fast the waveform is moving right around it.
func _wav_seam(path: String) -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(path)
	var samples := (bytes.size() - 44) / 2
	var at := func(i: int) -> float:
		return bytes.decode_s16(44 + posmod(i, samples) * 2) / 32768.0
	var jump := absf(at.call(0) - at.call(samples - 1))
	var local := 0.0
	for i in range(-64, 64):
		if i != -1:
			local = maxf(local, absf(at.call(i + 1) - at.call(i)))
	var rms := 0.0
	var count := 0
	for i in range(0, samples, 97):
		var v: float = at.call(i)
		rms += v * v
		count += 1
	return {"jump": jump, "typical": local, "rms": sqrt(rms / count), "seconds": samples / 22050.0}


func scenario_audio() -> void:
	print("SCENARIO adaptive audio")
	var sends_ok := AudioServer.get_bus_send(_bus("Music")) == &"Master" and AudioServer.get_bus_send(_bus("Ambient")) == &"Master" \
		and AudioServer.get_bus_send(_bus("SFX")) == &"Master"
	check("ambient, music and effects channels", _bus("Music") > 0 and _bus("Ambient") > 0 and _bus("SFX") > 0 and sends_ok)
	var reverb_ok := true
	for b in ["ReverbCorridor", "ReverbHall", "ReverbCavern"]:
		var i := _bus(b)
		reverb_ok = reverb_ok and i > 0 and AudioServer.get_bus_send(i) == &"SFX" and AudioServer.get_bus_effect(i, 0) is AudioEffectReverb
	check("three reverb buses feed the effects channel", reverb_ok)
	check("caverns add a distinct echo", AudioServer.get_bus_effect_count(_bus("ReverbCavern")) == 2
		and AudioServer.get_bus_effect(_bus("ReverbCavern"), 1) is AudioEffectDelay)

	var director := get_tree().root.get_node("AudioDirector")
	var layers: Dictionary = director.players
	check("drone, piano and combat layers loaded", layers.has(&"drone") and layers.has(&"piano") and layers.has(&"pulse"))
	var playing := layers.values().all(func(p): return p.playing)
	var loops := layers.values().all(func(p): return (p.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD)
	check("all layers loop and play together", playing and loops and director.ambience and director.ambience.playing)
	# The combat loop is half as long as the others, so compare phase in 16 s
	var positions := layers.values().map(func(p): return fposmod(p.get_playback_position(), 16.0))
	check("layers stay in step", positions.max() - positions.min() < 0.1, str(positions))
	for f in ["cave_drone", "piano_lament", "combat_pulse", "cave_ambience"]:
		var s := _wav_seam("res://assets/audio/music/%s.wav" % f)
		check("%s loops without a click" % f, s["jump"] <= s["typical"] * 1.5 + 0.002 and s["rms"] > 0.02,
			"seam %.4f, largest nearby step %.4f, rms %.3f, %.0f s" % [s["jump"], s["typical"], s["rms"], s["seconds"]])

	# Combat rooms: the music leans in, then settles when the fight is left behind
	await load_level(CHAPTER)
	check("exploring: no combat", not director.is_combat() and director.intensity < 0.05)
	await place(lvl.get_node("R4").entry_spawn)
	await seconds(3.0)
	var pulse_db: float = layers[&"pulse"].volume_db
	var cutoff: float = (AudioServer.get_bus_effect(_bus("Music"), 0) as AudioEffectLowPassFilter).cutoff_hz
	check("a combat room swells the music", director.intensity > 0.99 and pulse_db > -12.0 and cutoff > 8000.0,
		"intensity %.2f pulse %.1f dB cutoff %.0f Hz" % [director.intensity, pulse_db, cutoff])
	check("the drone intensifies and the piano steps back",
		layers[&"drone"].volume_db > -5.0 and layers[&"piano"].volume_db < -10.0)
	await place(lvl.get_node("R5").entry_spawn)
	await seconds(3.0)
	check("leaving the fight settles the music", director.intensity < 0.01 and layers[&"pulse"].volume_db < -50.0)

	# Reverb zones cover every room of the chapter
	var space: PhysicsDirectSpaceState2D = lvl.get_world_2d().direct_space_state
	var uncovered := []
	var cavern_ok := true
	for x in range(64, 11072, 64):
		var query := PhysicsPointQueryParameters2D.new()
		query.position = Vector2(x, 520)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		query.collision_mask = ReverbZone.AUDIO_LAYER
		var hits: Array = space.intersect_point(query)
		if hits.is_empty():
			uncovered.append(x)
	check("reverb zones cover every corridor and chamber", uncovered.is_empty(), str(uncovered))
	var r3_zone: Area2D = lvl.get_node("R3/Acoustics")
	check("tall chambers use the cavern reverb", r3_zone.audio_bus_override and r3_zone.audio_bus_name == &"ReverbCavern")
	# A footfall in a tall room really goes through the cavern bus
	await place(Vector2(3100, FLOOR))
	await frames(4)
	var cavern := _bus("ReverbCavern")
	var peak := -200.0
	Sfx.play("land", player.global_position, 0.0, 0.0)
	for i in 20:
		await get_tree().process_frame
		peak = maxf(peak, AudioServer.get_bus_peak_volume_left_db(cavern, 0))
	check("sounds inside a zone play through its reverb", peak > -60.0, "cavern bus peak %.1f dB" % peak)

	# The tutorial's slime arena is a combat zone
	await load_level(TUTORIAL)
	await place(Vector2(7500, FLOOR))
	await frames(4)
	check("the tutorial slime arena counts as combat", director.is_combat())
	await place(Vector2(5000, FLOOR))
	await frames(4)
	check("leaving the arena ends combat", not director.is_combat())

	var menu = lvl.get_node("PauseMenu")
	var labels := menu.find_children("*", "Label", true, false).map(func(l): return l.text)
	check("pause menu has music and ambience volumes", labels.has("Music volume") and labels.has("Ambience volume"))


# ================================================================ hazards and walls

func scenario_hazards() -> void:
	print("SCENARIO readable hazards and wall tiles")
	# Floor-standing wall tiles (pillars, arcades, doors) rest on the ground
	for path in [TUTORIAL, CHAPTER]:
		await load_level(path)
		var bad := WallTileAudit.find_misplaced(lvl.get_node("BackDecor"))
		check("no floating pillars or arcades in %s" % path.get_file(), bad.is_empty(), str(bad))
	# Spike tips glow through the dark, even well outside Echidna's lantern
	await load_level(TUTORIAL)
	var spikes = lvl.get_node("Hazards/Spikes2")
	check("spikes carry a danger glint", spikes._glint != null and spikes._glint.material is ShaderMaterial)
	# (to its right: 250 px to its left stands on the first spike)
	await place(Vector2(spikes.global_position.x + 250.0, FLOOR))
	await seconds(1.0)
	check("measuring from safe ground", not player.hazard_recovery.is_active() and player.current_health == 10)
	var lit: float = await _tip_luminance(spikes)
	await shot("hazard_spikes")
	spikes._glint.visible = false
	spikes._floor_glow.visible = false
	await frames(3)
	var bare: float = await _tip_luminance(spikes)
	spikes._glint.visible = true
	spikes._floor_glow.visible = true
	check("spike tips stand out 250 px from the lantern", lit >= 0.3 and lit > bare * 1.8,
		"tips %.2f with glint, %.2f without" % [lit, bare])
	# Retracting spikes flare while they rattle, before they rise
	var rising = lvl.get_node("Hazards/RetractingSpikes1")
	var flare := await wait_until(func():
		return rising._glint.material == SpikeHazard.glint_material(SpikeHazard.GLINT_WARNING), 6.0)
	check("rising spikes flare their glint during the warning", flare and rising.extension < 0.5)


## Brightest pixel luminance around a spike strip's tips in the rendered frame.
func _tip_luminance(spikes: Node2D) -> float:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_tree().root.get_texture().get_image()
	var xform: Transform2D = lvl.get_viewport().get_canvas_transform()
	var w: float = spikes.get_width()
	# Every pixel of the band where the tips are (the glint is a thin outline)
	var a := Vector2i((xform * (spikes.global_position + Vector2(-w / 2.0, -33.0))).round())
	var b := Vector2i((xform * (spikes.global_position + Vector2(w / 2.0, -18.0))).round())
	var best := 0.0
	for y in range(maxi(a.y, 0), mini(b.y, image.get_height())):
		for x in range(maxi(a.x, 0), mini(b.x, image.get_width())):
			best = maxf(best, image.get_pixel(x, y).get_luminance())
	return best


# ================================================================ screenshots

func scenario_look() -> void:
	print("SCENARIO presentation screenshots")
	await load_level(CHAPTER)
	# (Room 5's spot is between the rising spikes and the first piston)
	for spot in [["pres_r1", Vector2(1000, FLOOR)], ["pres_r3", Vector2(3150, FLOOR)], ["pres_r5", Vector2(6130, 274)],
			["pres_r6", Vector2(7640, FLOOR)], ["pres_r7", Vector2(9560, FLOOR)]]:
		await place(spot[1])
		await seconds(1.0)
		await shot(spot[0])
	await place(Vector2(700, FLOOR))
	Input.action_press("crouch")
	await seconds(2.6)
	await shot("pres_charge")
	Input.action_release("crouch")
	await seconds(1.0)
	check("screenshots taken", true)
