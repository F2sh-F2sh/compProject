class_name SceneFade
extends CanvasLayer

## A short fade through black between scenes, so nothing cuts hard: the old
## scene fades out, the new one is loaded behind black, then fades in.
##   SceneFade.change(tree, path)      fade out, change scene, fade in
##   SceneFade.change(tree, path, 0.0) the scene has already faded itself to
##                                     black: change at once, then fade in
##   SceneFade.restart(tree)           the same for restarting the scene
## It lives on the tree's root, so it outlasts the scene change, works while the
## game is paused and frees itself when done. While it fades out it swallows
## clicks and ignores a second request (no double loads from a double press);
## once the change is made the new scene is live and may change again at once.

const OUT_TIME := 0.3
const IN_TIME := 0.45

static var _active: SceneFade

var _rect: ColorRect


static func change(tree: SceneTree, path: String, out_time := OUT_TIME) -> void:
	_begin(tree, path, out_time)


static func restart(tree: SceneTree, out_time := OUT_TIME) -> void:
	_begin(tree, "", out_time)


## True while a fade is running (a scene change is on its way).
static func busy() -> bool:
	return is_instance_valid(_active)


static func _begin(tree: SceneTree, path: String, out_time: float) -> void:
	if busy():
		return
	var fade := SceneFade.new()
	_active = fade
	tree.root.add_child(fade)
	fade._run(path, out_time)


func _init() -> void:
	name = "SceneFade"
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_rect)


func _run(path: String, out_time: float) -> void:
	if out_time > 0.0:
		var out := create_tween()
		out.tween_property(_rect, "color:a", 1.0, out_time).set_trans(Tween.TRANS_SINE)
		await out.finished
	else:
		_rect.color.a = 1.0
	if path == "":
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(path)
	# The change is on its way: the new scene may ask for the next one at once,
	# and is clickable while it fades in
	_active = null
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# (the new scene arrives on the next frame; give it one more to settle)
	await get_tree().process_frame
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_rect, "color:a", 0.0, IN_TIME).set_trans(Tween.TRANS_SINE)
	await back.finished
	queue_free()
