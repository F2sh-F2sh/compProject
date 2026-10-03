@tool
class_name RuneCube
extends Node2D

## A stone cube with one rune carved on its face: a 2x2 composite of four
## fragments (essence top-left, form top-right, direction bottom-left,
## modifier bottom-right). Each cube owns its own recipe, so editing one
## never changes another. Use it (W) to open the assembly screen; pick it up
## and set it down elsewhere with F; switch it on and off from the assembly
## screen or remotely from the rune overview (Tab).
##
## A cube is either dungeon-powered (it sits on a pedestal that feeds it: it
## costs the player nothing) or player-powered (it draws on her mana: start
## costs, upkeep per second, a charge per repeat). The node's origin is the
## bottom-centre of the cube; it is a solid block she can stand on.

signal activated(cube: RuneCube)
signal deactivated(cube: RuneCube)
signal recipe_changed(cube: RuneCube)
signal fired(cube: RuneCube)
## For circuits and objective steps: on while the rune is running.
signal power_changed(powered: bool)

enum State { INACTIVE, ACTIVE, OBSTRUCTED, NO_MANA, INVALID, CARRIED }

const SIZE := 32.0
const STATE_NAMES := ["off", "on", "blocked", "no mana", "broken", "carried"]

## Short name shown in the overview ("East cube").
@export var display_name := "Rune cube"
## The rune it starts with, as "essence/form/direction/modifier" ("-" = a
## broken, empty quadrant).
@export var start_recipe := "wind/push/-/normal":
	set(value):
		start_recipe = value
		recipe = RuneRecipe.from_key(value)
		queue_redraw()
@export var dungeon_powered := false:
	set(value):
		dungeon_powered = value
		queue_redraw()
@export var carryable := true
## Fixed to a wall bracket (never carryable).
@export var mounted := false:
	set(value):
		mounted = value
		queue_redraw()
## Quadrants the player can't change (bits: 1 essence, 2 form, 4 direction,
## 8 modifier).
@export_flags("Essence", "Form", "Direction", "Modifier") var locked_slots := 0
@export var start_active := false

var recipe: RuneRecipe = RuneRecipe.from_key("wind/push/-/normal")
var is_active := false
var is_carried := false
## Highlighted while its assembly screen is open.
var is_selected := false
var spell := {}
## The running effect (a WindField, a light beam...), while on.
var effect: Node
var manager: RuneManager
## The room it belongs to (it can't be carried out of it).
var home_room: Room
## The pedestal it stands on (it then costs the player nothing).
var pedestal: Node
var interactable: Interactable
var body: StaticBody2D
var _collider: CollisionShape2D
var _face: Node2D
var _glow: Sprite2D
var _start_position := Vector2.ZERO
var _flash_state := -1
var _flash_time := 0.0
var _delay_left := 0.0
var _timed_left := 0.0
var _repeat_left := 0.0
var _time := 0.0


func _ready() -> void:
	recipe = RuneRecipe.from_key(start_recipe)
	body = StaticBody2D.new()
	body.name = "Body"
	_collider = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(SIZE, SIZE)
	_collider.shape = shape
	_collider.position = Vector2(0, -SIZE / 2.0)
	body.add_child(_collider)
	add_child(body)
	_face = Node2D.new()
	_face.name = "Face"
	_face.material = MagicLight.unshaded()
	_face.z_index = 1
	_face.draw.connect(_draw_face)
	add_child(_face)
	if Engine.is_editor_hint():
		return
	# Solid ground (2) that fireballs splash on too (1)
	body.collision_layer = 3
	body.collision_mask = 0
	body.add_to_group("rune_cube_body")
	body.add_to_group("world")
	body.set_meta("rune_cube", self)
	add_to_group("rune_cube")
	add_to_group("resettable")
	_glow = Sprite2D.new()
	_glow.texture = preload("res://assets/fx/soft_glow.png")
	_glow.position = Vector2(0, -SIZE / 2.0)
	_glow.scale = Vector2(0.9, 0.9)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_glow.material = add
	_glow.modulate.a = 0.0
	_glow.z_index = -1
	add_child(_glow)
	interactable = Interactable.new()
	interactable.verb = "Inscribe"
	interactable.use_priority = 1
	interactable.size = Vector2(60, 52)
	interactable.prompt_offset = Vector2(0, -52)
	interactable.echo_can_use = false
	add_child(interactable)
	interactable.interacted.connect(_on_interacted)
	interactable.body_entered.connect(_on_reached)
	_start_position = global_position
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	home_room = node as Room
	_register.call_deferred()


