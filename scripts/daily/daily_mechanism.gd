class_name DailyMechanism
extends DailyModule

## Generated variants of the story's fire, ice, light and space puzzles.
## Geometry and effects use the same story nodes; no separate spell simulator.
const DEFINITIONS := {
	"frozen_crossing": ["Frozen Crossing", "Cross the frozen span.", 3, 2, "ice/-/right/-"],
	"kindling": ["Kindling", "Light every marked brazier.", 2, 2, "fire/projectile/right/-"],
	"burn_through": ["Burn Through", "Clear the barrier.", 2, 2, "fire/projectile/right/-"],
	"prism_relay": ["Prism Relay", "Bring light to the crystal.", 4, 3, "light/beam/-/bounce"],
	"folded_wall": ["Folded Wall", "Find the far side of the wall.", 5, 3, "space/portal/right/-"],
	"together": ["Together", "Hold the plate as the flame reaches the shutter.", 2, 3, "fire/projectile/right/-"],
	"still_piston": ["Still Piston", "Still the ram, then pass beneath it.", 3, 2, "ice/freeze/right/-"],
	"dark_hall": ["Dark Hall", "Carry light across the hidden stones.", 4, 2, "light/glow/self/-"],
}

func configure(module_id: String) -> void:
	id = module_id
	var data: Array = DEFINITIONS[id]
	title = data[0]
	objective = data[1]
	min_tier = data[2]
	par_seconds = 60.0

func parameter_grid() -> Array:
	match id:
		"frozen_crossing":
			var out: Array = []
			for width in [3, 4, 5]:
				for lock in [0, 1]: out.append({"width": width, "lock": lock})
			return out
		"kindling":
			var out: Array = []
			for lock in [0,1]:
				for layout in [{"count": 1, "high": false}, {"count": 1, "high": true}, {"count": 2, "high": false}]:
					var params: Dictionary = layout.duplicate()
					params["lock"] = lock
					out.append(params)
			return out
		"burn_through": return [{"kind": 0, "distance": 2}, {"kind": 0, "distance": 3}, {"kind": 1, "distance": 2}]
		"prism_relay": return [{"distance": 2, "high": false}, {"distance": 3, "high": true}]
		"folded_wall": return [{"width": 2}, {"width": 3}, {"width": 4}]
		"together": return [{"window": 1.0}, {"window": 1.5}]
		"still_piston": return [{"speed": 400}, {"speed": 520}]
		"dark_hall": return [{"gaps": 1}, {"gaps": 2}]
	return [{}]

func sample(rng: DailyRng, _difficulty: int, _tier: int) -> Dictionary:
	return (rng.pick(parameter_grid()) as Dictionary).duplicate(true)

func fallback(_tier: int) -> Dictionary:
	return parameter_grid()[0].duplicate(true)

func columns(params: Dictionary) -> int:
	return 14 + int(params.get("width", 0))

func ceiling_row() -> int:
	return RoomKit.HIGH_CEIL if id == "prism_relay" else RoomKit.LOW_CEIL

func concept_of(_params: Dictionary) -> float:
	return float(DEFINITIONS[id][3])

func base_recipe(params: Dictionary) -> String:
	if id == "kindling":
		var form := "projectile" if int(params.get("lock", 0)) == 0 else "-"
		return "fire/%s/%s/-" % [form, "up" if params.get("high", false) else "right"]
	if id == "burn_through" and int(params.get("kind", 0)) == 1: return "wind/-/right/-"
	if id == "frozen_crossing" and int(params.get("lock", 0)) == 0: return "ice/-/right/long"
	return String(DEFINITIONS[id][4])

func open_slots(params: Dictionary) -> Dictionary:
	var slots: Array = []
	var recipe := base_recipe(params).split("/")
	for i in 4:
		if recipe[i] == "-": slots.append(i)
	return {"Puzzle Cube": slots}

func plans(params: Dictionary, words: PackedStringArray) -> Array:
	if not DailyVerified.bypass: return DailyVerified.plans(id, params, words)
	return raw_plans(params, words)

func raw_plans(params: Dictionary, words: PackedStringArray) -> Array:
	var out: Array = []
	var base := base_recipe(params).split("/")
	for key in DailyKit.sentences(words):
		var parts := key.split("/")
		var fits := true
		for i in 4:
			if base[i] != "-" and parts[i] != base[i]: fits = false
		if fits: out.append({"label": key.replace("/", ", "), "cubes": {"Puzzle Cube": key}})
	return out

func non_plans(_params: Dictionary, _words: PackedStringArray) -> Array:
	return [{"label": "Wind cannot replace this rune", "cubes": {"Puzzle Cube": "wind/push/left/normal"}}]

