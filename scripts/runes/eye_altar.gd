class_name EyeAltar
extends Node2D

## The great cube in the Eye, and the last sentence. The cube is fed by the
## dungeon and can be inscribed freely; when it is switched on, the sentence on
## it is read:
##   Light · Beam · Up · Long   the rewritten sky: the good ending
##   Ice · Freeze · Self · Large   the stillness: Ilse's wish, a real ending
##                                 that is not the only sentence (it leads
##                                 back here)
## Anything else is just a spell and it says it isn't enough.

signal sentence_read(kind: String)

const SKY := "light/beam/up/long"
const STILLNESS := "ice/freeze/self/large"

@export var cube_path: NodePath = ^"../GreatCube"

var cube: RuneCube
var decided := ""


func _ready() -> void:
	add_to_group("eye_altar")
	if Engine.is_editor_hint():
		return
	cube = get_node_or_null(cube_path) as RuneCube
	if cube:
		cube.activated.connect(_on_activated)


## "sky", "stillness" or "" for a recipe.
static func kind_of(key: String) -> String:
	match key:
		SKY:
			return "sky"
		STILLNESS:
			return "stillness"
	return ""


func _on_activated(c: RuneCube) -> void:
	if decided != "":
		return
	var kind := kind_of(c.recipe.to_key())
	var root := get_tree().get_first_node_in_group("chapter_root") as ChapterRoot
	if kind == "":
		if root:
			root.show_toast("That isn't enough. The cube answers to one sentence that sends the held moment away, and one that keeps it.", 5.0)
		return
	decided = kind
	sentence_read.emit(kind)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.lock_controls()
	Sfx.play("portal_open", global_position, 2.0, 0.0)
	ImpactFX.kick(get_tree(), 3.0, 0.3)
	await get_tree().create_timer(2.2).timeout
	var path := Journey.SKY_ENDING if kind == "sky" else Journey.STILLNESS_ENDING
	if kind == "sky":
		# The last card, after the closing pictures: the whole journey's numbers
		ChapterComplete.pending = {"name": "The Rewritten Sky", "stats": whole_run_stats()}
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


## Time and deaths added up over every part of the journey.
static func whole_run_stats() -> Dictionary:
	var time := 0.0
	var deaths := 0.0
	for prefix in ["tutorial", "ch1", "ch2", "landing", "kiln", "cistern", "lamps", "galleries", "eye"]:
		time += GameState.get_stat(prefix + ".stat.time")
		deaths += GameState.get_stat(prefix + ".stat.deaths")
	return {"time": time, "deaths": deaths, "heading": "THE END", "closing": "Thank you for playing.", "next": ""}