func _register() -> void:
	manager = RuneManager.get_for(get_tree())
	if manager == null:
		# Any scene with a cube gets a manager
		manager = RuneManager.new()
		manager.name = "RuneManager"
		get_tree().current_scene.add_child(manager)
	manager.register(self)
	_find_pedestal()
	if start_active:
		activate(false)


func _exit_tree() -> void:
	if manager and not Engine.is_editor_hint():
		manager.unregister(self)


# ---------------------------------------------------------------- queries

func centre() -> Vector2:
	return global_position + Vector2(0, -SIZE / 2.0)


## The middle of the face the effect leaves from (a corner for diagonals).
func get_face_point(direction: Vector2) -> Vector2:
	return centre() + Vector2(signf(snappedf(direction.x, 0.01)), signf(snappedf(direction.y, 0.01))) * SIZE / 2.0


func is_slot_locked(kind: int) -> bool:
	return locked_slots & (1 << kind) != 0


func state() -> int:
	if _flash_time > 0.0:
		return _flash_state
	if is_carried:
		return State.CARRIED
	if is_active:
		if is_instance_valid(effect) and effect.has_method("is_obstructed") and effect.is_obstructed():
			return State.OBSTRUCTED
		return State.ACTIVE
	if not recipe.is_complete():
		return State.INVALID
	return State.INACTIVE


func is_powered() -> bool:
	return is_active


## Paid for by the dungeon (built that way, or standing on a pedestal)
## rather than by the player's mana.
func fed_by_dungeon() -> bool:
	return dungeon_powered or pedestal != null


## Finds the pedestal it stands on, if any.
func _find_pedestal() -> void:
	pedestal = null
	if Engine.is_editor_hint() or is_carried:
		return
	for node in get_tree().get_nodes_in_group("rune_pedestal"):
		if node.holds(global_position):
			pedestal = node
			return


func state_name() -> String:
	return STATE_NAMES[state()]


## Mana per second while on (0 for dungeon-powered cubes, once-off spells and
## during a delay).
func upkeep() -> float:
	if not is_active or fed_by_dungeon() or spell.is_empty():
		return 0.0
	return float(spell.get("upkeep", 0.0))


## Can the player change the rune right now?
func can_edit() -> bool:
	return not is_active and not is_carried


func set_slot(kind: int, id: StringName) -> void:
	if not can_edit() or is_slot_locked(kind):
		return
	recipe.set_slot(kind, id)
	queue_redraw()
	_face.queue_redraw()
	recipe_changed.emit(self)


func description() -> Dictionary:
	return RuneBook.describe(recipe, fed_by_dungeon())


# ---------------------------------------------------------------- on / off

## Switches the rune on. Returns "" on success, otherwise why not (nothing
## is charged when it fails).
func activate(by_player := true) -> String:
	if is_active:
		return ""
	if is_carried:
		return "Set the cube down first."
	var why := RuneBook.problem(recipe)
	if why != "":
		_flash(State.INVALID)
		if by_player:
			Sfx.play("rune_blocked", centre(), -4.0)
		return why
	var s := RuneBook.spell(recipe)
	if not RuneEffects.is_built(s["key"]):
		return "This rune's magic is beyond you for now."
	var blocked := RuneEffects.problem(self, s)
	if blocked != "":
		_flash(State.OBSTRUCTED)
		if by_player:
			Sfx.play("rune_blocked", centre(), -4.0)
		return blocked
	# Enough for the cast plus two seconds of upkeep; Delay pays when it fires
	var needed: int = 0 if s["delay"] > 0.0 else int(s["start_cost"])
	if s["kind"] == RuneBook.Kind.SUSTAINED:
		needed += ceili(s["upkeep"] * RuneBook.START_SECONDS)
	if not fed_by_dungeon() and manager and not manager.can_afford(needed):
		_flash(State.NO_MANA)
		if by_player:
			Sfx.play("rune_blocked", centre(), -4.0)
		return "Not enough mana: this rune needs %d to start." % needed
	spell = s
	is_active = true
	if s["delay"] <= 0.0:
		if not _pay(int(s["start_cost"])):
			is_active = false
			return "Not enough mana."
		_start_effect()
	else:
		_delay_left = s["delay"]
	Sfx.play("rune_activate", centre(), -3.0)
	RuneJournal.note_cast(recipe)
	if not fed_by_dungeon():
		RuneJournal.note("mana")
	_glow.modulate = RuneFragments.essence_color(recipe.essence)
	queue_redraw()
	_refresh_verb()
	activated.emit(self)
	power_changed.emit(true)
	if manager:
		manager.runes_changed.emit()
	return ""


