extends Node

## Background physics and progression checks for the October polish pass.
## Input below is internal Godot action simulation, never desktop input.
var passed := 0
var failed := 0
var lvl: Node
var completed := false

func check(label: String, ok: bool) -> void:
	passed += int(ok)
	failed += int(not ok)
	print("  PASS " if ok else "  FAIL ", label)

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func open(path: String) -> void:
	get_tree().paused = false
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
		await get_tree().process_frame
	lvl = load(path).instantiate()
	get_tree().root.add_child(lvl)
	get_tree().current_scene = lvl
	await frames(12)

func run_suite(_filter: String) -> void:
	var state := get_tree().root.get_node("GameState")
	state.clear_all()
	state.all_abilities = false
	await open(Journey.MOVEMENT)
	check("movement tutorial contains no spell shrines", lvl.find_children("*", "AbilityShrine", true, false).is_empty())
	check("movement tutorial cannot use any of the three spells", not state.has_ability("fire") and not state.has_ability("heal") and not state.has_ability("echo"))
	check("tutorial ends before the spell-learning passage", lvl.get_node("LevelExit").position.x < 5300 and lvl.get_node("LevelExit").next_scene_path == Journey.PASSAGE)
	var player: Node2D = lvl.get_node("Player")
	for action in ["shoot", "heal", "echo"]:
		Input.action_press(action)
		await frames(2)
		Input.action_release(action)
		await frames(4)
	check("locked spells produce neither fireballs nor Echo recordings", get_tree().get_nodes_in_group("fireball").is_empty() and not player.get_node("EchoRecorder").is_recording)
	player.teleport_to(Vector2(5198, 530))
	await frames(30)
	check("finishing movement records its own completion without teaching magic", state.has_flag("story.movement_done") and not state.has_flag("tutorial.done") and not state.has_ability("echo"))
	await open(Journey.PASSAGE)
	player = lvl.get_node("Player")
	check("abbey entrance starts at the Echo inscription with no magic", player.global_position.x >= 5300 and not state.has_ability("echo") and not state.has_ability("fire"))
	var stone: AbilityShrine = lvl.get_node("EchoStone")
	player.teleport_to(stone.global_position + Vector2(-18, -4))
	await frames(15)
	Input.action_press("interact")
	await frames(2)
	Input.action_release("interact")
	await frames(3)
	check("reading the Echo inscription teaches only Echo", state.has_ability("echo") and not state.has_ability("fire") and not state.has_ability("heal"))
	check("the inscription explains why the word returns", stone.story.contains("Hush") and stone.story.contains("remembers"))
	state.grant_ability("fire")
	state.set_flag("tutorial.done")
	state.set_flag("ch1.r1.solved")
	check("entering the Belfry cannot grant Heal", state.has_ability("fire") and state.has_ability("echo") and not state.has_ability("heal"))
	await open(Journey.BELFRY)
	player = lvl.get_node("Player")
	var spring: AbilityShrine = lvl.get_node("R9/HotSpring")
	spring._on_used(player)
	check("spring healing preserves learned Fire and Echo", state.has_ability("heal") and state.has_ability("fire") and state.has_ability("echo"))
	player.current_mana = 0
	player.teleport_to(Vector2(500, 530))
	Input.action_press("reload")
	await frames(110)
	Input.action_release("reload")
	check("R restores mana without a flame", player.current_mana == player.get_mana_cap())
	check("the obsolete Kindle prompt is absent", player.get_node_or_null("KindlePrompt") == null)
	var skull: HintStone = lvl.find_children("*", "HintStone", true, false)[0]
	for i in 3:
		skull.listen()
		check("hint %d needs no waiting" % (i + 1), skull.stage == i + 1)
	state.clear_all()
	await open(Journey.BELFRY)
	player = lvl.get_node("Player")
	var block: PushableBlock = lvl.get_node("R1/Block")
	player.teleport_to(block.global_position + Vector2(-38, -4))
	await frames(8)
	Input.action_press("move_right")
	await frames(35)
	check("pushing uses a planted brace pose", player.is_pushing and player.animated_sprite.animation == &"push")
	Input.action_release("move_right")
	await frames(20)
	check("releasing movement ends the pushing pose", not player.is_pushing and player.animated_sprite.animation != &"push")
	var bat := Creature.new()
	bat.kind = "bat"
	bat.position = player.global_position + Vector2(90, -70)
	lvl.add_child(bat)
	bat.get_node("DamageArea").monitoring = false
	var attacks := 0
	var returns_home := false
	var last := ""
	for i in 180:
		await frames(1)
		if bat._state == "rush" and last != "rush":
			attacks += 1
		returns_home = returns_home or bat._state == "climb"
		last = bat._state
	check("bat makes repeated attacks without returning to spawn", attacks >= 2 and not returns_home)
	check("bat art has a consistent 64-pixel footprint", is_equal_approx(bat.sprite.sprite_frames.get_frame_texture(&"default", 0).get_width() * bat.sprite.scale.x, 64.0))
	var platform := MovingPlatform.new()
	platform.position = Vector2(1050, 440)
	platform.travel = Vector2(0, 100)
	lvl.add_child(platform)
	await frames(150)
	check("a descending platform stops above masonry", platform.global_position.y + platform.TILE_TOP + 25 <= 534)
	var file := ConfigFile.new()
	file.set_value("progress", "flags", {"tutorial.done": true})
	var path := "res://.godot/polish_legacy.cfg"
	check("legacy save fixture writes safely inside the project cache", file.save(path) == OK)
	state.load_game(path)
	state.grant_ability("heal")
	check("old-save migration keeps Fire and Echo after a new spell", state.has_ability("fire") and state.has_ability("echo") and state.has_ability("heal"))
	for scene in [Journey.BELFRY, Journey.OBSERVATORY, Journey.KILN, Journey.CISTERN, Journey.LAMPS, Journey.GALLERIES, Journey.EYE]:
		await open(scene)
		check("%s has no visible obsolete refill posts" % scene.get_file(), lvl.find_children("*", "KindleFlame", true, false).all(func(n): return not n.is_visible_in_tree()))
		await audit_floor_art(scene.get_file())
	await open("res://scenes/story/nan_cottage.tscn")
	lvl.dialogue.say("nan", "warm", "The Hush took the words. Read the inscriptions to remember your spells.")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	InputMap.action_erase_events("shoot")
	Input.parse_input_event(click)
	await frames(2)
	check("click finishes cottage dialogue with attack unbound", not lvl.dialogue.is_typing)
	InputMap.load_from_project_settings()
	file.set_value("progress", "flags", {"tutorial.done": true, "ability.fire": false})
	file.save(path)
	state.load_game(path)
	check("migration respects explicitly locked spells in older saves", not state.has_ability("fire"))
	state.clear_all()
	state.all_abilities = true
	completed = true


