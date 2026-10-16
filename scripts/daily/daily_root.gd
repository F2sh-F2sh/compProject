class_name DailyRoot
extends ChapterRoot

## The daily puzzle's level. It is a ChapterRoot (so the HUD, the pause menu,
## hints, Reset Room, the rune screens and the end card all work as in the
## story) whose rooms are not saved in the scene: they are built here, in
## code, from DailyRun's seed by DailyGenerator and RoomKit, and so are the
## player, the camera and the screen effects. The scene file is just this
## script on an empty node.
##
## Dying reloads the scene: the same seed builds the same level, and the
## player starts in the furthest room she had reached (earlier gates are shut
## behind her as in the story). No checkpoint is written, so the title's
## Continue is never touched.

## The generated puzzle (see DailyGenerator).
var spec: Dictionary
var kit: RoomKit
## The pieces each room's module made, by room index.
var pieces: Array = []
var bell: GreatBell
var exit_door: Area2D
var endless_label: Label
var death_screen: Control
## Per room index: the sentence on each cube that was switched on last.
var _recent := {}
var _transitioning := false


func _init() -> void:
	chapter_id = "daily"
	chapter_title = "Daily Puzzle"
	unit_name = "puzzle"
	complete_heading = "PUZZLE SOLVED"
	closing_line = ""
	total_pages = 0


func _ready() -> void:
	DailyRun.apply()
	DailyRun.root = self
	spec = DailyRun.spec_override if not DailyRun.spec_override.is_empty() else DailyGenerator.generate(
		DailyRun.seed_value, DailyRun.difficulty, DailyRun.tier)
	var darkness := CanvasModulate.new()
	darkness.name = "Darkness"
	darkness.color = RoomKit.AMBIENT
	add_child(darkness)
	kit = RoomKit.new(self, DailyRng.new(int(spec["seed"])).fork("decor"))
	_build_rooms()
	_build_player_and_ui()
	room_entered.connect(_on_room_entered)
	super._ready()
	if get_viewport().get_visible_rect().size.x < 900 and is_instance_valid(_objective):
		_objective.offset_top = 148 if DailyRun.mode == "endless" else 120
		_objective._fit()
		_title.add_theme_font_size_override("font_size", 32)
	if DailyRun.mode == "endless":
		_title.offset_top = 148
		_title.offset_bottom = 206
	player.died.connect(_on_player_died)
	room_reset_done.connect(func(_room): DailyRun.resets += 1)
	for cube in get_tree().get_nodes_in_group("rune_cube"):
		if cube is RuneCube and is_ancestor_of(cube):
			# A portable portal's doorway must clear the floor after placement.
			# This opt-in belongs to generated cubes; story portals keep their
			# authored doorway positions.
			cube.set_meta(&"daily_portal_floor_clearance", 8.0)
			cube.activated.connect(_on_cube_activated)


func _exit_tree() -> void:
	# A death reloads the level and the new root takes over at once; leaving
	# for the title (or the end card's buttons) puts the story's conditions
	# back. Decide a frame later, when it is clear which it was.
	var tree := get_tree()
	if tree:
		tree.process_frame.connect(DailyRoot._after_exit, CONNECT_ONE_SHOT)


static func _after_exit() -> void:
	if DailyRun.root == null or not is_instance_valid(DailyRun.root) or not DailyRun.root.is_inside_tree():
		DailyRun.restore()


# ------------------------------------------------------------------ building

func _build_rooms() -> void:
	var rooms_spec: Array = spec["rooms"]
	for i in rooms_spec.size():
		var r: Dictionary = rooms_spec[i]
		var module := DailyModules.make(String(r["module"]))
		var x0: int = r["x0"]
		var x1: int = r["x1"]
		var first := i == 0
		kit.shell(x0, x1, module.ceiling_row(), first, false)
		var entry := Vector2(RoomKit.cx(x0 + 2), 530)
		var room := kit.make_room("R%d" % (i + 1), module.title, x0, x1, module.ceiling_row(), entry, i, i)
		var part := module.build(kit, room, x0, x1, r["params"], spec["kit"])
		if not part.has("gate"):
			part["gate"] = kit.gate(room, "ExitGate", x1)
			part["goal_exit"] = true
		pieces.append(part)
		room.objective += " Personal Fire allowed." if r.get("personal_fire", false) else " Personal Fire and Echo sealed."
	if bool(spec.get("endless", false)):
		_build_stair(rooms_spec.size())
		return
	# The bell hall: a short room whose bell ends the puzzle
	var b: Dictionary = spec["bell"]
	kit.shell(b["x0"], b["x1"], RoomKit.LOW_CEIL, false, true)
	var hall := kit.make_room("R%d" % (rooms_spec.size() + 1), "The Bell", b["x0"], b["x1"], RoomKit.LOW_CEIL,
		Vector2(RoomKit.cx(b["x0"] + 2), 530), rooms_spec.size(), rooms_spec.size())
	bell = kit.inst(RoomKit.PUZZLE + "great_bell.tscn", hall, "GreatBell",
		Vector2(RoomKit.cx(b["x0"] + 5), RoomKit.FLOOR_Y - 120.0),
		{"announce": "Puzzle solved", "announce_sub": "The bell rings out.", "tolls": 1, "toll_gap": 1.0}) as GreatBell
	kit.guide(hall, "Ring the bell.")
	kit.step(hall, "The bell rings", ObjectiveStep.Condition.POWERED, bell)
	var deco := kit.group(hall, "Decor")
	for col in [b["x0"] + 3, b["x0"] + 7]:
		kit.torch(deco, col)