func deactivate(reason := "") -> void:
	if not is_active:
		return
	is_active = false
	_delay_left = 0.0
	_timed_left = 0.0
	_repeat_left = 0.0
	_stop_effect()
	if reason != "reset" and reason != "left":
		Sfx.play("rune_deactivate", centre(), -6.0 if reason == "" else -3.0)
	if reason == "exhausted":
		_flash(State.NO_MANA, 1.5)
	queue_redraw()
	_refresh_verb()
	deactivated.emit(self)
	power_changed.emit(false)
	if manager:
		manager.runes_changed.emit()


func toggle() -> String:
	if is_active:
		deactivate()
		return ""
	return activate()


func _pay(amount: int) -> bool:
	if fed_by_dungeon() or manager == null:
		return true
	return manager.spend(amount)


func _start_effect() -> void:
	_stop_effect()
	effect = RuneEffects.create(self, spell)
	match spell["kind"]:
		RuneBook.Kind.TIMED:
			_timed_left = spell["duration"]
		RuneBook.Kind.REPEAT:
			_repeat_left = spell["repeat_every"]
		RuneBook.Kind.ONCE:
			# A single effect: the cube is free again once it has fired
			fired.emit(self)
			_finish_once.call_deferred()
	if spell["kind"] != RuneBook.Kind.ONCE:
		fired.emit(self)


func _finish_once() -> void:
	if is_active and spell.get("kind") == RuneBook.Kind.ONCE:
		is_active = false
		# The effect (a gust, a bolt) plays out on its own
		effect = null
		queue_redraw()
		_refresh_verb()
		deactivated.emit(self)
		power_changed.emit(false)
		if manager:
			manager.runes_changed.emit()


func _stop_effect() -> void:
	if is_instance_valid(effect):
		if effect.has_method("stop"):
			effect.stop()
		else:
			effect.queue_free()
	effect = null


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_flash_time = maxf(_flash_time - delta, 0.0)
	if is_active:
		if _delay_left > 0.0:
			_delay_left -= delta
			if _delay_left <= 0.0:
				if _pay(int(spell["start_cost"])):
					_start_effect()
				else:
					deactivate("exhausted")
		elif _timed_left > 0.0:
			_timed_left -= delta
			if _timed_left <= 0.0:
				deactivate("timed")
		elif spell.get("kind") == RuneBook.Kind.REPEAT:
			_repeat_left -= delta
			if _repeat_left <= 0.0:
				_repeat_left = spell["repeat_every"]
				if _pay(int(spell["repeat_cost"])):
					_stop_effect()
					effect = RuneEffects.create(self, spell)
					fired.emit(self)
				else:
					deactivate("exhausted")
	if is_carried:
		return
	var target := 0.55 + sin(_time * 3.0) * 0.12 if is_active else 0.0
	_glow.modulate.a = move_toward(_glow.modulate.a, target, delta * 2.0)
	_face.queue_redraw()


# ---------------------------------------------------------------- carrying

func pick_up() -> void:
	is_carried = true
	pedestal = null
	_collider.set_deferred("disabled", true)
	interactable.enabled = false
	z_index = 5
	queue_redraw()


func put_down(at: Vector2) -> void:
	global_position = at
	is_carried = false
	_collider.set_deferred("disabled", false)
	interactable.enabled = true
	z_index = 0
	reset_physics_interpolation()
	queue_redraw()
	_find_pedestal()
	if pedestal:
		Sfx.play("rune_socket", centre(), -4.0)
		RuneJournal.note("pedestal")
	Sfx.play("rune_place", centre(), -4.0)


func reset_state() -> void:
	deactivate("reset")
	is_carried = false
	_collider.set_deferred("disabled", false)
	interactable.enabled = true
	z_index = 0
	global_position = _start_position
	recipe = RuneRecipe.from_key(start_recipe)
	reset_physics_interpolation()
	queue_redraw()
	_find_pedestal()
	recipe_changed.emit(self)
	if start_active:
		activate.call_deferred(false)


func _flash(s: int, seconds := 1.0) -> void:
	_flash_state = s
	_flash_time = seconds


func _on_interacted(_by: Node) -> void:
	if manager and manager.assembly:
		manager.assembly.open(self)


