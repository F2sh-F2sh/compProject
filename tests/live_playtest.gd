extends SceneTree

## Disposable, in-memory playtest session. Never writes real saves/settings.
## F1 title, F2 village, F3 cottage, F4 road, F5 well, F6 tutorial,
## F7 Belfry, F8 Observatory. These shortcuts exist only in this harness.
var _started := false

func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		root.get_node("GameState").persist_to_disk = false
		root.get_node("GameState").clear_all()
		var settings := root.get_node("Settings")
		settings.persist_to_disk = false
		settings.fullscreen = false
		settings.bindings.clear()
		InputMap.load_from_project_settings()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1152, 648))
		AudioServer.set_bus_mute(0, true)
		root.add_child(SceneShortcuts.new())
		change_scene_to_file("res://scenes/ui/title_screen.tscn")
	return false

class SceneShortcuts extends Node:
	const PATHS := ["ui/title_screen", "story/lowbell", "story/nan_cottage", "story/pilgrims_path", "story/well_descent", "tutorial_level", "chapter/chapter_1", "chapter/chapter_2"]
	func _input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode >= KEY_F1 and event.keycode <= KEY_F8:
			get_viewport().set_input_as_handled()
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/%s.tscn" % PATHS[event.keycode - KEY_F1])
