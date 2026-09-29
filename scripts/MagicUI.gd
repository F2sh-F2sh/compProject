extends CanvasLayer

<<<<<<< HEAD
@export var fireball_cost := 5
@export var heal_cost := 20

@onready var heal_slot: PanelContainer = %HealSlot
@onready var fire_slot: PanelContainer = %FireSlot


func _ready() -> void:
	add_to_group("ammo_ui")
	for slot in [heal_slot, fire_slot]:
		slot.pivot_offset = slot.size / 2.0
		slot.resized.connect(func(): slot.pivot_offset = slot.size / 2.0)


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
=======
@onready var mana_label: Label = $Control/mana_label
@onready var reload_label: Label = $Control/ReloadLabel
@onready var fireball_icon: AnimatedSprite2D = $Control/FireballIcon
@onready var heal_icon: AnimatedSprite2D = $Control/HealIcon
@onready var mana_bar: ProgressBar = $Control/ManaBar

var previous_mana := -1


func _ready():
	add_to_group("ammo_ui")

	fireball_icon.play("FireBall")
	heal_icon.play("Heal")

	reload_label.text = "RESTORING MANA"
	reload_label.visible = false


func update_display(
	current_mana: int,
	max_mana: int,
	reloading: bool,
	progress: float
):

	mana_bar.max_value = max_mana
	mana_bar.value = current_mana

	# Pulse when mana changes
	if current_mana != previous_mana:
		pulse_mana()
		previous_mana = current_mana

	if reloading:

		mana_label.visible = false
		mana_bar.visible = false

		reload_label.visible = true

	else:

		reload_label.visible = false

		mana_label.visible = true
		mana_bar.visible = true

		mana_label.text = "MANA\n" + str(current_mana)

		var percent := float(current_mana) / float(max_mana)

		# High Mana = Bright Cyan
		if percent > 0.75:

			mana_label.modulate = Color(0.3, 1.0, 1.0)
			mana_bar.modulate = Color(0.3, 1.0, 1.0)

		# Medium Mana = Blue
		elif percent > 0.50:

			mana_label.modulate = Color(0.1, 0.7, 1.0)
			mana_bar.modulate = Color(0.1, 0.7, 1.0)

		# Low Mana = Purple
		elif percent > 0.25:

			mana_label.modulate = Color(0.5, 0.3, 1.0)
			mana_bar.modulate = Color(0.5, 0.3, 1.0)

		# Critical Mana = Pink
		else:

			mana_label.modulate = Color(1.0, 0.15, 0.8)
			mana_bar.modulate = Color(1.0, 0.15, 0.8)


func pulse_mana():

	mana_label.scale = Vector2.ONE * 1.25
	mana_bar.scale = Vector2.ONE * 1.08

	var tween = create_tween()

	tween.parallel().tween_property(
		mana_label,
		"scale",
		Vector2.ONE,
		0.15
	)

	tween.parallel().tween_property(
		mana_bar,
		"scale",
		Vector2.ONE,
		0.15
	)
>>>>>>> ca7ff5e18fa8e215148f3f169007eba690423f12
