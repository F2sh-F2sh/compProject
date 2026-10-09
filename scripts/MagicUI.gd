extends CanvasLayer

@export var fireball_cost := 5
@export var heal_cost := 20

@onready var heal_slot: PanelContainer = %HealSlot
@onready var fire_slot: PanelContainer = %FireSlot


func _ready() -> void:
	add_to_group("ammo_ui")
	_dungeon_skin()
	for slot in [heal_slot, fire_slot]:
		slot.pivot_offset = slot.size / 2.0
		slot.resized.connect(func(): slot.pivot_offset = slot.size / 2.0)
	# A spell's slot appears once she has remembered it
	GameState.flag_changed.connect(_on_flag_changed)
	_show_known_spells()


func _on_flag_changed(_id: String, _value: Variant) -> void:
	_show_known_spells()


func _show_known_spells() -> void:
	heal_slot.visible = GameState.has_ability("heal")
	fire_slot.visible = GameState.has_ability("fire")


func update_display(current_mana: int, reloading: bool) -> void:
	var usable := 0 if reloading else current_mana
	heal_slot.modulate = Color.WHITE if usable >= heal_cost else Color(0.5, 0.5, 0.6, 0.7)
	fire_slot.modulate = Color.WHITE if usable >= fireball_cost else Color(0.5, 0.5, 0.6, 0.7)


## Brightens the heal slot as a heal is channelled (0 when idle).
func set_heal_progress(p: float) -> void:
	heal_slot.self_modulate = Color.WHITE.lerp(Color(1.4, 1.7, 2.1), p)


func flash_spell(spell: String) -> void:
	var slot := fire_slot if spell == "fireball" else heal_slot
	slot.scale = Vector2.ONE * 1.12
	slot.self_modulate = Color(1.8, 1.6, 2.2)
	var tween := create_tween().set_parallel()
	tween.tween_property(slot, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(slot, "self_modulate", Color.WHITE, 0.25)


## The spell slots as small stone frames with gold corners; the key on a gold
## plate, the cost beneath in the UI face.
func _dungeon_skin() -> void:
	for slot in [heal_slot, fire_slot]:
		slot.add_theme_stylebox_override("panel", DungeonUI.style("panel_lite", 8, Vector4(8, 6, 8, 6)))
		for label in slot.find_children("*", "Label", true, false):
			label.add_theme_font_override("font", Fonts.UI)
			label.add_theme_font_size_override("font_size", 8)
			if label.name == "Key":
				label.add_theme_stylebox_override("normal", DungeonUI.style("nameplate", 8, Vector4(6, 1, 6, 1)))
				label.add_theme_color_override("font_color", DungeonUI.INK_DARK)