func audit_floor_art(label: String) -> void:
	var rects: Array[Rect2] = []
	var grounded := true
	var separated := true
	for node in lvl.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if not sprite.is_visible_in_tree() or not sprite.texture or sprite.centered or sprite.offset.y >= 0:
			continue
		if sprite.texture.resource_path.get_file().get_basename() not in ["skull_pile", "rocks_a", "rocks_b", "skeleton", "tombstone_rubble", "candelabra", "candle", "barrel", "crate", "bones", "urn", "pot", "chest"]:
			continue
		var ink := Rect2(sprite.texture.get_image().get_used_rect())
		var rect := Rect2(sprite.to_global(ink.position + sprite.offset), ink.size * sprite.global_scale)
		separated = separated and rects.all(func(other): return not other.intersects(rect))
		rects.append(rect)
		var foot := Vector2(rect.get_center().x, rect.end.y)
		var query := PhysicsRayQueryParameters2D.create(foot - Vector2(0, 2), foot + Vector2(0, 3), 2)
		var hit: Dictionary = lvl.get_world_2d().direct_space_state.intersect_ray(query)
		grounded = grounded and not hit.is_empty() and hit["normal"].y < -0.8
		if hit.is_empty():
			print("  Ungrounded prop: ", sprite.get_path(), " foot ", foot)
	check(label + " floor decorations rest on collision surfaces", grounded)
	check(label + " floor decorations do not overlap each other", separated)
