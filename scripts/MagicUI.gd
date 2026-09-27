extends CanvasLayer

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
