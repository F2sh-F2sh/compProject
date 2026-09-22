extends CanvasLayer

@onready var ammo_label = $Control/AmmoCounter
@onready var reload_circle = $Control/ReloadCircle
@onready var reload_label = $Control/ReloadLabel
@onready var fireball_icon: AnimatedSprite2D = $Control/FireballIcon

var previous_ammo := -1

func _ready():
	add_to_group("ammo_ui")

	fireball_icon.play("FireBall")

	# Wizard-themed text
	reload_label.text = "RECHARGING"

func update_display(
	current_ammo: int,
	max_ammo: int,
	reloading: bool,
	progress: float
):
	# Pulse when ammo changes
	if current_ammo != previous_ammo:
		pulse_ammo()
		previous_ammo = current_ammo

	if reloading:

		ammo_label.visible = false

		reload_label.visible = true
		reload_circle.visible = true

		reload_circle.value = progress * 100.0

	else:

		reload_label.visible = false
		reload_circle.visible = false

		ammo_label.visible = true
		ammo_label.text = "MANA\n" + str(current_ammo)

		# Color based on ammo amount
		var percent := float(current_ammo) / float(max_ammo)

		if percent > 0.6:
			ammo_label.modulate = Color.WHITE

		elif percent > 0.3:
			ammo_label.modulate = Color(1.0, 0.65, 0.0) # Orange

		else:
			ammo_label.modulate = Color(1.0, 0.2, 0.2) # Red


func pulse_ammo():

	ammo_label.scale = Vector2.ONE * 1.25

	var tween = create_tween()

	tween.tween_property(
		ammo_label,
		"scale",
		Vector2.ONE,
		0.15
	)
