extends Control
var can_restart = false

#Run this code once when the DeathScreen loads.
func _ready():
	#Tells game to keep this death-screen script running even when the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_death_screen():
	can_restart = false

	show()

	$FadeToBlack.modulate.a = 0.0
	$Center/MessageBox/YouDiedImage.modulate.a = 0.0
	$Center/MessageBox/RestartPrompt.modulate.a = 0.0

	$Center.show()

	get_tree().paused = true

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Fade screen to black
	tween.tween_property(
		$FadeToBlack,
		"modulate:a",
		1.0,
		1.5
	)

	# Short pause
	tween.tween_interval(0.3)

	# Fade in YOU DIED
	tween.tween_property(
		$Center/MessageBox/YouDiedImage,
		"modulate:a",
		1.0,
		1.0
	)

	# Pause before the restart prompt
	tween.tween_interval(0.6)

	# Fade in SPACEBAR TO START OVER
	tween.tween_property(
		$Center/MessageBox/RestartPrompt,
		"modulate:a",
		1.0,
		0.8
	)

	await tween.finished

	can_restart = true


func _input(event):
	if can_restart and event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed and not event.echo:
			restart_level()


func restart_level():
	can_restart = false
	get_tree().paused = false
	get_tree().reload_current_scene()
