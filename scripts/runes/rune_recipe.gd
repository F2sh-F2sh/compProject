class_name RuneRecipe
extends Resource

## One rune: four fragment ids (see RuneFragments), one of each kind. An
## empty id is a missing (broken) quadrant. Each cube owns its own copy, so
## editing one cube never changes another.

@export var essence: StringName = &""
@export var form: StringName = &""
@export var direction: StringName = &""
@export var modifier: StringName = &""


static func make(e: StringName, f: StringName, d: StringName, m: StringName) -> RuneRecipe:
	var r := RuneRecipe.new()
	r.essence = e
	r.form = f
	r.direction = d
	r.modifier = m
	return r


## "wind/push/right/strong" (empty slots are "-").
func to_key() -> String:
	var parts := PackedStringArray()
	for id in [essence, form, direction, modifier]:
		parts.append(String(id) if id != &"" else "-")
	return "/".join(parts)


static func from_key(key: String) -> RuneRecipe:
	var parts := key.split("/")
	var r := RuneRecipe.new()
	if parts.size() == 4:
		var ids: Array[StringName] = []
		for p in parts:
			ids.append(StringName(p) if p != "-" else &"")
		r.essence = ids[0]
		r.form = ids[1]
		r.direction = ids[2]
		r.modifier = ids[3]
	return r


func get_slot(kind: int) -> StringName:
	return [essence, form, direction, modifier][kind]


func set_slot(kind: int, id: StringName) -> void:
	match kind:
		RuneFragments.Kind.ESSENCE: essence = id
		RuneFragments.Kind.FORM: form = id
		RuneFragments.Kind.DIRECTION: direction = id
		RuneFragments.Kind.MODIFIER: modifier = id


func is_complete() -> bool:
	return essence != &"" and form != &"" and direction != &"" and modifier != &""


func copy() -> RuneRecipe:
	return RuneRecipe.make(essence, form, direction, modifier)