func _build_player_and_ui() -> void:
	var rooms_spec: Array = spec["rooms"]
	var start_room: Room = kit.rooms["R%d" % (clampi(DailyRun.respawn_room, 0, rooms_spec.size()) + 1)]
	var p := kit.inst("res://scenes/player/player.tscn", self, "Player", start_room.entry_spawn,
		{"z_index": 1, "collision_mask": 2})
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.set_script(load("res://scripts/world/camera_bounds.gd"))
	camera.set("bounds", start_room.bounds)
	camera.set("base_zoom", Vector2(2, 2))
	camera.zoom = Vector2(2, 2)
	p.add_child(camera)
	var aura := PointLight2D.new()
	aura.name = "PlayerLight"
	aura.texture = LightTextures.radial(256)
	aura.color = Color(0.78, 0.72, 1.0)
	aura.energy = 1.15
	aura.texture_scale = 1.45
	aura.height = 40.0
	aura.position = Vector2(0, -20)
	p.add_child(aura)

	var post := CanvasLayer.new()
	post.name = "PostFX"
	post.layer = 1
	post.set_script(load("res://scripts/fx/post_fx.gd"))
	var screen := ColorRect.new()
	screen.name = "Screen"
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/dungeon_post.gdshader")
	mat.set_shader_parameter("fog_floor_y", float(RoomKit.FLOOR_Y))
	screen.material = mat
	post.add_child(screen)
	add_child(post)

	kit.inst("res://scenes/ui/hud.tscn", self, "HUD", Vector2.ZERO)
	kit.inst("res://scenes/ui/ammo_ui.tscn", self, "AmmoUI", Vector2.ZERO)
	var death_ui := CanvasLayer.new()
	death_ui.name = "DeathUI"
	death_ui.layer = 2
	add_child(death_ui)
	death_screen = load("res://scenes/ui/death_screen.tscn").instantiate()
	death_ui.add_child(death_screen)
	if DailyRun.mode == "endless":
		_build_endless_hud()
	var pause := CanvasLayer.new()
	pause.name = "PauseMenu"
	pause.set_script(load("res://scripts/ui/pause_menu.gd"))
	add_child(pause)
	# Last, so its screens get input before the pause menu
	var manager := kit.inst("res://scenes/runes/rune_manager.tscn", self, "RuneManager", Vector2.ZERO)
	manager.set("starting_fragments", spec["kit"])


# ------------------------------------------------------------------ the run

func _physics_process(delta: float) -> void:
	if _transitioning: return
	# Moving stones and in-flight spells may still land during the fade.
	# Reset owns this attempt: neither the parent objective ledger nor the
	# challenge score may credit those transient completions. Time still runs.
	if is_resetting:
		if not DailyRun.finished: DailyRun.time += delta
		return
	super._physics_process(delta)
	# Pit modules remove the bedrock as well as the floor. End a fall below
	# that bedrock through the normal death flow, including Endless lives.
	if is_instance_valid(player) and not player.is_dead and player.global_position.y > 14 * RoomKit.T:
		player.die()
	if get_viewport().get_visible_rect().size.x < 900 and is_instance_valid(_objective) and _objective.visible:
		var title_top := maxf(118.0, _objective.position.y + _objective.size.y + 12.0)
		_title.offset_top = title_top
		_title.offset_bottom = title_top + 46.0
	for i in pieces.size():
		DailyModules.make(String(spec["rooms"][i]["module"])).update_runtime(pieces[i])
		var part: Dictionary = pieces[i]
		var room: Room = kit.rooms["R%d" % (i + 1)]
		if part.get("goal_exit", false):
			# Reevaluate after Reset Room too; scoring remembers the first
			# clear, but a fresh attempt must solve its physical goals again.
			part["gate"].set_powered(room.is_cleared())
		elif part.has("finish_step") and not room.is_cleared():
			part["gate"].set_powered(false)
	if DailyRun.finished or current_room == null:
		return
	if bell and bell.is_rung():
		DailyRun.finished = true
		return
	DailyRun.time += delta
	# The first time a puzzle room is cleared, remember what cleared it
	var order := _rooms_in_order.find(current_room)
	if order >= 0 and order < spec["rooms"].size() and not DailyRun.solved_with.has(order) and current_room.is_cleared():
		DailyRun.solved_with[order] = _recent.get(order, {}).duplicate()
		DailyRun.rooms_cleared += 1
		_log_room(order)
		if pieces[order].has("gate"):
			pieces[order]["gate"].set_powered(true)


