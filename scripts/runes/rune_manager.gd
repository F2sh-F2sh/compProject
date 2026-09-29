class_name RuneManager
extends Node2D

## The one place that runs the rune cubes of a level:
##  - keeps the list of cubes;
##  - every physics frame (before any object moves) adds up, per object,
##    the force of every active wind field that reaches it (each field once
##    per object per frame; the total is never normalised, so two winds the
##    same way really are twice as strong) and hands it over;
##  - charges mana: the player's own mana (player.current_mana) is the only
##    mana there is. Sustained player-powered runes drain their upkeep from
##    it continuously; if it runs dry, every sustained player-powered rune
##    shuts down at once and stays off (no automatic restart). Mana comes
##    back by itself only while none of them is running;
##  - stops runes when the player leaves a room, before Reset Room, and
##    gives back the mana the player had on entering the room after it;
##  - F3 toggles a debug view of every region, blocked ray and force.
## Dungeon-powered cubes (fed by a pedestal) never touch the player's mana.

signal runes_changed
signal exhausted

## Fragments the player knows from the start of this level.
@export var starting_fragments: PackedStringArray = ["wind", "push", "left", "normal"]

## Seconds after the last upkeep before mana starts coming back, and how fast.
const REGEN_DELAY := 1.2
const REGEN_RATE := 20.0
const LOW_MANA := 15

var cubes: Array[RuneCube] = []
var player: CharacterBody2D
var chapter: ChapterRoot
var carrier: RuneCarrier
var assembly: RuneAssembly
var overview: RuneOverview
var hud: RuneHud
var debug_draw := false
## Mana per second the player is paying right now.
var total_upkeep := 0.0
var _drain := 0.0
var _regen := 0.0
var _since_upkeep := 99.0
var _room_start_mana := -1
## For the debug view: body -> [[field, force], ...] from the last frame.
var contributions := {}
var net_forces := {}
var _wind_sound: AudioStreamPlayer2D


static func get_for(tree: SceneTree) -> RuneManager:
	return tree.get_first_node_in_group("rune_manager") as RuneManager if tree else null


## Whether the player can use this fragment yet.
static func knows(id: StringName, tree: SceneTree = null) -> bool:
	if GameState.has_flag("rune.frag.%s" % id):
		return true
	var manager := get_for(tree) if tree else null
	return manager != null and manager.starting_fragments.has(String(id))


static func learn(id: StringName) -> void:
	GameState.set_flag("rune.frag.%s" % id)


## What wind rays must ignore: the cubes themselves and every loose object
## (walls, gates and the ground block wind; a crate does not shield a stone).
static func wind_ray_exclusions(tree: SceneTree) -> Array[RID]:
	var out: Array[RID] = []
	for node in tree.get_nodes_in_group("rune_cube_body"):
		out.append(node.get_rid())
	for node in tree.get_nodes_in_group("wind_receiver"):
		if node is CollisionObject2D:
			out.append(node.get_rid())
	return out


## An object's box in the world: its own get_bounds(), or its collision shapes.
static func bounds_of(node: Node2D) -> Rect2:
	if node.has_method("get_bounds"):
		return node.get_bounds()
	var box := Rect2()
	var first := true
	for child in node.get_children():
		if child is CollisionShape2D and child.shape and not child.disabled:
			var r: Rect2 = child.global_transform * child.shape.get_rect()
			box = r if first else box.merge(r)
			first = false
	return box if not first else Rect2(node.global_position - Vector2(8, 16), Vector2(16, 16))


func _ready() -> void:
	add_to_group("rune_manager")
	process_physics_priority = -10
	top_level = true
	z_index = 60
	var node := get_parent()
	while node and not node is ChapterRoot:
		node = node.get_parent()
	chapter = node as ChapterRoot
	if chapter:
		chapter.room_entered.connect(_on_room_entered)
		chapter.room_resetting.connect(_on_room_resetting)
		chapter.room_reset_done.connect(_on_room_reset_done)
	assembly = RuneAssembly.new()
	add_child(assembly)
	overview = RuneOverview.new()
	add_child(overview)
	hud = RuneHud.new()
	add_child(hud)
	_find_player.call_deferred()


func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return
	carrier = RuneCarrier.new()
	carrier.name = "RuneCarrier"
	player.add_child(carrier)
	var wind := PlayerWind.new()
	wind.name = "PlayerWind"
	player.add_child(wind)
	if _room_start_mana < 0:
		_room_start_mana = player.current_mana


func register(cube: RuneCube) -> void:
	if not cubes.has(cube):
		cubes.append(cube)


func unregister(cube: RuneCube) -> void:
	cubes.erase(cube)


func active_cubes() -> Array[RuneCube]:
	return cubes.filter(func(c): return c.is_active)


