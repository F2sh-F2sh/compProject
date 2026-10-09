extends Node

## Persistent progress that survives deaths and restarts: completed puzzles,
## unlocked shortcuts, collected pages and the last full checkpoint.
## Everything is keyed by stable ids set in the Inspector, never by node paths.

signal flag_changed(id: String, value: Variant)

const SAVE_PATH := "user://savegame.cfg"

var flags := {}
## The most recent checkpoint anywhere (where "Continue" goes).
var checkpoint_scene := ""
var checkpoint_id := ""
## The last checkpoint reached in each scene, so the tutorial's lessons and
## the chapter's shrines never overwrite each other.
var checkpoints := {}
## Counters for this play session only (never saved): deaths per room, etc.
var session := {}
## Tests turn this off so they never touch a real save file.
var persist_to_disk := true


func _ready() -> void:
	_migrate_old_user_dir()
	load_game()


## The game was renamed from "compProject", which moved its user folder:
## bring the old save and settings across once, so nobody loses progress.
func _migrate_old_user_dir() -> void:
	var here := OS.get_user_data_dir()
	var old := here.get_base_dir().path_join("compProject")
	if old == here or not DirAccess.dir_exists_absolute(old):
		return
	for file_name in ["savegame.cfg", "settings.cfg"]:
		var from := old.path_join(file_name)
		var to := here.path_join(file_name)
		if FileAccess.file_exists(from) and not FileAccess.file_exists(to):
			DirAccess.copy_absolute(from, to)


## Flags share the store with run statistics (numbers, see add_stat), so only
## a true boolean counts as set.
func has_flag(id: String) -> bool:
	var value = flags.get(id, false)
	return id != "" and value is bool and value


func get_flag(id: String, default: Variant = null) -> Variant:
	return flags.get(id, default)


func set_flag(id: String, value: Variant = true) -> void:
	var old = flags.get(id)
	if id == "" or (typeof(old) == typeof(value) and old == value):
		return
	flags[id] = value
	_earlier = -1
	flag_changed.emit(id, value)
	save_game()


func count_flags(prefix: String) -> int:
	var count := 0
	for id in flags:
		var value = flags[id]
		if String(id).begins_with(prefix) and value is bool and value:
			count += 1
	return count


# ------------------------------------------------------------------ abilities
# Echidna's three family spells were taken by the Hush: she remembers them one
# at a time on the Novices' Way (see AbilityShrine). Each is a saved flag,
# "ability.fire", "ability.heal" and "ability.echo".

const ABILITIES := ["fire", "heal", "echo"]
## Tests turn this on so they can use every spell from the first frame.
var all_abilities := false
## Tests turn this on: the roaming creatures (CreatureSpawner) stay away, so
## the scripted puzzle routes are not chased about. Their own tests turn it off.
var calm_creatures := false
var _earlier := -1


## Whether Echidna has this spell. A save from before spells had to be earned
## (the tutorial or a chapter already played) has them all.
func has_ability(id: String) -> bool:
	return id in ABILITIES and (all_abilities or has_flag("ability." + id))


func grant_ability(id: String) -> void:
	if id not in ABILITIES:
		return
	set_flag("ability." + id)


func grant_all_abilities() -> void:
	for id in ABILITIES:
		grant_ability(id)


func _has_earlier_progress() -> bool:
	if _earlier == -1:
		_earlier = 1 if (count_flags("ability.") == 0 and (has_flag("tutorial.done") or count_flags("ch1.") > 0 or count_flags("ch2.") > 0)) else 0
	return _earlier == 1


func set_checkpoint(scene_path: String, id: String) -> void:
	if checkpoint_scene == scene_path and checkpoint_id == id and checkpoints.get(scene_path) == id:
		return
	checkpoint_scene = scene_path
	checkpoint_id = id
	checkpoints[scene_path] = id
	save_game()


## The checkpoint id to respawn at in this scene, or "" to use the level start.
func get_checkpoint_for(scene_path: String) -> String:
	return checkpoints.get(scene_path, "")


## Forgets a scene's checkpoint (e.g. once the tutorial is finished).
func clear_checkpoint(scene_path: String) -> void:
	checkpoints.erase(scene_path)
	if checkpoint_scene == scene_path:
		checkpoint_scene = ""
		checkpoint_id = ""
	save_game()