func build(k: RoomKit, room: Room, x0: int, x1: int, params: Dictionary, _words: PackedStringArray) -> Dictionary:
	var cx := RoomKit.cx(x0 + 4)
	var cube_y := float(RoomKit.FLOOR_Y)
	if id == "frozen_crossing": cube_y += RuneCube.SIZE
	if id == "still_piston": cube_y -= 64
	if id == "folded_wall": cube_y -= 16
	if id == "dark_hall": cx = RoomKit.cx(x0 + 6)
	var base := base_recipe(params)
	var lock := 0
	var parts := base.split("/")
	for i in 4:
		if parts[i] != "-": lock |= 1 << i
	var cube := k.cube(room, "Puzzle Cube", cx, base, {"dungeon_powered": true,
		"carryable": id == "dark_hall", "mounted": id in ["frozen_crossing", "folded_wall", "still_piston"], "locked_slots": lock}, cube_y) as RuneCube
	var gate := k.gate(room, "ExitGate", x1)
	var pieces := {"cubes": {"Puzzle Cube": cube}, "gate": gate, "id": id, "params": params, "x0": x0, "x1": x1}
	match id:
		"frozen_crossing", "dark_hall":
			var start := x0 + 5
			var width := int(params["width"]) if id == "frozen_crossing" else 2 * int(params["gaps"]) - 1
			for col in range(start, start + width):
				if id == "dark_hall" and col == x0 + 6: continue
				k.ground.erase_cell(Vector2i(col, 8))
				for row in range(9, 13): k.earth.erase_cell(Vector2i(col, row))
				if id == "dark_hall":
					if not pieces.has("gap_edges"): pieces["gap_edges"] = []
					pieces["gap_edges"].append(col * 64)
					var subdivisions := 1
					for j in subdivisions:
						var stone := k.inst(RoomKit.PUZZLE + "spectral_platform.tscn", room, "HiddenStone%d_%d" % [col, j],
							Vector2(col * 64 + j * (64 / subdivisions), RoomKit.FLOOR_Y), {"mode": 1, "casts_shadow": false, "size": Vector2(64 / subdivisions, 12)})
						if not pieces.has("stones"): pieces["stones"] = []
						pieces["stones"].append(stone)
			pieces["crossing_end"] = float((start + width) * 64)
			var crossing_target: Node
			if id == "frozen_crossing":
				var span := BridgeSpan.new()
				span.cube = cube
				room.add_child(span)
				crossing_target = span
			if id == "dark_hall":
				var span := VisibleSpan.new()
				span.stones = pieces["stones"]
				room.add_child(span)
				crossing_target = span
			k.step(room, "The crossing rune wakes", ObjectiveStep.Condition.POWERED, crossing_target)
			k.step(room, "Safely across", ObjectiveStep.Condition.REACHED, null,
				{"area": Rect2((start + width) * 64, 400, 3 * 64, 140)})
			var step: ObjectiveStep = room.get_children()[-1]
			pieces["finish_step"] = step
		"kindling", "together":
			var braziers: Array = []
			var count := int(params.get("count", 1))
			for i in count:
				var at := Vector2(cx + 192, RoomKit.FLOOR_Y - (0 if i == 0 else 50))
				var props := {"wall_side": -1 if i > 0 else 0}
				if params.get("high", false):
					at = Vector2(cx, 350)
					props = {"hang_length": 94.0}
				if id == "together": props["burn_time"] = params["window"]
				var brazier := k.inst(RoomKit.PUZZLE + "brazier.tscn", room, "Brazier%d" % i, at, props)
				braziers.append(brazier)
			var sources := braziers.duplicate()
			if id == "together":
				var plate := k.plate(room, "TimingPlate", cx + 128, {"width": 48.0})
				sources.append(plate)
				pieces["plate"] = plate
			k.circuit(room, "FireCircuit", sources, [gate], {"latch": true, "mode": 0, "channel_y": 440.0})
			k.step(room, "The fire circuit opens the gate", ObjectiveStep.Condition.OPEN, gate)
		"burn_through":
			var at := Vector2(cx + int(params["distance"]) * 64, RoomKit.FLOOR_Y)
			var barrier: Node
			if int(params["kind"]) == 0:
				barrier = k.inst("res://scenes/runes/burnable.tscn", room, "Brambles", at, {"size": Vector2(32, 144)})
			else:
				barrier = k.inst("res://scenes/runes/cracked_wall.tscn", room, "CrackedWall", at + Vector2(108, 0), {"break_momentum": 660.0})
				# The low stone has a run-up for a sustained wind. The upper stone
				# sits close enough for a single gust to land a heavy impact.
				var low := k.stone(room, "RunupStone", cx + 64, {"size": Vector2(48, 32)})
				k.inst(RoomKit.PUZZLE + "spectral_platform.tscn", room, "ImpactLedge", Vector2(cx + 160, RoomKit.FLOOR_Y - 48),
					{"mode": 0, "start_solid": true, "size": Vector2(64,12)})
				var high := k.stone(room, "GustStone", cx + 192, {}, RoomKit.FLOOR_Y - 48)
				pieces["impact_stones"] = [low, high]
			k.step(room, "The barrier falls", ObjectiveStep.Condition.OPEN, barrier)
			pieces["barrier"] = barrier
		"prism_relay":
			var distance := int(params["distance"]) * 64
			var mirror := k.inst(RoomKit.PUZZLE + "mirror.tscn", room, "Mirror", Vector2(cx + distance, RoomKit.FLOOR_Y - 16), {"facing": 3, "rotatable": false, "post_length": 16.0})
			var height := float(distance)
			# The cap blocks a diagonal shortcut. Keep the normal floor beneath it:
			# the 22px seam is the low beam passage, not a full solid support.
			k.floor_tile(x0 + 5, 7)
			k.inst(RoomKit.PUZZLE + "mirror.tscn", room, "UpperMirror", Vector2(cx, RoomKit.FLOOR_Y - 16 - height),
				{"facing": 1, "rotatable": false, "hanging": true, "post_length": RoomKit.FLOOR_Y - 40 - height})
			var receiver := k.inst(RoomKit.PUZZLE + "light_receiver.tscn", room, "Crystal", Vector2(cx + distance, RoomKit.FLOOR_Y - 16 - height), {"accepts_aura": false})
			k.circuit(room, "LightCircuit", [receiver], [gate], {"latch": true, "channel_y": 390.0})
			k.step(room, "The crystal receives reflected light", ObjectiveStep.Condition.OPEN, gate)
			pieces["mirror"] = mirror
		"folded_wall":
			var width := int(params["width"])
			for col in range(x0 + 5, x0 + 5 + width):
				for row in range(RoomKit.LOW_CEIL, 9): k.solid(col, row)
			k.step(room, "The far side reached", ObjectiveStep.Condition.REACHED, null,
				{"area": Rect2((x0 + 5 + width) * 64, 400, (x1 - x0 - 5 - width) * 64, 140)})
			pieces["finish_step"] = room.get_children()[-1]
		"still_piston":
			var piston := DailyPiston.new()
			piston.name = "Piston"
			piston.position = Vector2(cx + 112, 256)
			piston.raised_head_bottom = 190
			piston.travel_distance = 88
			piston.slam_speed = float(params["speed"])
			piston.raised_pause = 3.0
			room.add_child(piston)
			pieces["piston"] = piston
			k.step(room, "The piston is frozen", ObjectiveStep.Condition.POWERED, piston)
			k.step(room, "Past the piston", ObjectiveStep.Condition.REACHED, null, {"area": Rect2(cx + 160, 400, 160, 140)})
			pieces["finish_step"] = room.get_children()[-1]
	k.guide(room, objective)
	var hints := hints_for(params)
	k.hint(room, Vector2(RoomKit.cx(x0 + 1) + 20, RoomKit.FLOOR_Y), hints, [cube, gate])
	if params.get("guided", true): k.waymarks(room, x0, x1)
	for col in [x0 + 2, x1 - 2]: k.torch(room, col)
	pieces["room"] = room
	return pieces

