extends Node

## Persistent progress that survives deaths and restarts: completed puzzles,
## unlocked shortcuts, collected pages and the last full checkpoint.
## Everything is keyed by stable ids set in the Inspector, never by node paths.

signal flag_changed(id: String, value: Variant)

const SAVE_PATH := "user://savegame.cfg"

var flags := {}
var checkpoint_scene := ""
var checkpoint_id := ""
## Tests turn this off so they never touch a real save file.
var persist_to_disk := true


func _ready() -> void:
	load_game()


func has_flag(id: String) -> bool:
	return id != "" and flags.get(id, false) == true


func get_flag(id: String, default: Variant = null) -> Variant:
	return flags.get(id, default)


func set_flag(id: String, value: Variant = true) -> void:
	if id == "" or flags.get(id) == value:
		return
	flags[id] = value
	flag_changed.emit(id, value)
	save_game()


func count_flags(prefix: String) -> int:
	var count := 0
	for id in flags:
		if String(id).begins_with(prefix) and flags[id] == true:
			count += 1
	return count


func set_checkpoint(scene_path: String, id: String) -> void:
	if checkpoint_scene == scene_path and checkpoint_id == id:
		return
	checkpoint_scene = scene_path
	checkpoint_id = id
	save_game()


## The checkpoint id to respawn at in this scene, or "" to use the level start.
func get_checkpoint_for(scene_path: String) -> String:
	return checkpoint_id if checkpoint_scene == scene_path else ""


## Forgets all progress made in one scene (flags are prefixed with a scene key).
func clear_progress(prefix: String) -> void:
	for id in flags.keys():
		if String(id).begins_with(prefix):
			flags.erase(id)
	if checkpoint_id.begins_with(prefix):
		checkpoint_scene = ""
		checkpoint_id = ""
	save_game()


func clear_all() -> void:
	flags.clear()
	checkpoint_scene = ""
	checkpoint_id = ""
	save_game()


func save_game() -> void:
	if not persist_to_disk:
		return
	var file := ConfigFile.new()
	file.set_value("progress", "flags", flags)
	file.set_value("progress", "checkpoint_scene", checkpoint_scene)
	file.set_value("progress", "checkpoint_id", checkpoint_id)
	file.save(SAVE_PATH)


func load_game() -> void:
	if not persist_to_disk:
		return
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return
	flags = file.get_value("progress", "flags", {})
	checkpoint_scene = file.get_value("progress", "checkpoint_scene", "")
	checkpoint_id = file.get_value("progress", "checkpoint_id", "")
