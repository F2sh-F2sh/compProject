extends SceneTree

## Rendered QA only. Run on an isolated desktop through the local launcher,
## never on the user's interactive desktop. No OS input is synthesised.
var started := false
var out := "user://polish_shots/"

func _process(_delta: float) -> bool:
	if not started:
		started = true
		_run()
	return false

func _run() -> void:
	root.get_node("GameState").persist_to_disk = false
	root.get_node("Settings").persist_to_disk = false
	root.get_node("GameState").calm_creatures = true
	root.get_node("GameState").all_abilities = false
	root.get_node("GameState").clear_all()
	var tours: GDScript = load("res://scripts/ui/ui_tour.gd")
	tours.set("enabled", false)
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for path in ["res://scenes/ui/title_screen.tscn", "res://scenes/story/story_intro.tscn", "res://scenes/story/lowbell.tscn", "res://scenes/story/nan_cottage.tscn", "res://scenes/tutorial/tutorial_movement.tscn", "res://scenes/tutorial/tutorial_level.tscn",
			"res://scenes/chapter/chapter_1.tscn", "res://scenes/chapter/chapter_2.tscn", "res://scenes/chapter/landing.tscn", "res://scenes/chapter/wing_kiln.tscn",
			"res://scenes/chapter/wing_cistern.tscn", "res://scenes/chapter/wing_lamps.tscn", "res://scenes/chapter/wing_galleries.tscn", "res://scenes/chapter/eye.tscn"]:
		if current_scene:
			current_scene.queue_free()
			await process_frame
		var scene: Node = load(path).instantiate()
		root.add_child(scene)
		current_scene = scene
		await create_timer(0.8).timeout
		if path.ends_with("lowbell.tscn"):
			scene._begin_play()
			scene.player.teleport_to(Vector2(580, 534))
			scene.camera.call("snap")
			await create_timer(1.0).timeout
		elif path.ends_with("story_intro.tscn"):
			scene._show_picture(4)
			await create_timer(2.0).timeout
		elif path.ends_with("nan_cottage.tscn"):
			scene._fade.color.a = 0
			scene.intro_camera.position = Vector2(650, 410)
			scene.dialogue.say("nan", "warm", "Take the pilgrim road past my garden. The bellkeepers' well is east of the sealed gate.")
			scene.dialogue.finish_typing()
			await create_timer(0.5).timeout
		else:
			await create_timer(3.5).timeout
		if TitleCard.is_showing():
			TitleCard._current.queue_free()
		await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		if img == null or img.is_empty():
			push_error("Renderer did not produce pixels")
			quit(1)
			return
		var file: String = String(path).get_file().get_basename() + ".png"
		img.save_png(ProjectSettings.globalize_path(out + file))
		print("RENDERED ", file, " ", img.get_size())
		if path.ends_with("nan_cottage.tscn"):
			scene.dialogue.close()
			scene.intro_camera.zoom = Vector2.ONE
			scene.intro_camera.position = Vector2(576, 380)
			await create_timer(0.35).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(out + "cottage_world.png"))
		elif path.ends_with("chapter_1.tscn"):
			var player := scene.get_node("Player")
			var block := scene.get_node("R1/Block")
			player.teleport_to(block.global_position + Vector2(-38, -4))
			await create_timer(0.2).timeout
			Input.action_press("move_right")
			await create_timer(0.35).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(out + "pushing.png"))
			Input.action_release("move_right")
			var sign := scene.get_node("R3/Signs/Mirrors")
			player.teleport_to(sign.global_position + Vector2(0, -4))
			await create_timer(5.5).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(out + "mirror_caption.png"))
	quit()