func drive(pieces: Dictionary) -> Dictionary:
	var cube: RuneCube = pieces["cubes"]["Puzzle Cube"]
	match id:
		"frozen_crossing": return {"teleport": Vector2(cube.position.x, RoomKit.FLOOR_Y - 4), "hold": ["move_right", "sprint"]}
		"folded_wall": return {"teleport": Vector2(cube.position.x + 36, RoomKit.FLOOR_Y - 4), "hold": ["move_right"]}
		"still_piston": return {"teleport": cube.position + Vector2(36, -4), "hold": ["move_right"]}
		"dark_hall": return {"teleport": Vector2(RoomKit.cx(int(pieces["x0"]) + 2), RoomKit.FLOOR_Y - 4), "hold": ["move_right", "sprint"]}
		"together": return {"teleport": Vector2(cube.position.x + 36, RoomKit.FLOOR_Y - 4), "hold": ["move_right", "sprint"]}
	return {}

func advance(pieces: Dictionary, player: CharacterBody2D, _elapsed: float) -> void:
	if id == "dark_hall":
		Input.action_release("jump")
		for edge in pieces["gap_edges"]:
			if player.is_on_floor() and player.position.x >= edge - 22 and player.position.x < edge and int(pieces.get("jump_edge", -1)) != edge:
				pieces["jump_edge"] = edge
				Input.action_press("jump")
	if id == "frozen_crossing":
		Input.action_release("jump")
		var cube: RuneCube = pieces["cubes"]["Puzzle Cube"]
		if player.is_on_floor() and player.position.x >= cube.position.x + 208 and not pieces.get("jumped", false):
			pieces["jumped"] = true
			Input.action_press("jump")
	if id == "together" and absf(player.position.x - pieces["plate"].position.x) < 24:
		Input.action_release("move_right")
	if pieces.has("finish_step") and pieces["finish_step"].done:
		pieces["gate"].set_powered(true)


