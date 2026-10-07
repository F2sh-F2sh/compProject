extends Node

## Gameplay tests for the tutorial level. Run through tests/run_tests.gd.

const LEVEL := "res://scenes/tutorial_level.tscn"
const DT := 1.0 / 60.0
const SHOTS := "user://test_shots/"
# PistonTrap.Phase values (kept numeric so this file doesn't depend on class load order)
const PHASE_RAISED := 0
const PHASE_WARNING := 1
const PHASE_SLAM := 2
const PHASE_LOWERED := 3

var lvl: Node
var player: CharacterBody2D
var passed := 0
var failed := 0
var monitor_camera := false
var camera_worst := 0.0
var camera_worst_at := ""
var recoveries := 0
var only := ""


func run_suite(filter: String) -> void:
	only = filter
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOTS))
	await get_tree().process_frame
	if only == "" or only == "play":
		await scenario_playthrough()
	if only == "" or only == "spike":
		await scenario_nonlethal_spike()
	if only == "" or only == "lethal":
		await scenario_lethal_spike_and_restart()
	if only == "" or only == "piston":
		await scenario_piston()
	if only == "" or only == "fallback":
		await scenario_unreached_checkpoint()
	if only == "" or only == "retract":
		await scenario_retracting()
	if only == "" or only == "camera":
		await scenario_camera_aspects()
	if only == "" or only == "design":
		await scenario_mechanics_required()
	if only == "" or only == "gauntlet":
		await scenario_gauntlet()
	if only == "" or only == "slime":
		await scenario_slimes()
	if only == "" or only == "echo":
		await scenario_echo()
	if only == "" or only == "legacy":
		await scenario_legacy_level()
	if only == "" or only == "feel":
		await scenario_feel()
	print("tutorial suite: passed=%d failed=%d" % [passed, failed])


# ------------------------------------------------------------ helpers

