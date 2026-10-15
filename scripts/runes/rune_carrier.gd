class_name RuneCarrier
extends Node2D

## Lets Echidna pick up a rune cube (F), carry it over her head and set it
## down again. While she carries one, a ghost shows where it would land, in
## white where it can go and in red, with the reason, where it can't; if its
## rune is complete the ghost also marks the area the rune would cover.
## Added to the player by the RuneManager.

const FONT := Fonts.UI
const PICK_RANGE := 46.0
## How far ahead of her feet the cube's centre lands.
const PLACE_AHEAD := 30.0
const HOLD_OFFSET := Vector2(0, -44)

var held: RuneCube
var player: CharacterBody2D
var target := Vector2.ZERO
var valid := false
var reason := ""
var _ghost: Node2D
var _preview: PackedVector2Array = []


func _ready() -> void:
	player = get_parent() as CharacterBody2D
	_ghost = Node2D.new()
	_ghost.top_level = true
	_ghost.z_index = 30
	_ghost.material = MagicLight.unshaded()
	_ghost.draw.connect(_draw_ghost)
	add_child(_ghost)


func _physics_process(_delta: float) -> void:
	if held and not is_instance_valid(held):
		held = null
	if held and not held.is_carried:
		# Put back by a room reset
		held = null
	if held:
		held.global_position = player.global_position + HOLD_OFFSET
		_update_target()
	_ghost.visible = held != null
	_ghost.queue_redraw()
	if player.is_dead or player.controls_locked or get_tree().paused:
		return
	if Input.is_action_just_pressed("rune_carry"):
		if held:
			try_place()
		else:
			try_pick_up()


func facing() -> float:
	var sprite: AnimatedSprite2D = player.get("animated_sprite")
	return -1.0 if sprite and sprite.flip_h else 1.0


## The cube she would pick up now, if any.
func nearest_cube() -> RuneCube:
	var best: RuneCube = null
	var best_d := PICK_RANGE
	var me := player.global_position + Vector2(0, -16)
	for node in get_tree().get_nodes_in_group("rune_cube"):
		var cube := node as RuneCube
		if cube == null or cube.is_carried:
			continue
		var d := cube.centre().distance_to(me)
		# Prefer the one she faces
		if signf(cube.centre().x - me.x) != facing():
			d += 12.0
		if d < best_d:
			var ray := PhysicsRayQueryParameters2D.create(me, cube.centre(), 2, [player.get_rid(), cube.body.get_rid()])
			if not player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
				continue
			best_d = d
			best = cube
	return best


## Picks up the nearest cube. Returns "" or why not.
func try_pick_up() -> String:
	var cube := nearest_cube()
	if cube == null:
		return "nothing"
	var why := ""
	if cube.mounted or not cube.carryable:
		why = "This cube is fixed in place."
	elif cube.is_active and not (bool(cube.get_meta(&"daily_portal_carry", false))
			and is_instance_valid(cube.effect) and cube.effect is RunePortal):
		why = "Switch the cube off before you move it."
	if why != "":
		_say(cube.centre() + Vector2(0, -30), why, true)
		return why
	held = cube
	cube.pick_up()
	Sfx.play("rune_select", cube.centre(), -5.0)
	_update_target()
	return ""


## Sets the held cube down at the ghost. Returns "" or why not.
func try_place() -> String:
	if held == null:
		return "nothing"
	_update_target()
	if not valid:
		_say(target + Vector2(0, -44), reason, true)
		return reason
	var cube := held
	held = null
	cube.put_down(target)
	return ""


func drop_for_reset() -> void:
	held = null


func _say(at: Vector2, text: String, blocked: bool) -> void:
	FloatText.spawn(player.get_parent(), at, text, Color(1.0, 0.62, 0.55) if blocked else Color(0.85, 0.78, 1.0), 20.0, 1.6)
	if blocked:
		Sfx.play("rune_blocked", at, -6.0)