## The cubes in the room the player is in (all cubes outside a chapter).
func room_cubes() -> Array[RuneCube]:
	var room := chapter.current_room if chapter else null
	if room == null:
		return cubes.duplicate()
	return cubes.filter(func(c): return c.is_carried or room.contains(c.global_position + Vector2(0, -8)))


func deactivate_all(reason := "") -> int:
	var n := 0
	for cube in active_cubes():
		cube.deactivate(reason)
		n += 1
	return n


## True while any player-powered rune keeps drawing mana.
func player_upkeep_running() -> bool:
	return cubes.any(func(c): return c.is_active and not c.fed_by_dungeon() and c.upkeep() > 0.0)


# ---------------------------------------------------------------- mana

## The most mana she can hold here (a room's warding circle may lower it).
func mana_cap() -> int:
	var cap: int = player.get_mana_cap() if player else 0
	var room := chapter.current_room if chapter else null
	if room and room.mana_limit > 0:
		cap = mini(cap, room.mana_limit)
	return cap


func mana() -> int:
	return player.current_mana if player else 0


func can_afford(amount: int) -> bool:
	if Settings.assist_infinite_mana:
		return true
	return player != null and player.current_mana >= amount


## Takes mana for a cast or a repeat. False (and nothing taken) if short.
func spend(amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_afford(amount):
		return false
	if not Settings.assist_infinite_mana:
		player.current_mana -= amount
	_since_upkeep = 0.0
	player.update_mana_ui()
	return true


func _update_mana(delta: float) -> void:
	if player == null or player.is_dead:
		return
	total_upkeep = 0.0
	# Any rune she powers (a repeating or timed one too) holds back regeneration
	var drawing := false
	for cube in cubes:
		if cube.is_active and not cube.fed_by_dungeon():
			drawing = true
			total_upkeep += cube.upkeep()
	player.set("reload_locked", drawing)
	# A warding circle holds her mana down (a refill or heal can't beat it)
	if player.current_mana > mana_cap():
		player.current_mana = mana_cap()
		player.update_mana_ui()
	if drawing:
		_since_upkeep = 0.0
		_regen = 0.0
		if Settings.assist_infinite_mana or total_upkeep <= 0.0:
			return
		_drain += total_upkeep * delta
		var whole := int(_drain)
		if whole > 0:
			_drain -= whole
			if player.current_mana >= whole:
				player.current_mana -= whole
				player.update_mana_ui()
			else:
				player.current_mana = 0
				player.update_mana_ui()
				_exhaust()
		return
	_drain = 0.0
	_since_upkeep += delta
	if _since_upkeep < REGEN_DELAY or player.is_reloading or player.current_mana >= mana_cap():
		_regen = 0.0
		return
	_regen += REGEN_RATE * delta
	var gain := int(_regen)
	if gain > 0:
		_regen -= gain
		player.current_mana = mini(player.current_mana + gain, mana_cap())
		player.update_mana_ui()


# Upkeep couldn't be paid: every sustained player-powered rune goes out, once
func _exhaust() -> void:
	var stopped := 0
	for cube in active_cubes():
		if not cube.fed_by_dungeon():
			cube.deactivate("exhausted")
			stopped += 1
	_drain = 0.0
	if stopped > 0:
		Sfx.play("rune_exhaust", null, -4.0, 0.0)
		RuneJournal.note("exhaust")
		_toast("Your mana ran dry. Every rune you were powering went dark.")
		exhausted.emit()


func _toast(text: String, seconds := 4.0) -> void:
	if chapter:
		chapter.show_toast(text, seconds)
	else:
		FloatText.spawn(get_tree().current_scene, player.global_position + Vector2(0, -60) if player else Vector2.ZERO, text, Color("e4ddf2"))


# ---------------------------------------------------------------- forces

func _physics_process(delta: float) -> void:
	if player == null:
		return
	_update_mana(delta)
	_apply_winds()
	if debug_draw:
		queue_redraw()


func _apply_winds() -> void:
	var fields: Array[WindField] = []
	for cube in cubes:
		if cube.is_active and is_instance_valid(cube.effect) and cube.effect is WindField:
			fields.append(cube.effect)
	_update_wind_sound(fields)
	contributions.clear()
	net_forces.clear()
	for body in get_tree().get_nodes_in_group("wind_receiver"):
		# The player takes wind through her PlayerWind component
		var receiver: Node = body if body.has_method("set_wind_force") else body.get_node_or_null("PlayerWind")
		if not body is Node2D or receiver == null:
			continue
		var total := Vector2.ZERO
		if not fields.is_empty():
			var box := bounds_of(body)
			var parts := []
			# One share per field per object per frame, simply added up
			for field in fields:
				var share := field.contribution_for(body, box)
				if share != Vector2.ZERO:
					total += share
					parts.append([field, share])
			if parts.size() >= 2:
				RuneJournal.note("stack")
			if debug_draw and not parts.is_empty():
				contributions[body] = parts
		net_forces[body] = total
		receiver.set_wind_force(total)


# One shared, quiet loop for every running wind (not one per cube): it sits
# at the running wind nearest the player and grows a little with each extra
func _update_wind_sound(fields: Array[WindField]) -> void:
	if fields.is_empty():
		if _wind_sound and _wind_sound.playing:
			_wind_sound.stop()
		return
	if _wind_sound == null:
		var stream := load("res://assets/audio/sfx/wind_loop.wav") as AudioStreamWAV
		if stream == null:
			return
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2
		_wind_sound = AudioStreamPlayer2D.new()
		_wind_sound.stream = stream
		_wind_sound.bus = Settings.SFX_BUS
		_wind_sound.max_distance = 900.0
		add_child(_wind_sound)
	var nearest: WindField = fields[0]
	for f in fields:
		if f.origin().distance_to(player.global_position) < nearest.origin().distance_to(player.global_position):
			nearest = f
	_wind_sound.global_position = nearest.origin() + nearest.direction * nearest.free_reach * 0.5
	_wind_sound.volume_db = minf(-16.0 + 3.0 * (fields.size() - 1), -8.0)
	if not _wind_sound.playing:
		_wind_sound.play()


# ---------------------------------------------------------------- rooms

func _on_room_entered(room: Room) -> void:
	# Runes left running behind stop; so does anything carried out of reach
	for cube in active_cubes():
		if not room.contains(cube.global_position + Vector2(0, -8)) and not cube.is_carried:
			cube.deactivate("left")
	# Each room's cubes belong to it: one carried out goes back home
	if carrier and carrier.held and carrier.held.home_room and carrier.held.home_room != room:
		var cube := carrier.held
		carrier.drop_for_reset()
		cube.reset_state()
		_toast("The cube slips from your hands and drifts back to its room.", 3.0)
	if player:
		_room_start_mana = player.current_mana


func _on_room_resetting(room: Room) -> void:
	if carrier:
		carrier.drop_for_reset()
	if assembly.is_open:
		assembly.close()
	for cube in cubes:
		if room.contains(cube.global_position + Vector2(0, -8)) or cube.is_carried:
			cube.deactivate("reset")


func _on_room_reset_done(_room: Room) -> void:
	if player and _room_start_mana >= 0:
		player.current_mana = mini(maxi(player.current_mana, _room_start_mana), player.get_mana_cap())
		player.update_mana_ui()
	_drain = 0.0


# ---------------------------------------------------------------- debug view

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		debug_draw = not debug_draw
		for cube in cubes:
			cube.queue_redraw()
		queue_redraw()


func _draw() -> void:
	if not debug_draw:
		return
	var font := ThemeDB.fallback_font
	for cube in cubes:
		var region: Dictionary = cube.effect.region() if cube.is_active and is_instance_valid(cube.effect) and cube.effect.has_method("region") else {}
		if not region.is_empty():
			var o: Vector2 = region["origin"]
			var along: Vector2 = region["along"]
			var across: Vector2 = region["across"]
			var h: float = region["width"] / 2.0
			var l: float = region["length"]
			var pts := PackedVector2Array([o - across * h, o - across * h + along * l, o + across * h + along * l, o + across * h, o - across * h])
			draw_polyline(pts, Color(0.5, 0.9, 1.0, 0.8), 1.0)
		var label := "%s%s %s" % ["* " if cube.is_active else "", cube.recipe.to_key(), cube.state_name()]
		draw_string(font, cube.global_position + Vector2(-40, -40), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.9))
	for body in net_forces:
		if not is_instance_valid(body):
			continue
		var box := bounds_of(body)
		draw_rect(box, Color(1, 1, 1, 0.35), false, 1.0)
		var c := box.get_center()
		for part in contributions.get(body, []):
			draw_line(c, c + (part[1] as Vector2) * 0.03, Color(0.5, 0.9, 1.0, 0.7), 1.0)
		var net: Vector2 = net_forces[body]
		if net != Vector2.ZERO:
			draw_line(c, c + net * 0.03, Color(1.0, 0.85, 0.3), 2.0)
		var text := "F %d,%d" % [roundi(net.x), roundi(net.y)]
		if body is WindBody:
			text += "  need %d%s" % [roundi(body.breakaway_force()), "  STRAIN" if body.is_straining else ""]
		draw_string(font, box.position + Vector2(0, -4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 0.9, 0.5))
	if player:
		draw_string(font, player.global_position + Vector2(-50, -70), "upkeep %.1f/s  mana %d" % [total_upkeep, player.current_mana],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.9, 1.0))
