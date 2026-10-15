class_name DailyCalibration
extends RefCounted

## Local, bounded solve observations. No networking or story-save writes.
const LIMIT := 2000
static var file_path := "user://puzzle_stats.cfg"
static var persist := true

static func append(entry: Dictionary) -> void:
	if not persist:
		return
	var file := ConfigFile.new()
	file.load(file_path)
	var rows: Array = read_rows(file)
	rows.append(entry.duplicate(true))
	if rows.size() > LIMIT: rows = rows.slice(rows.size() - LIMIT)
	file.set_value("stats", "rows", rows)
	file.save(file_path)

static func read_rows(file: ConfigFile) -> Array:
	var raw: Variant = file.get_value("stats", "rows", [])
	var rows: Array = []
	if raw is Array:
		for entry in raw:
			if entry is Dictionary and entry.has_all(["module", "params", "tier", "r", "time", "resets", "hints", "deaths"]):
				var valid := entry["module"] is String and entry["params"] is Dictionary
				for key in ["r", "time", "tier", "resets", "hints", "deaths"]:
					var value: Variant = entry[key]
					if not (value is float or value is int): valid = false; continue
					if not is_finite(float(value)) or float(value) < 0: valid = false
				if entry.has("parts"):
					if not entry["parts"] is Dictionary:
						valid = false
					else:
						for key in ["search", "steps", "concept", "execution", "decoys"]:
							var part: Variant = entry["parts"].get(key, 0)
							if not (part is float or part is int): valid = false; continue
							if not is_finite(float(part)) or float(part) < 0: valid = false
				if valid: rows.append(entry)
	return rows.slice(maxi(0, rows.size() - LIMIT))