# The first time she reaches any rune cube (wherever she came in), the rune
# tour explains how cubes are edited: Inscribe, words change only while the
# cube is off, LOCKED words never, and the runes list on its key. Once per save.
func _on_reached(body: Node) -> void:
	if body.is_in_group("player") and not GameState.has_flag("ui.tour.runes") and not is_instance_valid(UiTour.current):
		UiTour.play_later(self, "runes", 0.6)


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var h := SIZE / 2.0
	var top := -SIZE
	if mounted:
		# An iron bracket behind the cube
		draw_rect(Rect2(-h - 4, top + 6, SIZE + 8, 4), Color("2a2438"))
		draw_rect(Rect2(-h - 4, top + SIZE - 10, SIZE + 8, 4), Color("2a2438"))
	# Weathered stone block
	draw_rect(Rect2(-h, top, SIZE, SIZE), Color("16121f"))
	draw_rect(Rect2(-h + 1, top + 1, SIZE - 2, SIZE - 2), Color("3a3350"))
	draw_rect(Rect2(-h + 1, top + 1, SIZE - 2, 2), Color("514870"))
	draw_rect(Rect2(-h + 3, top + 3, SIZE - 6, SIZE - 6), Color("241f33"))
	if fed_by_dungeon():
		# A carved channel from the floor: the dungeon feeds this one
		draw_rect(Rect2(-h - 3, -3, SIZE + 6, 3), Color("2c2544"))
		draw_rect(Rect2(-2, -3, 4, 3), Color("6d56b8"))


func _draw_face() -> void:
	var h := SIZE / 2.0
	var top := -SIZE
	var s := state()
	var base := RuneFragments.essence_color(recipe.essence)
	var lit := is_active and _delay_left <= 0.0
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	var rim := Color(0.55, 0.45, 0.8, 0.35)
	match s:
		State.ACTIVE: rim = Color(base, 0.55 + 0.3 * pulse)
		State.OBSTRUCTED: rim = Color(1.0, 0.7, 0.25, 0.5 + 0.5 * pulse)
		State.NO_MANA: rim = Color(1.0, 0.3, 0.3, 0.9 if int(_time * 8.0) % 2 == 0 else 0.3)
		State.INVALID: rim = Color(1.0, 0.35, 0.35, 0.55)
		State.CARRIED: rim = Color(0.9, 0.85, 1.0, 0.6)
	if is_selected:
		rim = Color(1, 1, 1, 0.9)
	_face.draw_rect(Rect2(-h + 0.5, top + 0.5, SIZE - 1, SIZE - 1), rim, false, 1.0)
	# The four quadrants of the composite
	var cell := 12.0
	var origins := [Vector2(-h + 3, top + 3), Vector2(1, top + 3), Vector2(-h + 3, top + 17), Vector2(1, top + 17)]
	for kind in 4:
		var id := recipe.get_slot(kind)
		var o: Vector2 = origins[kind]
		var c := o + Vector2(cell / 2.0, cell / 2.0)
		var col := base if kind == RuneFragments.Kind.ESSENCE else RuneFragments.NEUTRAL
		col.a = 0.95 if lit else 0.55
		if id == &"":
			col = Color(1.0, 0.4, 0.4, 0.8)
		RuneFragments.draw_glyph(_face, id, c, cell, col, 1.0)
		if is_slot_locked(kind):
			_face.draw_rect(Rect2(o.x + cell - 3, o.y, 3, 3), Color(0.7, 0.65, 0.85, 0.7))
	if fed_by_dungeon():
		_face.draw_rect(Rect2(-2, -3, 4, 3), Color(0.6, 0.5, 1.0, 0.5 + 0.4 * pulse if lit else 0.35))
	# Delay: a draining ring. Timed: a shrinking bar
	if is_active and _delay_left > 0.0:
		var t := _delay_left / maxf(spell.get("delay", 1.0), 0.01)
		_face.draw_arc(centre() - global_position, h + 5, -PI / 2, -PI / 2 + TAU * t, 20, Color(base, 0.9), 2.0)
	elif is_active and _timed_left > 0.0:
		var t2 := _timed_left / maxf(spell.get("duration", 1.0), 0.01)
		_face.draw_rect(Rect2(-h, 3, SIZE * t2, 2), Color(base, 0.9))
	if manager and manager.debug_draw:
		_face.draw_string(ThemeDB.fallback_font, Vector2(-h, top - 4), state_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if _face:
			_face.queue_redraw()
		return
	if is_carried:
		_face.queue_redraw()


## The prompt says what using the cube will do: inscribe it, or (while it
## runs) look at it and switch it off first.
func _refresh_verb() -> void:
	if interactable:
		interactable.verb = "Running: switch off to edit" if is_active else "Inscribe"
