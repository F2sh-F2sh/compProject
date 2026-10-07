extends Node

## Background physics/state checks. No desktop input, window, or screenshots.
var passed := 0
var failed := 0
var lvl: Node

func check(label: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("  PASS ", label)
	else:
		failed += 1
		print("  FAIL ", label)

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func open_scene(path: String) -> void:
	get_tree().paused = false
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	await get_tree().process_frame
	lvl = load(path).instantiate()
	get_tree().root.add_child(lvl)
	get_tree().current_scene = lvl
	await frames(65)
	if lvl.get("dialogue") and lvl.dialogue.active:
		lvl.dialogue.complete()
	await frames(20)

func run_suite(_filter: String) -> void:
	await open_scene("res://scenes/story/nan_lantern_cottage.tscn")
	var has_pause := false
	for child in lvl.get_children():
		if child is PauseMenu:
			has_pause = true
	check("cottage provides the pause menu after dialogue", has_pause)
	var pause_event := InputEventKey.new()
	pause_event.physical_keycode = KEY_ESCAPE
	pause_event.keycode = KEY_ESCAPE
	pause_event.pressed = true
	Input.parse_input_event(pause_event)
	await frames(3)
	check("pause input pauses the cottage", get_tree().paused)
	pause_event = InputEventKey.new()
	pause_event.physical_keycode = KEY_ESCAPE
	pause_event.keycode = KEY_ESCAPE
	pause_event.pressed = false
	Input.parse_input_event(pause_event)
	for child in lvl.get_children():
		if child is PauseMenu:
			child._set_open(false)
	var original_size := get_tree().root.size
	get_tree().root.size = Vector2i(2400, 648)
	await frames(90)
	var visible_size: Vector2 = get_viewport().get_visible_rect().size / lvl.camera.zoom
	var visible_area := Rect2(lvl.camera.position - visible_size / 2, visible_size)
	check("wide cottage camera stays inside the authored backdrop", Rect2(-1, 99, 962, 702).encloses(visible_area))
	get_tree().root.size = original_size
	await open_scene("res://scenes/story/well_descent.tscn")
	var lamp: PointLight2D = lvl._sconces[0]["light"]
	var stray_glow := false
	for child in lvl.get_children():
		if child is Sprite2D and child.texture == StoryPaint.GLOW_TEXTURE and child.position.is_equal_approx(lamp.position) and child.is_visible_in_tree():
			stray_glow = true
	check("unlit lamp has no detached visible glow", not stray_glow)
	lvl.light_sconce(0)
	lvl.light_sconce(1)
	var closed_door := false
	for child in lvl.get_children():
		if child is Sprite2D and child.position.is_equal_approx(Vector2(1700, 664)) and child.texture is AtlasTexture and child.texture.region == Rect2(SurfaceArt.REGIONS["door_tall"][1]) and child.is_visible_in_tree():
			closed_door = true
	check("open ward removes its closed door artwork", not closed_door)
	var fire: Area2D = load("res://scenes/FireBall.tscn").instantiate()
	fire.position = Vector2(350, 485)
	fire.direction = Vector2.DOWN
	lvl.add_child(fire)
	await frames(15)
	check("fireballs collide with prologue terrain", not is_instance_valid(fire))
	var slime: CharacterBody2D = load("res://scenes/slime.tscn").instantiate()
	slime.respawn_on_room_reset = true
	slime.position = Vector2(1400, 650)
	lvl.add_child(slime)
	await frames(2)
	Chill.apply(slime, 5.0)
	slime.die()
	await frames(3)
	check("thawing a killed frozen enemy preserves stopped physics", slime.is_dead and not slime.is_physics_processing())
	await frames(45)
	check("killed frozen enemy stays harmless", not slime.get_node("DamageArea").monitoring)
	slime.reset_state()
	await frames(2)
	check("room reset restores the defeated enemy", not slime.is_dead and slime.is_physics_processing())
	# Isolated geometry fixtures in a real level's physics world. These check
	# edge cases, not traversal of an authored puzzle route.
	var room := Room.new()
	room.bounds = Rect2(200, 0, 800, 300)
	lvl.add_child(room)
	var cube := RuneCube.new()
	cube.start_recipe = "space/portal/right/normal"
	cube.position = Vector2(600, 200)
	room.add_child(cube)
	var player: CharacterBody2D = lvl.player
	player.teleport_to(Vector2(570, 200))
	player.lock_controls(true)
	var carrier := RuneCarrier.new()
	player.add_child(carrier)
	var wall: StaticBody2D = lvl._solid(Rect2(584, 140, 4, 65))
	await frames(3)
	check("a solid wall blocks picking up a nearby cube", carrier.try_pick_up() != "" and not cube.is_carried)
	if carrier.held:
		carrier.held = null
		cube.put_down(Vector2(600, 200))
	wall.queue_free()
	await frames(3)
	check("the same cube can be picked up with no wall", carrier.try_pick_up() == "" and cube.is_carried)
	carrier.held = null
	cube.put_down(Vector2(600, 200))
	await frames(3)
	var spell: Dictionary = RuneBook.spell(cube.recipe)
	var far := RunePortal.far_centre(cube, spell)
	room.bounds = Rect2(200, 0, far.x - 200 + 2, 300)
	check("the entire portal exit must fit inside its room", RunePortal.problem(cube, spell).contains("outside"))
	room.bounds = Rect2(200, 0, 800, 300)
	check("portal opens when the destination is clear", RunePortal.problem(cube, spell) == "")
	var portal := RunePortal.new()
	lvl.add_child(portal)
	portal.setup(cube, spell)
	portal.set_physics_process(false)
	player.teleport_to(portal.entrance + Vector2(0, 12))
	var exit_wall: StaticBody2D = lvl._solid(Rect2(far - Vector2(20, 35), Vector2(40, 70)))
	await frames(3)
	var before := player.global_position
	portal._carry(player)
	check("a newly blocked portal exit does not embed the player", player.global_position.is_equal_approx(before))
	exit_wall.collision_layer = 0
	await frames(3)
	before = player.global_position
	var velocity_before := player.velocity
	portal._carry(player)
	check("clearing the exit permits transit with velocity preserved", player.global_position.is_equal_approx(before + portal.exit_point - portal.entrance) and player.velocity == velocity_before)
	var file := ConfigFile.new()
	var path := "res://.godot/adversarial_save.cfg"
	file.set_value("progress", "flags", {"tutorial.done": true, "ch1.stat.time": 12.0, "bad.stat": [], 7: true})
	file.set_value("progress", "checkpoints", {"valid": "ch1.r1", "invalid": 123, 42: "wrong key"})
	check("nested corrupted-save fixture was written", file.save(path) == OK)
	var state := get_tree().root.get_node("GameState")
	state.load_game(path)
	check("corrupt nested checkpoint entries are rejected", state.checkpoints == {"valid": "ch1.r1"})
	check("corrupt nested flags are rejected without losing valid progress", state.flags == {"tutorial.done": true, "ch1.stat.time": 12.0})
	state.clear_all()