## Forgets all progress made in one scene (flags are prefixed with a scene key).
func clear_progress(prefix: String) -> void:
	_earlier = -1
	for id in flags.keys():
		if String(id).begins_with(prefix):
			flags.erase(id)
	for scene_path in checkpoints.keys():
		if String(checkpoints[scene_path]).begins_with(prefix):
			checkpoints.erase(scene_path)
	if checkpoint_id.begins_with(prefix):
		checkpoint_scene = ""
		checkpoint_id = ""
	save_game()


func clear_all() -> void:
	flags.clear()
	_earlier = -1
	checkpoints.clear()
	session.clear()
	checkpoint_scene = ""
	checkpoint_id = ""
	save_game()


## Adds to a session counter (not saved), e.g. deaths in a room.
func bump(key: String, amount := 1) -> int:
	session[key] = int(session.get(key, 0)) + amount
	return session[key]


## Run statistics (time, deaths, resets, hints), kept with the progress
## under the chapter's prefix, e.g. "ch1.stat.deaths". Not written to disk
## on every change; the next save_game() stores them.
func add_stat(key: String, amount: float) -> void:
	flags[key] = float(flags.get(key, 0.0)) + amount


func get_stat(key: String) -> float:
	var v = flags.get(key, 0.0)
	return float(v) if (v is float or v is int) else 0.0


## Appends one line to user://playtest_log.csv (for playtesting: time,
## deaths, resets and hints per room and per run, without writing them down
## by hand). Skipped while the tests run.
func log_playtest(fields: Array) -> void:
	if not persist_to_disk:
		return
	var path := "user://playtest_log.csv"
	var is_new := not FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ_WRITE if not is_new else FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	if is_new:
		file.store_line("when,what,room,seconds,deaths,resets,hints,pages")
	var row := PackedStringArray([Time.get_datetime_string_from_system(false, true)])
	for f in fields:
		row.append(str(f).replace(",", ";"))
	file.store_line(",".join(row))
	file.close()


func save_game() -> void:
	if not persist_to_disk:
		return
	var file := ConfigFile.new()
	var saved_flags := flags.duplicate()
	saved_flags["progress.abilities_version"] = 1
	file.set_value("progress", "flags", saved_flags)
	file.set_value("progress", "checkpoint_scene", checkpoint_scene)
	file.set_value("progress", "checkpoint_id", checkpoint_id)
	file.set_value("progress", "checkpoints", checkpoints)
	file.save(SAVE_PATH)


## Loads the save (or another file, for the tests' corrupted-save check).
func load_game(path := SAVE_PATH) -> void:
	if not persist_to_disk and path == SAVE_PATH:
		return
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	# A damaged or hand-edited save must never crash the game: anything of
	# the wrong type falls back to empty progress
	var loaded_flags = file.get_value("progress", "flags", {})
	flags = {}
	if loaded_flags is Dictionary:
		for key in loaded_flags:
			var value = loaded_flags[key]
			if key is String and (value is bool or value is int or (value is float and is_finite(value))):
				flags[key] = value
	_earlier = -1
	var scene = file.get_value("progress", "checkpoint_scene", "")
	var id = file.get_value("progress", "checkpoint_id", "")
	checkpoint_scene = scene if scene is String else ""
	checkpoint_id = id if id is String else ""
	var loaded_checkpoints = file.get_value("progress", "checkpoints", {})
	checkpoints = {}
	if loaded_checkpoints is Dictionary:
		for key in loaded_checkpoints:
			if key is String and loaded_checkpoints[key] is String:
				checkpoints[key] = loaded_checkpoints[key]
	# Saves from before per-scene checkpoints
	if checkpoints.is_empty() and checkpoint_scene != "":
		checkpoints[checkpoint_scene] = checkpoint_id
	# Migrate genuinely old saves once, while loading, rather than making
	# spell access depend on unrelated flags during play. Learning HEAL must
	# never revoke FIRE or ECHO, and a room flag must never teach a spell.
	if not flags.is_empty() and not flags.has("progress.abilities_version"):
		if not ABILITIES.any(func(ability): return flags.has("ability." + ability)) and (has_flag("tutorial.done") or count_flags("ch1.") > 0 or count_flags("ch2.") > 0):
			for ability in ABILITIES:
				flags["ability." + ability] = true
		flags["progress.abilities_version"] = 1