func _on_room_entered(room: Room) -> void:
	if _transitioning: return
	var order := _rooms_in_order.find(room)
	DailyRun.room_spells(spec["rooms"][order] if order >= 0 and order < spec["rooms"].size() else {})
	if not DailyRun.room_started.has(order):
		DailyRun.room_started[order] = {"time": DailyRun.time, "resets": DailyRun.resets, "hints": DailyRun.hints, "deaths": DailyRun.deaths}
	if order > DailyRun.respawn_room:
		DailyRun.respawn_room = order


## A cube went on: counts as a cast, and is what the room's clearing is
## credited to (the codex of ways).
func _on_cube_activated(cube: RuneCube) -> void:
	if _transitioning: return
	DailyRun.casts += 1
	var order := _rooms_in_order.find(cube.home_room)
	if order < 0:
		return
	if not _recent.has(order):
		_recent[order] = {}
	var part: Dictionary = pieces[order]
	var phase := 0
	if part.has("beats") and part["beats"][0]["steps"].all(func(step): return step.done): phase = 1
	for name in part["cubes"]:
		if part["cubes"][name] != cube: continue
		if part.get("reuse", false) and not String(name).begins_with("%d: " % (phase + 1)): continue
		_recent[order][name] = cube.recipe.to_key()


func note_hint() -> void:
	super.note_hint()
	DailyRun.hints += 1


## Which assists were on, as a number: 1 less damage, 2 unlimited mana, 4
## movement aids. Shown with the result and in the share code.
static func assist_mask() -> int:
	var mask := 0
	if Settings.assist_damage < 1.0:
		mask |= 1
	if Settings.assist_infinite_mana:
		mask |= 2
	if Settings.assist_auto_sprint or Settings.assist_toggle_crouch:
		mask |= 4
	return mask


## "Room 1 - Gust Alley: Push right, strong (4 ways)" for each puzzle room.
func ways_lines() -> Array:
	var lines: Array = []
	var rooms_spec: Array = spec["rooms"]
	for i in rooms_spec.size():
		var module := DailyModules.make(String(rooms_spec[i]["module"]))
		var plans := module.plans(rooms_spec[i]["params"], spec["kit"])
		var used: Dictionary = DailyRun.solved_with.get(i, {})
		var found := "your own way"
		if used.is_empty():
			found = "a way of your own"
		for plan in plans:
			var same: bool = not plan["cubes"].is_empty()
			for cube_name in plan["cubes"]:
				if not used.has(cube_name) or used[cube_name] != plan["cubes"][cube_name]:
					same = false
			if same:
				found = String(plan["label"])
				break
		lines.append("%d. %s: %s  (%d ways in all)" % [i + 1, module.title, found, plans.size()])
	return lines


## The bell has rung: the puzzle is done. Scores it, writes it down and shows
## the card (this replaces the story's end card).
func finish_chapter() -> void:
	DailyRun.finished = true
	for node in get_tree().get_nodes_in_group("gameplay_ui"):
		node.visible = false
	var rooms_count: int = spec["rooms"].size()
	var stats := {"time": DailyRun.time, "deaths": DailyRun.deaths, "resets": DailyRun.resets,
		"hints": DailyRun.hints, "casts": DailyRun.casts}
	var scored := DailyScore.compute(stats, DailyScore.par_seconds(spec), rooms_count)
	var result := {
		"day": DailyRun.day_index, "mode": DailyRun.mode, "score": scored["score"], "stars": scored["stars"],
		"time": DailyRun.time, "deaths": DailyRun.deaths, "resets": DailyRun.resets, "hints": DailyRun.hints,
		"casts": DailyRun.casts, "assist": assist_mask(), "difficulty": DailyRun.difficulty, "tier": DailyRun.tier,
		"version": spec["version"], "rooms": rooms_count, "digest": spec["digest"],
	}
	var info := {}
	if DailyRun.mode == "daily" or DailyRun.mode == "practice":
		info = DailyStore.record(result)
	DailyComplete.open(self, {"result": result, "scored": scored, "info": info, "ways": ways_lines(),
		"code": DailyScore.encode(result), "mode": DailyRun.mode, "seed": DailyRun.seed_value})