func update_runtime(pieces: Dictionary) -> void:
	if pieces.has("finish_step") and pieces["finish_step"].done:
		pieces["gate"].set_powered(true)
	if pieces.has("barrier") and pieces["barrier"].is_open:
		pieces["gate"].set_powered(true)


func hints_for(params: Dictionary) -> Array:
	match id:
		"frozen_crossing": return [
			"The missing floor interrupts the crossing. The edge cube is flush with the near bank.",
			"Ice can hold a walkable shape. A longer span leaves less gap at the far bank.",
			"Carve Ice, Bridge, Right. Long crosses the whole pit; Normal or Persist needs a running hop from the far end of the ice."]
		"kindling": return [
			"The gold bowls feed the gate's carved channel. Wall torches do not.",
			"A fire projectile reaches a bowl. A fan or blast can catch two bowls together.",
			"Use Fire, Projectile, Up for the hanging bowl, or Right for floor bowls. Split or Explode reaches both bowls."]
		"burn_through":
			if int(params["kind"]) == 1: return [
				"Two heavy stones face the cracked masonry: one has a run-up, one rests beside it.",
				"It needs a heavy impact. A continuous strong wind and a sharp strong gust move the stone differently.",
				"Wind, Push, Right, Strong sends the low stone down its run-up. Wind, Burst, Right, Strong drives the upper stone straight into the wall."]
			return ["Dry brambles seal the passage.", "Fire travels further than a hand and burns what wind cannot move.", "Use Fire, Projectile, Right. A plain bolt burns the barrier; Explode and Split also work."]
		"prism_relay": return [
			"The crystal sits beyond a stone buttress. Two silver faces point towards it.",
			"A plain ray stops at a mirror. Bounce lets the silver face turn it through a right angle.",
			"Carve Light, Beam, Bounce. Right uses the floor mirror; Up uses the hanging mirror. Hop the buttress once the gate opens."]
		"folded_wall": return [
			"The wall reaches from floor to vault. A doorway can have a far side beyond stone.",
			"Space folds a path rather than breaking a wall. The longer fold reaches further.",
			"Use Space, Portal, Right, Normal or Long. Step into the doorway on the cube's right, then walk clear of the far side."]
		"together": return [
			"The flame dies quickly; the plate and bowl must feed the gate at the same time.",
			"A delayed bolt leaves time to stand on the plate. Repeating fire offers another chance.",
			"Carve Fire, Projectile, Right, Delay and run to the plate. Repeat works too; a quick run can meet a plain bolt's flame."]
		"still_piston": return [
			"The raised ram leaves a safe opening, but its next stroke closes it.",
			"Cold reaching the head pauses the ram. Keep it raised while you pass.",
			"Cast Ice, Freeze, Right while the head is raised, then walk underneath. Long, Large and Persist give different coverage or duration."]
		"dark_hall": return [
			"Faint marks show stones across the missing floor near the pillar.",
			"Magical light makes those stones solid. A glow shines on every side rather than in a straight beam.",
			"Carve Light, Glow, Self, Normal or Large on the pillar cube. The revealed stones carry you across; an unlit cube can be moved before casting."]
	return ["Look at the obstacle.", "Follow its carved channel.", "Choose the cube's missing words."]


class VisibleSpan extends Node:
	var stones: Array = []
	func is_powered() -> bool:
		return not stones.is_empty() and stones.all(func(stone): return stone.is_solid)


class BridgeSpan extends Node:
	var cube: RuneCube
	func is_powered() -> bool:
		return is_instance_valid(cube) and cube.is_powered() and cube.recipe.essence == &"ice" and cube.recipe.form == &"bridge"