# Where the cube would land and whether it may
func _update_target() -> void:
	var space := player.get_world_2d().direct_space_state
	var x := snappedf(player.global_position.x + facing() * PLACE_AHEAD, 2.0)
	var feet := player.global_position.y
	var exclude: Array[RID] = [held.body.get_rid(), player.get_rid()]
	var down := PhysicsRayQueryParameters2D.create(Vector2(x, feet - 24.0), Vector2(x, feet + 72.0), 2, exclude)
	var hit := space.intersect_ray(down)
	_preview = []
	if hit.is_empty():
		target = Vector2(x, feet)
		_verdict(false, "It needs solid ground under it.")
		return
	target = hit["position"]
	# A pedestal close by takes the cube into its socket
	for pedestal in get_tree().get_nodes_in_group("rune_pedestal"):
		target = pedestal.snap(target)
	if hit["collider"] is WindBody:
		_verdict(false, "Not on something that can move.")
		return
	if hit["normal"].y > -0.7:
		_verdict(false, "Too steep to stand it there.")
		return
	# Room for the whole cube (a hair smaller, so it can sit flush)
	var box := RectangleShape2D.new()
	box.size = Vector2(RuneCube.SIZE - 2.0, RuneCube.SIZE - 2.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = box
	query.transform = Transform2D(0.0, target + Vector2(0, -RuneCube.SIZE / 2.0 - 1.0))
	query.collision_mask = 2
	query.exclude = exclude
	if not space.intersect_shape(query, 1).is_empty():
		_verdict(false, "There isn't room for it there.")
		return
	var rect := Rect2(target - Vector2(RuneCube.SIZE / 2.0, RuneCube.SIZE), Vector2(RuneCube.SIZE, RuneCube.SIZE))
	# Not on top of her
	if rect.grow(-2.0).intersects(RuneManager.bounds_of(player)):
		_verdict(false, "Step back a little.")
		return
	var room: Room = held.manager.chapter.current_room if held.manager and held.manager.chapter else null
	if room and not room.bounds.encloses(rect):
		_verdict(false, "Keep it inside this room.")
		return
	for hazard in get_tree().get_nodes_in_group("hazard_zone"):
		if hazard.has_method("get_hazard_rect") and hazard.get_hazard_rect().intersects(rect):
			_verdict(false, "Not on a hazard.")
			return
	for zone in get_tree().get_nodes_in_group("no_rune_zone"):
		if zone.has_method("get_rect") and zone.get_rect().intersects(rect):
			_verdict(false, "The stone here refuses runes.")
			return
	var eye := player.global_position + Vector2(0, -20)
	var los := PhysicsRayQueryParameters2D.create(eye, target + Vector2(0, -RuneCube.SIZE / 2.0), 2, exclude)
	if not space.intersect_ray(los).is_empty():
		_verdict(false, "You can't reach there.")
		return
	_verdict(true, "")
	_preview = _region_preview()


func _verdict(ok: bool, why: String) -> void:
	valid = ok
	reason = why


# The area the cube's rune would cover from the ghost's spot
func _region_preview() -> PackedVector2Array:
	if held == null or not RuneBook.is_valid(held.recipe):
		return []
	var s := RuneBook.spell(held.recipe)
	if not s.has("reach") or not s.has("width") or s["direction"] == Vector2.ZERO:
		return []
	var dir: Vector2 = (s["direction"] as Vector2).normalized()
	var centre := target + Vector2(0, -RuneCube.SIZE / 2.0)
	var o := centre + Vector2(signf(snappedf(dir.x, 0.01)), signf(snappedf(dir.y, 0.01))) * RuneCube.SIZE / 2.0
	var reach: float = s["reach"]
	var exclude := RuneManager.wind_ray_exclusions(get_tree())
	var hit := player.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(o, o + dir * reach, 2, exclude))
	if not hit.is_empty():
		reach = o.distance_to(hit["position"])
	var across := dir.orthogonal() * float(s["width"]) / 2.0
	return PackedVector2Array([o - across, o - across + dir * reach, o + across + dir * reach, o + across, o - across])


func _draw_ghost() -> void:
	if held == null:
		return
	var col := Color(0.9, 0.95, 1.0, 0.75) if valid else Color(1.0, 0.35, 0.3, 0.8)
	var rect := Rect2(target - Vector2(RuneCube.SIZE / 2.0, RuneCube.SIZE), Vector2(RuneCube.SIZE, RuneCube.SIZE))
	_ghost.draw_rect(rect, Color(col, 0.12))
	_ghost.draw_rect(rect, col, false, 1.0)
	if not valid:
		_ghost.draw_line(rect.position + Vector2(6, 6), rect.end - Vector2(6, 6), col, 2.0)
		_ghost.draw_line(Vector2(rect.end.x - 6, rect.position.y + 6), Vector2(rect.position.x + 6, rect.end.y - 6), col, 2.0)
		# Why not, right above the ghost
		_ghost.draw_string(FONT, Vector2(rect.get_center().x - 90.0, rect.position.y - 6.0), reason,
			HORIZONTAL_ALIGNMENT_CENTER, 180.0, 8, col)
	elif _preview.size() > 1:
		var wind := RuneFragments.essence_color(held.recipe.essence)
		for i in _preview.size() - 1:
			var a := _preview[i]
			var b := _preview[i + 1]
			var n := maxi(int(a.distance_to(b) / 8.0), 1)
			for k in n:
				if k % 2 == 0:
					_ghost.draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), Color(wind, 0.5), 1.0)