func check(label: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
		print("  PASS ", label, "  ", detail)
	else:
		failed += 1
		print("  FAIL ", label, "  ", detail)


func release_all() -> void:
	for a in ["move_left", "move_right", "jump", "crouch", "sprint", "shoot", "heal", "reload"]:
		Input.action_release(a)


func load_level() -> void:
	release_all()
	get_tree().paused = false
	# Every scenario starts at the beginning, not at a saved lesson
	get_tree().root.get_node("GameState").clear_checkpoint(LEVEL)
	if is_instance_valid(get_tree().current_scene):
		get_tree().current_scene.queue_free()
	await get_tree().process_frame
	lvl = load(LEVEL).instantiate()
	get_tree().root.add_child(lvl)
	get_tree().current_scene = lvl
	await get_tree().process_frame
	await get_tree().physics_frame
	player = lvl.get_node("Player")
	recoveries = 0
	player.hazard_recovery.recovery_started.connect(func(): recoveries += 1)
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


func place(x: float) -> void:
	player.teleport_to(Vector2(x, 530))
	await frames(8)


## Places the player on a raised ledge (top y 502) instead of the floor.
func place_on_ledge(x: float) -> void:
	player.teleport_to(Vector2(x, 500))
	await frames(8)


func move_until_x(x: float, sprint := false, timeout := 12.0) -> bool:
	Input.action_press("move_right")
	if sprint:
		Input.action_press("sprint")
	var ok := await wait_until(func(): return player.global_position.x >= x, timeout)
	return ok


func approach_and_jump(x: float, sprint := false) -> bool:
	var reached := await move_until_x(x, sprint)
	var jumped := await tap_jump()
	return reached and jumped


func tap_action(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(1)


## Points the real mouse at a world position and presses the shoot action.
func aim_and_shoot(world_pos: Vector2) -> void:
	if DisplayServer.get_name() == "headless":
		await preload("res://tests/background_aim.gd").fire(player, world_pos)
		return
	var screen_pos: Vector2 = lvl.get_viewport().get_canvas_transform() * world_pos
	var motion := InputEventMouseMotion.new()
	motion.position = screen_pos
	motion.global_position = screen_pos
	get_tree().root.push_input(motion, true)
	await frames(2)
	await tap_action("shoot")


func fight_slimes(slimes: Array, timeout: float) -> bool:
	var t := 0.0
	while t < timeout:
		var alive := slimes.filter(func(s): return is_instance_valid(s) and not s.is_dead)
		if alive.is_empty():
			return true
		var target: Node2D = alive[0]
		for s in alive:
			if s.global_position.distance_to(player.global_position) < target.global_position.distance_to(player.global_position):
				target = s
		# Back away if a slime gets too close, otherwise stand and shoot
		if target.global_position.distance_to(player.global_position) < 50.0:
			Input.action_press("move_left")
			await frames(8)
			Input.action_release("move_left")
		await aim_and_shoot(target.global_position + Vector2(0, -6))
		await frames(16)
		t += 0.35
	return false


func wait_phase_start(piston, target) -> void:
	await wait_until(func(): return piston.phase != target, 6.0)
	await wait_until(func(): return piston.phase == target, 6.0)


func tap_jump() -> bool:
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	var left_ground := await wait_until(func(): return not player.is_on_floor(), 0.3)
	var landed := await wait_until(func(): return player.is_on_floor(), 2.0)
	return left_ground and landed


func _lesson_card_showing() -> bool:
	return lvl.get_children().any(func(n): return n is TitleCard)


func sfx() -> Node:
	return get_tree().root.get_node("Sfx")


func _count_sounds(prefix: String) -> int:
	var n := 0
	for key in sfx().played:
		if String(key).begins_with(prefix):
			n += int(sfx().played[key])
	return n


## Highest rise (px) of the jump now starting, measured until she lands.
func _measure_rise(floor_y: float) -> float:
	var top := floor_y
	var t := 0.0
	await wait_until(func(): return not player.is_on_floor(), 0.3)
	while not player.is_on_floor() and t < 3.0:
		top = minf(top, player.global_position.y)
		await get_tree().physics_frame
		t += DT
	return floor_y - top


func shot(file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SHOTS + file_name + ".png"))


func cam_rect() -> Rect2:
	var cam: Camera2D = player.get_node("Camera2D")
	var size := get_tree().root.get_visible_rect().size / cam.zoom
	var center := cam.get_screen_center_position()
	return Rect2(center - size / 2.0, size)


func _physics_process(_delta: float) -> void:
	if monitor_camera and is_instance_valid(player) and player.is_inside_tree():
		var cam = player.get_node("Camera2D")
		var r := cam_rect()
		var b: Rect2 = cam.bounds
		var over := maxf(maxf(b.position.x - r.position.x, r.end.x - b.end.x),
			maxf(b.position.y - r.position.y, r.end.y - b.end.y))
		if over > camera_worst:
			camera_worst = over
			camera_worst_at = "player=%s view=%s" % [player.global_position.round(), r]


# ------------------------------------------------------------ scenarios

func scenario_playthrough() -> void:
	print("SCENARIO full playthrough")
	await load_level()
	monitor_camera = true
	camera_worst = 0.0
	var start_health: int = player.current_health
	var hazards := lvl.get_node("Hazards")

	await shot("play_00_start")
	check("the tutorial opens with its first lesson card", _lesson_card_showing())
	check("hop onto first ledge", await approach_and_jump(1300))
	check("entering the next lesson shows its card and saves it",
		_lesson_card_showing() and get_tree().root.get_node("GameState").get_checkpoint_for(LEVEL) == "lesson.2")
	check("jump up to walkway", await approach_and_jump(1490),
		"y=%.0f" % player.global_position.y)
	await shot("play_01_walkway")
	check("walking gap jump", await approach_and_jump(1718),
		"landed y=%.0f x=%.0f" % [player.global_position.y, player.global_position.x])
	check("landed on walkway 2", player.global_position.y < 520.0, "y=%.0f" % player.global_position.y)
	check("sprint gap jump", await approach_and_jump(2030, true),
		"landed x=%.0f y=%.0f" % [player.global_position.x, player.global_position.y])
	check("landed on walkway 3", player.global_position.y < 520.0 and player.global_position.x > 2140.0,
		"x=%.0f y=%.0f" % [player.global_position.x, player.global_position.y])
	Input.action_release("sprint")

	# Charged jump up the plateau wall: crouch to gather it, then jump
	await move_until_x(2470)
	await frames(30)
	Input.action_release("move_right")
	await frames(10)
	Input.action_press("crouch")
	await seconds(1.4)
	await shot("play_02_charging")
	await seconds(1.2)
	Input.action_press("move_right")
	await tap_action("jump")
	Input.action_release("crouch")
	await wait_until(func(): return not player.is_on_floor(), 0.3)
	await wait_until(func(): return player.is_on_floor(), 2.5)
	check("charged jump reaches plateau", player.global_position.y < 450.0,
		"x=%.0f y=%.0f" % [player.global_position.x, player.global_position.y])

	# A tapped jump must NOT reach the plateau (so the charge is really needed)
	# is covered by the geometry: wall is 96 px, base jump apex is ~62 px.

	check("walk-jump over single spike", await approach_and_jump(2935))
	check("checkpoint A lit on the way", lvl.get_node("Checkpoints/CheckpointA").is_active)
	check("sprint-jump over wide spikes", await approach_and_jump(3160, true),
		"x=%.0f" % player.global_position.x)
	Input.action_release("sprint")

	# Retracting spikes: wait at checkpoint C for them to drop, then sprint across
	await move_until_x(3500)
	Input.action_release("move_right")
	var r1 = hazards.get_node("RetractingSpikes1")
	await wait_until(func():
		var t := fposmod(r1._elapsed + r1.start_phase * r1.get_cycle_length(), r1.get_cycle_length())
		return r1.is_lowered() and t < 0.2, 6.0)
	await shot("play_03_retract_lowered")
	check("crossed retracting spikes", await move_until_x(3720, true))
	Input.action_release("sprint")

	# Pistons: wait for each to finish retracting, then sprint beneath it
	var p1 = hazards.get_node("Piston1")
	var p2 = hazards.get_node("Piston2")
	var p3 = hazards.get_node("Piston3")
	await move_until_x(3900)
	Input.action_release("move_right")
	await wait_until(func(): return p1.phase == PHASE_SLAM, 6.0)
	await wait_until(func(): return p1.phase == PHASE_LOWERED, 2.0)
	await shot("play_04_piston_slam")
	await wait_until(func(): return p1.phase == PHASE_RAISED, 6.0)
	check("passed under piston 1", await move_until_x(4096, true))
	Input.action_release("move_right")
	Input.action_release("sprint")
	await wait_phase_start(p2, PHASE_RAISED)
	check("passed under piston 2", await move_until_x(4300, true))
	Input.action_release("sprint")

	# Combined section
	check("walk-jump combined spikes", await approach_and_jump(4535))
	await move_until_x(4660)
	Input.action_release("move_right")
	await wait_phase_start(p3, PHASE_RAISED)
	check("passed under piston 3", await move_until_x(4900, true))
	Input.action_release("sprint")
	check("sprint-jump final spikes", await approach_and_jump(5010, true),
		"x=%.0f" % player.global_position.x)
	Input.action_release("sprint")

	check("no damage taken through the hazard course", player.current_health == start_health,
		"health=%d" % player.current_health)
	check("no hazard resets on the intended path", recoveries == 0, "resets=%d" % recoveries)

	# Fireball gauntlet: stop short of the pistons, shoot the rune switch
	var switch = lvl.get_node("Gauntlet/RuneSwitch")
	await move_until_x(5480)
	Input.action_release("move_right")
	await frames(20)
	await shot("play_06_gauntlet")
	await aim_and_shoot(switch.global_position)
	var hit := await wait_until(func(): return switch.is_active, 2.0)
	check("fireball hits the rune switch", hit)
	await frames(10)
	await shot("play_07_switch_hit")
	var gauntlet := lvl.get_node("Gauntlet").get_children().filter(func(n): return n.has_method("get_head_bottom"))
	var all_raised := await wait_until(func():
		return gauntlet.all(func(p): return p.progress <= 0.0 and not p.is_dangerous()), 3.0)
	check("switch stops every gauntlet piston", all_raised)
	var before_gauntlet: int = player.current_health
	check("crossed the stopped gauntlet", await move_until_x(5800, true))
	Input.action_release("sprint")
	check("no damage in the stopped gauntlet", player.current_health == before_gauntlet)

	# Slime arena: burn both slimes
	await move_until_x(6060)
	Input.action_release("move_right")
	var slimes := lvl.get_node("Enemies").get_children()
	var killed := await fight_slimes(slimes, 25.0)
	check("both slimes defeated with fireballs", killed)
	await shot("play_08_arena")

	# Echo lab: record on the plate so the Echo holds the gate open
	var plate = lvl.get_node("EchoLab/Plate")
	var gate = lvl.get_node("EchoLab/Gate")
	var recorder = player.get_node("EchoRecorder")
	await move_until_x(plate.global_position.x - 2)
	Input.action_release("move_right")
	await frames(20)
	check("standing on the plate opens the gate", plate.is_pressed)
	await tap_action("echo")
	check("recording started", recorder.is_recording)
	await seconds(0.8)
	await shot("play_09_recording")
	await tap_action("echo")
	await frames(40)
	check("an Echo was created", recorder.echoes.size() == 1)
	check("temporal debt lowers max mana", player.get_mana_cap() == player.MAX_MANA - recorder.mana_debt_per_echo,
		"cap=%d" % player.get_mana_cap())
	await shot("play_10_echo")
	check("gate open behind the Echo", await move_until_x(gate.global_position.x + 60, true),
		"x=%.0f gate open=%.2f" % [player.global_position.x, gate.open_amount])
	Input.action_release("sprint")
	check("plate still held by the Echo", plate.is_pressed)

	# Exit door
	var exit_x: float = lvl.get_node("LevelExit").global_position.x
	await move_until_x(exit_x - 40)
	var exit = lvl.get_node("LevelExit")
	await wait_until(func(): return exit._triggered, 3.0)
	check("exit door triggers", exit._triggered)
	check("controls locked at exit", player.controls_locked)
	var state := get_tree().root.get_node("GameState")
	check("finishing marks the tutorial done and forgets its lesson", state.has_flag("tutorial.done")
		and state.get_checkpoint_for(LEVEL) == "")
	Input.action_release("move_right")
	await seconds(1.2)
	await shot("play_05_exit")
	monitor_camera = false
	check("camera never showed outside the level", camera_worst <= 0.5,
		"worst overshoot=%.2f %s" % [camera_worst, camera_worst_at])
	var changed := await wait_until(func(): return get_tree().current_scene != lvl and get_tree().current_scene != null, 4.0)
	check("exit leads into chapter 1", changed and get_tree().current_scene.scene_file_path.ends_with("chapter/chapter_1.tscn"),
		str(get_tree().current_scene.scene_file_path if get_tree().current_scene else "none"))


func scenario_nonlethal_spike() -> void:
	print("SCENARIO non-lethal spike hit")
	await load_level()
	var spikes = lvl.get_node("Hazards/Spikes1")
	var cp_a = lvl.get_node("Checkpoints/CheckpointA")
	await place(2780)
	await move_until_x(2900)
	check("checkpoint A activated by walking through it", cp_a.is_active)
	# Hold jump so a charge is in progress when the hit lands
	Input.action_press("jump")
	var hit := await wait_until(func(): return player.current_health < 10, 3.0)
	check("spike hit applies damage", hit and player.current_health == 8, "health=%d" % player.current_health)
	check("controls locked during recovery", player.controls_locked)
	check("no death screen for a non-lethal hit", not lvl.get_node("DeathUI/DeathScreen").visible and not get_tree().paused)
	await frames(8)
	await shot("spike_01_fading")
	var done := await wait_until(func(): return not player.hazard_recovery.is_active(), 2.0)
	Input.action_release("move_right")
	await frames(10)
	var respawn: Vector2 = cp_a.get_respawn_position()
	check("recovery finished and control restored", done and not player.controls_locked)
	check("returned to checkpoint A", player.global_position.distance_to(respawn) < 6.0,
		"pos=%s expected=%s" % [player.global_position.round(), respawn])
	check("respawn is outside the spike hitbox", not spikes.get_hazard_rect().has_point(player.global_position))
	check("health kept, not healed", player.current_health == 8)
	check("exactly one reset for one contact", recoveries == 1, "resets=%d" % recoveries)
	check("stale jump charge cleared", not player.charging_jump and player.charge_time == 0.0)
	check("invulnerable right after recovery", player.is_invulnerable(),
		"remaining=%.2f" % player.invulnerable_time)
	check("HUD still visible", lvl.get_node("HUD").visible)
	await shot("spike_02_back_at_checkpoint")
	Input.action_release("jump")
	await seconds(1.5)
	check("no further damage while standing at the checkpoint", player.current_health == 8)
	check("invulnerability wears off", not player.is_invulnerable())


func scenario_lethal_spike_and_restart() -> void:
	print("SCENARIO lethal spike hit and restart")
	await load_level()
	var death = lvl.get_node("DeathUI/DeathScreen")
	await place(2780)
	player.current_health = 2
	player.update_health_ui()
	await move_until_x(2900)
	var died := await wait_until(func(): return player.is_dead, 3.0)
	check("lethal spike hit kills instead of resetting", died and recoveries == 0, "resets=%d" % recoveries)
	check("death screen shown, game paused", death.visible and get_tree().paused)
	check("gameplay HUD hidden", not lvl.get_node("HUD").visible and not lvl.get_node("AmmoUI").visible)
	Input.action_release("move_right")
	await seconds(0.8)
	await shot("death_01_fading")

	# A jump press held from before the prompt appears must not skip the screen
	var press := InputEventKey.new()
	press.physical_keycode = KEY_SPACE
	press.keycode = KEY_SPACE
	press.pressed = true
	Input.parse_input_event(press)
	await seconds(2.8)
	check("prompt active", death.can_restart)
	await shot("death_02_full")
	var echo := press.duplicate()
	echo.echo = true
	for i in 5:
		Input.parse_input_event(echo)
		await frames(3)
	check("held key does not restart", get_tree().current_scene == lvl and get_tree().paused)
	var release := press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await frames(3)
	Input.parse_input_event(press.duplicate())
	var restarted := await wait_until(func(): return get_tree().current_scene != lvl and get_tree().current_scene != null, 2.0)
	await frames(10)
	Input.parse_input_event(release.duplicate())
	check("fresh press restarts the level", restarted)
	if restarted:
		lvl = get_tree().current_scene
		player = lvl.get_node("Player")
		check("restart restores full health", player.current_health == player.MAX_HEALTH)
		check("restart unpauses and revives", not get_tree().paused and not player.is_dead and not player.controls_locked)
		check("restart restores HUD", lvl.get_node("HUD").visible and lvl.get_node("AmmoUI").visible)
		var lesson = lvl.get_node("Lessons/Lesson5")
		check("restart begins the current lesson, not the whole tutorial",
			player.global_position.distance_to(lesson.get_spawn_position()) < 8.0,
			"x=%.0f (lesson starts at %.0f)" % [player.global_position.x, lesson.get_spawn_position().x])
		check("camera active after restart", get_tree().root.get_camera_2d() == player.get_node("Camera2D"))


func scenario_piston() -> void:
	print("SCENARIO piston hit")
	await load_level()
	var p1 = lvl.get_node("Hazards/Piston1")
	await place(3930)
	await wait_until(func(): return p1.phase == PHASE_WARNING, 6.0)
	# Walk right under the head as it slams
	Input.action_press("move_right")
	await wait_until(func(): return player.global_position.x >= 3985, 2.0)
	Input.action_release("move_right")
	var start_x := player.global_position.x
	var hit := await wait_until(func(): return player.current_health < 10, 2.0)
	check("piston hit applies damage", hit and player.current_health == 8, "health=%d" % player.current_health)
	check("a crush fades the player back, like a spike hit", recoveries == 1 and player.controls_locked,
		"resets=%d" % recoveries)
	await wait_until(func(): return not player.hazard_recovery.is_active(), 2.0)
	await frames(10)
	var clear_x: float = p1.get_hazard_rect().position.x - 20.0
	check("returned to safe ground just before the piston", player.global_position.x < clear_x
		and player.global_position.x > 3700.0 and player.is_on_floor(),
		"x=%.0f (piston %.0f, was %.0f)" % [player.global_position.x, p1.global_position.x, start_x])
	await seconds(2.0)
	check("one piston hit per contact", player.current_health == 8, "health=%d" % player.current_health)

	# Hitbox and art always agree
	var ok := true
	var shape_rect: Rect2
	for i in 240:
		await get_tree().physics_frame
		var cs: CollisionShape2D = p1._hitbox.get_child(0)
		var r: RectangleShape2D = cs.shape
		var bottom: float = p1._hitbox.global_position.y + r.size.y / 2.0
		var drawn: float = p1.global_position.y + p1.get_head_bottom()
		if absf(bottom - drawn) > 0.5:
			ok = false
			shape_rect = Rect2(bottom, drawn, 0, 0)
	check("piston hitbox matches drawn head over a full cycle", ok, str(shape_rect))

	# Lethal piston hit goes to the full death screen
	await load_level()
	p1 = lvl.get_node("Hazards/Piston1")
	player.current_health = 2
	await place(4000)
	var died := await wait_until(func(): return player.is_dead, 5.0)
	check("lethal piston hit shows the death screen", died and lvl.get_node("DeathUI/DeathScreen").visible)
	get_tree().paused = false


func scenario_unreached_checkpoint() -> void:
	print("SCENARIO spike hit before its checkpoint was reached")
	await load_level()
	var cp_a = lvl.get_node("Checkpoints/CheckpointA")
	await place(3050)
	await frames(20)
	Input.action_press("move_left")
	var hit := await wait_until(func(): return player.current_health < 10, 3.0)
	Input.action_release("move_left")
	await wait_until(func(): return not player.hazard_recovery.is_active(), 2.0)
	await frames(10)
	check("hit registered", hit)
	check("unreached checkpoint A stays unlit", not cp_a.is_active)
	check("fell back to last safe ground, not checkpoint A",
		player.global_position.x > 3010.0 and player.global_position.distance_to(cp_a.get_respawn_position()) > 100.0,
		"pos=%s" % player.global_position.round())
	var spikes = lvl.get_node("Hazards/Spikes1")
	check("fallback spot is outside the spikes", not spikes.get_hazard_rect().grow(4).has_point(player.global_position))


func scenario_retracting() -> void:
	print("SCENARIO retracting spikes")
	await load_level()
	var r1 = lvl.get_node("Hazards/RetractingSpikes1")
	var cp_c = lvl.get_node("Checkpoints/CheckpointC")
	var mismatch := 0
	for i in 300:
		await get_tree().physics_frame
		var should_hurt: bool = r1.extension >= r1.danger_extension
		var collider: CollisionShape2D = r1._collider
		if not should_hurt and not collider.disabled and i > 2:
			mismatch += 1
	check("retracted spikes have no active hitbox", mismatch == 0, "mismatched frames=%d" % mismatch)

	await place(3380)
	await move_until_x(3440)
	Input.action_release("move_right")
	check("checkpoint C lit", cp_c.is_active)
	await wait_until(func():
		var t := fposmod(r1._elapsed + r1.start_phase * r1.get_cycle_length(), r1.get_cycle_length())
		return r1.is_lowered() and t < 0.2, 6.0)
	await move_until_x(r1.global_position.x - 4)
	Input.action_release("move_right")
	check("standing on lowered spikes is safe", player.current_health == 10)
	var hit := await wait_until(func(): return player.current_health < 10, 4.0)
	await shot("retract_01_hit")
	check("rising spikes hurt", hit)
	await wait_until(func(): return not player.hazard_recovery.is_active(), 2.0)
	await frames(10)
	check("rising spikes return player to checkpoint C",
		player.global_position.distance_to(cp_c.get_respawn_position()) < 6.0, "pos=%s" % player.global_position.round())


func scenario_mechanics_required() -> void:
	print("SCENARIO each obstacle needs the mechanic it teaches")
	await load_level()
	# The sprint gap is a pit: a missed jump fades you back to the ledge
	await place_on_ledge(1950)
	await move_until_x(2030)
	await tap_action("jump")
	var fell := await wait_until(func(): return recoveries == 1, 2.5)
	Input.action_release("move_right")
	await wait_until(func(): return not player.hazard_recovery.is_active(), 2.0)
	await frames(10)
	check("walking jump falls into the sprint-gap pit", fell, "x=%.0f y=%.0f" % [player.global_position.x, player.global_position.y])
	check("the pit returns you to the ledge unhurt", player.global_position.x < 2048.0 and player.global_position.y < 520.0
		and player.current_health == 10, "x=%.0f y=%.0f hp=%d" % [player.global_position.x, player.global_position.y, player.current_health])
	# Even a fully charged jump without sprinting falls short
	await place_on_ledge(2036)
	Input.action_press("crouch")
	await seconds(2.6)
	Input.action_press("move_right")
	await tap_action("jump")
	Input.action_release("crouch")
	await wait_until(func(): return not player.is_on_floor(), 0.3)
	await wait_until(func(): return player.is_on_floor() or player.hazard_recovery.is_active(), 2.5)
	check("a charged jump without sprinting can't clear the sprint gap", recoveries == 2 or player.global_position.x < 2176.0,
		"x=%.0f resets=%d" % [player.global_position.x, recoveries])
	release_all()
	await wait_until(func(): return not player.hazard_recovery.is_active(), 2.0)
	# A sprint jump from standstill at the edge clears it
	await place_on_ledge(2030)
	Input.action_press("move_right")
	Input.action_press("sprint")
	await tap_action("jump")
	await wait_until(func(): return not player.is_on_floor(), 0.3)
	await wait_until(func(): return player.is_on_floor() or player.hazard_recovery.is_active(), 2.5)
	check("a sprint jump clears the gap", player.global_position.x > 2176.0 and player.global_position.y < 520.0,
		"x=%.0f y=%.0f" % [player.global_position.x, player.global_position.y])
	release_all()

	await place(2440)
	await move_until_x(2470)
	await frames(20)
	await tap_jump()
	await frames(30)
	check("a tapped jump cannot reach the plateau", player.global_position.y > 520.0,
		"y=%.0f" % player.global_position.y)
	release_all()

	await place(3110)
	await frames(10)
	var before: int = player.current_health
	await approach_and_jump(3160)
	await frames(30)
	check("walking jump cannot clear the wide spikes", player.current_health < before)


func scenario_gauntlet() -> void:
	print("SCENARIO fireball gauntlet")
	await load_level()
	var pistons := lvl.get_node("Gauntlet").get_children().filter(func(n): return n.has_method("get_head_bottom"))
	var cycle: float = pistons[0].get_cycle_length()
	var runs := 16
	var survived := 0
	var detail := ""
	for i in runs:
		var jump := i % 2 == 1
		player.current_health = 10
		player.invulnerable_time = 0.0
		release_all()
		await place(5470)
		# Stagger the start across one full cycle
		await seconds(cycle * i / runs + 0.02)
		player.invulnerable_time = 0.0
		var hp: int = player.current_health
		Input.action_press("move_right")
		Input.action_press("sprint")
		var t := 0.0
		var jumped := false
		while player.global_position.x < 5720 and player.current_health == hp and t < 3.0:
			if jump and not jumped and player.global_position.x > 5495:
				Input.action_press("jump")
				await frames(2)
				Input.action_release("jump")
				jumped = true
			await get_tree().physics_frame
			t += DT
		release_all()
		# A crush fades back to safety; let it finish before the next run
		await wait_until(func(): return not player.hazard_recovery.is_active(), 2.0)
		if player.current_health == hp and player.global_position.x >= 5720:
			survived += 1
			detail += " run%d(jump=%s)" % [i, jump]
	check("running pistons cannot be crossed (%d attempts, walking/jumping)" % runs, survived == 0,
		"got through:%s" % detail)

	# Now shoot the switch and cross safely
	player.current_health = 10
	player.invulnerable_time = 0.0
	await place(5470)
	var switch = lvl.get_node("Gauntlet/RuneSwitch")
	var screen_pos: Vector2 = lvl.get_viewport().get_canvas_transform() * switch.global_position
	check("rune switch is on screen from the shooting spot",
		Rect2(Vector2.ZERO, get_tree().root.get_visible_rect().size).has_point(screen_pos), str(screen_pos))
	check("rune switch is within fireball range",
		player.global_position.distance_to(switch.global_position) < 380.0,
		"%.0f px" % player.global_position.distance_to(switch.global_position))
	await aim_and_shoot(switch.global_position)
	check("switch activated by fireball", await wait_until(func(): return switch.is_active, 2.0))
	await wait_until(func(): return pistons.all(func(p): return p.progress <= 0.0), 3.0)
	check("pistons retract and stay stopped", pistons.all(func(p): return not p.running and not p.is_dangerous()))
	var hp_before: int = player.current_health
	await move_until_x(5800, true)
	release_all()
	check("gauntlet crossable once stopped", player.current_health == hp_before)
	await seconds(3.0)
	check("pistons stay stopped", pistons.all(func(p): return p.phase == PHASE_RAISED))


func scenario_slimes() -> void:
	print("SCENARIO slimes")
	await load_level()
	var slime = lvl.get_node("Enemies/Slime1")
	await place(slime.global_position.x - 70)
	var hp: int = player.current_health
	var hurt := await wait_until(func(): return player.current_health < hp, 8.0)
	check("slime contact hurts the player", hurt, "health=%d" % player.current_health)
	check("slime knocks the player back", absf(player.velocity.x) > 50.0 or player.knockback_time > 0.0 or not player.is_on_floor(),
		"vx=%.0f" % player.velocity.x)
	check("slime hit does not use spike recovery", recoveries == 0)
	await seconds(1.0)
	var home: float = slime.home_x
	await place(slime.global_position.x - 150)
	# Keep the drop available to inspect even when simulated shots kill at
	# point-blank range; wounded-player attraction is checked separately below.
	player.current_health = player.MAX_HEALTH
	player.invulnerable_time = 20.0
	var killed := await fight_slimes([slime], 15.0)
	check("fireballs kill a slime", killed)
	# (Checked at once: a hurt Echidna nearby would already be drawing it in)
	var orbs := get_tree().get_nodes_in_group("pickup")
	check("a defeated slime leaves a health orb", orbs.size() == 1)
	player.current_health = player.MAX_HEALTH
	await seconds(1.0)
	check("dead slime is removed", not is_instance_valid(slime))
	check("at full health she leaves the orb for later", orbs.size() == 1 and is_instance_valid(orbs[0]))
	if orbs.size() == 1 and is_instance_valid(orbs[0]):
		var orb: Node2D = orbs[0]
		player.current_health = 7
		player.update_health_ui()
		await place(orb.global_position.x - 30.0)
		var healed := await wait_until(func(): return player.current_health == 8, 3.0)
		await frames(1) # queue_free is committed at the end of the healing frame.
		check("the orb drifts to a hurt Echidna and heals her", healed and not is_instance_valid(orb),
			"hp=%d" % player.current_health)

	# Leash: an idle slime stays near home
	await load_level()
	var other = lvl.get_node("Enemies/Slime2")
	await place(1000)
	var max_away := 0.0
	for i in 480:
		await get_tree().physics_frame
		max_away = maxf(max_away, absf(other.global_position.x - other.home_x))
	check("wandering slime stays in its arena", max_away < other.home_radius + 90.0, "max %.0f px from home" % max_away)


func scenario_echo() -> void:
	print("SCENARIO echo system")
	await load_level()
	var plate = lvl.get_node("EchoLab/Plate")
	var gate = lvl.get_node("EchoLab/Gate")
	var recorder = player.get_node("EchoRecorder")

	# Alone: the gate shuts before you can reach it
	await place(plate.global_position.x - 30)
	await move_until_x(plate.global_position.x)
	Input.action_release("move_right")
	await seconds(1.2)
	check("gate opens while the player stands on the plate", gate.open_amount > 0.95)
	await move_until_x(gate.global_position.x + 60, true, 3.0)
	release_all()
	await seconds(0.3)
	check("gate closes before the player can reach it alone", player.global_position.x < gate.global_position.x,
		"x=%.0f gate=%.0f" % [player.global_position.x, gate.global_position.x])
	check("gate never closed on the player", player.current_health == 10)

	# With an Echo holding the plate
	await place(plate.global_position.x - 60)
	await tap_action("echo")
	check("HUD shows recording", lvl.get_node("HUD/HUDRoot/StatusBar").echo_recording)
	await move_until_x(plate.global_position.x)
	var secs: float = lvl.get_node("HUD/HUDRoot/StatusBar").echo_seconds
	check("the HUD counts down the seconds left to record", secs > 0.0 and secs < 7.95, "%.1f s" % secs)
	Input.action_release("move_right")
	await seconds(1.0)
	await tap_action("echo")
	await frames(5)
	check("recording stops and spawns an Echo", not recorder.is_recording and recorder.echoes.size() == 1)
	var echo = recorder.echoes[0]
	check("Echo starts where the recording began", echo.global_position.x < plate.global_position.x - 40.0,
		"echo x=%.0f" % echo.global_position.x)
	await seconds(1.6)
	check("Echo replays the walk onto the plate and holds it", plate.is_pressed and echo.is_finished(),
		"echo x=%.0f" % echo.global_position.x)
	await move_until_x(gate.global_position.x + 60, true, 4.0)
	release_all()
	check("player passes the gate thanks to the Echo", player.global_position.x > gate.global_position.x + 20)
	check("mana cap reduced by one Echo", player.get_mana_cap() == 90, "cap=%d" % player.get_mana_cap())
	check("HUD shows the debt", lvl.get_node("HUD/HUDRoot/StatusBar").mp_debt == 10)
	await shot("echo_01_passed")

	# More Echoes: capped at max_echoes; the oldest fades and its debt is returned
	for i in 2:
		await tap_action("echo")
		await seconds(0.5)
		await tap_action("echo")
		await frames(5)
	await seconds(0.7)
	check("Echo count is capped", recorder.echoes.size() == recorder.max_echoes, "count=%d" % recorder.echoes.size())
	check("debt tracks living Echoes", player.get_mana_cap() == 100 - recorder.max_echoes * 10, "cap=%d" % player.get_mana_cap())
	check("the replaced Echo faded away", not is_instance_valid(echo))
	check("each living Echo wears its own colour", recorder.echoes.size() == 2
		and recorder.echoes[0].tint != recorder.echoes[1].tint)
	# Holding the echo key lets every Echo fade and returns their mana
	Input.action_press("echo")
	await seconds(0.8)
	Input.action_release("echo")
	await seconds(0.7)
	check("holding the echo key lets every Echo fade", recorder.echoes.is_empty() and not recorder.is_recording
		and player.get_mana_cap() == 100, "echoes=%d cap=%d" % [recorder.echoes.size(), player.get_mana_cap()])

	# Recorded spells are recast by the Echo
	recorder.clear_echoes()
	await seconds(0.7)
	check("clearing Echoes restores max mana", player.get_mana_cap() == 100)
	await place(6200)
	await tap_action("echo")
	await frames(10)
	await aim_and_shoot(player.global_position + Vector2(200, -12))
	await frames(10)
	await tap_action("echo")
	var existing := get_tree().get_nodes_in_group("fireball")
	var recast := await wait_until(func():
		return get_tree().get_nodes_in_group("fireball").any(func(f): return not existing.has(f)), 1.5)
	check("Echo recasts the recorded fireball", recast)

	# A hazard reset while recording cancels the recording
	recorder.clear_echoes()
	await place(2780)
	await tap_action("echo")
	await move_until_x(2995)
	await wait_until(func(): return player.hazard_recovery.is_active(), 3.0)
	release_all()
	await frames(5)
	check("spike reset cancels an unfinished recording", not recorder.is_recording and recorder.echoes.is_empty())


func scenario_legacy_level() -> void:
	print("SCENARIO existing TestingPlayerMovement level still works")
	release_all()
	get_tree().paused = false
	if is_instance_valid(get_tree().current_scene):
		get_tree().current_scene.queue_free()
	await get_tree().process_frame
	lvl = load("res://scenes/TestingPlayerMovement.tscn").instantiate()
	get_tree().root.add_child(lvl)
	get_tree().current_scene = lvl
	await seconds(1.0)
	player = lvl.get_node("Player")
	check("legacy level loads with player", player != null and not player.is_dead)
	player.take_damage(3)
	check("legacy damage without a source still works", player.current_health == 7)
	player.invulnerable_time = 0.0
	player.take_damage(99)
	await seconds(0.5)
	check("legacy death screen shows", lvl.get_node("DeathUI/DeathScreen").visible and get_tree().paused)
	get_tree().paused = false


func scenario_feel() -> void:
	print("SCENARIO jump feel, healing and footsteps")
	await load_level()

	# The jump leaves the ground on the frame the press registers, at the same
	# height. (A simulated press, like a real key press between frames,
	# registers on the next physics frame; the buffer staying empty shows the
	# jump never waited on top of that.)
	await place(700)
	await frames(10)
	var floor_y := player.global_position.y
	Input.action_press("jump")
	var waited := false
	for i in 2:
		await get_tree().physics_frame
		waited = waited or player.jump_buffer_time > 0.0
	check("a jump launches on the frame the press registers", player.velocity.y < -300.0 and not waited,
		"vy=%.0f" % player.velocity.y)
	Input.action_release("jump")
	var rise: float = await _measure_rise(floor_y)
	check("a tapped jump still rises about 62 px", absf(rise - 62.0) < 6.0, "%.1f px" % rise)
	await frames(10)

	# Crouching gathers the high jump; she can't walk while crouched
	Input.action_press("crouch")
	Input.action_press("move_right")
	await seconds(0.6)
	check("crouching holds her in place", absf(player.global_position.x - 700.0) < 4.0 and player.charging_jump,
		"x=%.0f" % player.global_position.x)
	Input.action_release("move_right")
	await seconds(2.0)
	floor_y = player.global_position.y
	await tap_action("jump")
	Input.action_release("crouch")
	rise = await _measure_rise(floor_y)
	check("a full crouch-charge still rises about 132 px", absf(rise - 132.0) < 8.0, "%.1f px" % rise)
	await frames(10)
	# Letting go of crouch drops the charge: the next jump is a normal hop
	Input.action_press("crouch")
	await seconds(1.8)
	Input.action_release("crouch")
	await frames(2)
	check("releasing crouch drops the charge", not player.charging_jump and player.charge_time == 0.0)
	floor_y = player.global_position.y
	await tap_action("jump")
	rise = await _measure_rise(floor_y)
	check("after a dropped charge the jump is a normal hop", absf(rise - 62.0) < 6.0, "%.1f px" % rise)

	# Coyote time: a jump just after running off a ledge still counts
	# (The press registers on the frame after it is made, so it lands on
	# airborne frame case[0] + 2)
	for case in [[3, true], [7, false]]:
		await place_on_ledge(1690)
		release_all()
		await frames(6)
		Input.action_press("move_right")
		await wait_until(func(): return not player.is_on_floor(), 2.0)
		await frames(case[0])
		Input.action_press("jump")
		await frames(2)
		var jumped: bool = player.velocity.y < -300.0
		release_all()
		var ms := int((case[0] + 2) * 1000.0 / 60.0)
		if case[1]:
			check("a jump %d ms after running off a ledge still works" % ms, jumped, "vy=%.0f" % player.velocity.y)
		else:
			check("a jump %d ms after leaving the ledge is too late" % ms, not jumped, "vy=%.0f" % player.velocity.y)
		await wait_until(func(): return player.is_on_floor(), 2.0)
		await seconds(0.8)

	# Healing is a short channel, not an instant top-up
	await load_level()
	await place(700)
	player.current_health = 6
	player.update_health_ui()
	await tap_action("heal")
	check("heal begins a channel; nothing is spent yet", player.heal_channel.is_channeling
		and player.current_health == 6 and player.current_mana == 100)
	await seconds(1.3)
	check("completing the channel heals and spends the mana", not player.heal_channel.is_channeling
		and player.current_health == 8 and player.current_mana == 80,
		"hp=%d mp=%d" % [player.current_health, player.current_mana])
	await tap_action("heal")
	await seconds(0.4)
	await tap_action("move_right")
	check("moving breaks the heal and costs nothing", not player.heal_channel.is_channeling
		and player.current_health == 8 and player.current_mana == 80)
	await seconds(0.5)
	await tap_action("heal")
	await seconds(0.3)
	player.take_damage(1)
	check("a hit breaks the heal and costs nothing", not player.heal_channel.is_channeling
		and player.current_mana == 80 and player.current_health == 7)
	player.invulnerable_time = 0.0
	await seconds(0.8)
	await tap_action("heal")
	check("no healing for a moment after a hit", not player.heal_channel.is_channeling)
	await seconds(2.4)
	await tap_action("heal")
	check("healing works again once that moment passes", player.heal_channel.is_channeling)
	await seconds(1.4)

	# Footsteps: soft, dry, and only every other plant
	await load_level()
	await place(500)
	var plants := [0]
	player.footstep.connect(func(_p): plants[0] += 1)
	var heard_before := _count_sounds("step_stone_")
	Input.action_press("move_right")
	await seconds(2.0)
	Input.action_release("move_right")
	var heard := _count_sounds("step_stone_") - heard_before
	check("walking steps are heard at a natural pace, not on every plant", heard >= 3 and heard <= 6 and heard < plants[0],
		"%d heard of %d plants in 2 s" % [heard, plants[0]])
	check("footsteps skip the room echo (dry Foley bus)", String(sfx().last_bus.get("step_stone_1", "")) == "Foley"
		or String(sfx().last_bus.get("step_stone_2", "")) == "Foley")
	await seconds(0.8)
	heard_before = _count_sounds("step_stone_")
	await tap_action("move_right")
	await seconds(0.6)
	check("a quick tap makes no step sound", _count_sounds("step_stone_") == heard_before)


func scenario_camera_aspects() -> void:
	print("SCENARIO camera bounds at other window shapes")
	var original := get_tree().root.size
	for size in [Vector2i(1024, 768), Vector2i(1680, 640), Vector2i(800, 800)]:
		get_tree().root.set_size(size)
		await load_level()
		await frames(5)
		var worst := 0.0
		var where := ""
		for spot in [Vector2(96, 530), Vector2(2600, 430), Vector2(8120, 530), Vector2(3000, 300)]:
			player.teleport_to(spot)
			await frames(20)
			var cam = player.get_node("Camera2D")
			var r := cam_rect()
			var b: Rect2 = cam.bounds
			var over := maxf(maxf(b.position.x - r.position.x, r.end.x - b.end.x),
				maxf(b.position.y - r.position.y, r.end.y - b.end.y))
			if over > worst:
				worst = over
				where = "spot=%s view=%s zoom=%s" % [spot, r, cam.zoom]
		check("camera inside level at window %s" % size, worst <= 0.5, "%.2f %s" % [worst, where])
	get_tree().root.set_size(original)