func _build_stair(index: int) -> void:
	var e: Dictionary = spec["exit"]
	var x0: int = e["x0"]
	var x1: int = e["x1"]
	kit.shell(x0, x1, RoomKit.LOW_CEIL, false, true)
	var hall := kit.make_room("R%d" % (index + 1), "The Stair", x0, x1, RoomKit.LOW_CEIL,
		Vector2(RoomKit.cx(x0 + 2), 530), index, index)
	var door := Sprite2D.new()
	door.name = "StairDoor"
	door.texture = load("res://assets/tileset/walls/tiles/10_door_wood.png")
	door.centered = false
	door.offset = Vector2(-32, -64)
	door.position = Vector2(RoomKit.cx(x1 - 2), RoomKit.FLOOR_Y)
	hall.add_child(door)
	var glow := PointLight2D.new()
	glow.texture = LightTextures.radial(256)
	glow.color = Color(0.5, 0.62, 1.0)
	glow.energy = 1.2
	glow.texture_scale = 1.1
	glow.position = Vector2(0, -32)
	door.add_child(glow)
	exit_door = Area2D.new()
	exit_door.name = "ExitDoor"
	exit_door.collision_layer = 0
	exit_door.collision_mask = 1 # Player body; layer 2 belongs to its hurtbox.
	exit_door.position = door.position + Vector2(0, -64)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(64, 128)
	shape.shape = rectangle
	exit_door.add_child(shape)
	hall.add_child(exit_door)
	exit_door.body_entered.connect(_on_exit_reached)
	kit.guide(hall, "Go through the door.")
	kit.torch(hall, x0 + 2)
	kit.torch(hall, x1 - 3)


func _build_endless_hud() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 3
	overlay.add_to_group("gameplay_ui")
	add_child(overlay)
	endless_label = Label.new()
	endless_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	# The existing active-rune strip occupies y=82..112.
	endless_label.offset_top = 114
	endless_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endless_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	endless_label.add_theme_font_override("font", Fonts.UI)
	endless_label.add_theme_font_size_override("font_size", 16)
	endless_label.add_theme_color_override("font_color", Color("e8dcc0"))
	endless_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	endless_label.add_theme_constant_override("shadow_offset_x", 2)
	endless_label.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(endless_label)
	endless_label.text = "Endless · Room %d · %s · Lives %d" % [DailyRun.endless_k + 1, DailyDifficulty.name_of(DailyRun.level()), DailyRun.lives]
	if DailyRun.deaths > 0:
		endless_label.modulate = Color("b23a48")
		create_tween().tween_property(endless_label, "modulate", Color.WHITE, 0.6)


func _on_player_died() -> void:
	DailyRun.deaths += 1
	if DailyRun.mode != "endless":
		return
	if not DailyRun.lose_life():
		return
	DailyRun.finished = true
	death_screen.set_process_input(false)
	await get_tree().create_timer(1.5, true).timeout
	death_screen.hide()
	EndlessCard.open(self, "over")


func _on_exit_reached(body: Node) -> void:
	if body != player or DailyRun.finished or is_resetting or not kit.rooms["R1"].is_cleared():
		return
	DailyRun.finished = true
	_transitioning = true
	var stats := {"time": DailyRun.time, "deaths": DailyRun.deaths, "resets": DailyRun.resets,
		"hints": DailyRun.hints, "casts": DailyRun.casts}
	var module := DailyModules.make(String(spec["rooms"][0]["module"]))
	var scored := DailyScore.compute(stats, module.par_seconds + 10.0, 1)
	DailyRun.last_ways = String(ways_lines()[0]).trim_prefix("1. ")
	var rest := DailyRun.bank_endless_room(int(scored["score"]))
	DailyRun.new_best = DailyStore.record_endless(DailyRun.endless_start, DailyRun.run_rooms,
		DailyRun.run_score, DailyRun.level()) or DailyRun.new_best
	if rest:
		EndlessCard.open(self, "rest")
	else:
		DailyRun.prepare_endless_room()
		SceneFade.change(get_tree(), DailyRun.SCENE)


func _log_room(index: int) -> void:
	var entry: Dictionary = spec["rooms"][index]
	var before: Dictionary = DailyRun.room_started.get(index, {"time": 0.0, "resets": 0, "hints": 0, "deaths": 0})
	var module := DailyModules.make(entry["module"])
	var parts := module.score_parts(entry["params"], spec["kit"])
	DailyCalibration.append({"module": entry["module"], "params": entry["params"], "tier": spec["tier"],
		"r": DailyDifficulty.total(parts), "parts": parts, "time": DailyRun.time - float(before["time"]),
		"resets": DailyRun.resets - int(before["resets"]), "hints": DailyRun.hints - int(before["hints"]),
		"deaths": DailyRun.deaths - int(before["deaths"])})
