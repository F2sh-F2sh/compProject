class_name DailyStore
extends RefCounted

## Everything the daily puzzle remembers, in its own file (user://daily.cfg),
## apart from the story's save: each day's result, the streak, the free
## "mend" that forgives one missed day a week, and the friends' results
## pasted in. Loaded on first use, written after every change, and refused
## wholesale if the file is damaged (it validates every field like
## GameState.load_game does).
##
## The clock: the daily puzzle is the local calendar date. A clock that is
## wrong would hand out the wrong puzzle or a fake streak, so the daily is
## only ranked when the date is not earlier than the day this build was made
## nor earlier than a day already seen (a handheld with no battery clock
## reports 1970). Practice is always open.

const PATH := "user://daily.cfg"
## The first day this build can be played (2026-10-10), as a daily day number.
const BUILD_DAY := 282
## How many days make a streak week, and how long a mend takes to come back.
const MEND_EVERY := 7
const MAX_FRIENDS := 40
const MAX_NAME := 16

## Tests turn this off so they never touch a player's file.
static var persist := true
## Where the file lives (the tests point it elsewhere).
static var file_path := PATH
## What the date is: a Callable returning {"year", "month", "day"}; the tests
## replace it.
static var now_provider := Callable()

static var _loaded := false
## "day number" -> the ranked result of that day (see record()).
static var days := {}
## "day number" -> the best practice score for that day.
static var practice := {}
static var streak := 0
static var best_streak := 0
static var last_day := -1
static var last_mend_day := -100000
static var last_seen_day := -1
static var player_name := ""
## [{name, code, day, score, time, stars}] pasted in by the player.
static var friends: Array = []


# ------------------------------------------------------------------ the clock

## Today's day number.
static func today() -> int:
	var d: Dictionary
	if now_provider.is_valid():
		d = now_provider.call()
	else:
		d = Time.get_date_dict_from_system(false)
	return DailyRng.day_index(int(d["year"]), int(d["month"]), int(d["day"]))


## "ok", "too_early" (before this build existed: the clock is wrong) or
## "rewound" (earlier than a day already seen).
static func clock_status() -> String:
	_ensure_loaded()
	var t := today()
	if t < BUILD_DAY:
		return "too_early"
	if t < last_seen_day:
		return "rewound"
	return "ok"


## Remembers that `today` has been seen (only when the clock is sane).
static func note_today() -> void:
	_ensure_loaded()
	if clock_status() == "ok" and today() > last_seen_day:
		last_seen_day = today()
		save()


# ------------------------------------------------------------------ results

## The ranked result of a day, or {} if it hasn't been played.
static func result_for(day: int) -> Dictionary:
	_ensure_loaded()
	return days.get(str(day), {})


static func has_ranked(day: int) -> bool:
	return not result_for(day).is_empty()


## Writes a finished run's result. A daily's first completion of a date is
## its ranked result and moves the streak; anything else only updates the
## day's practice best. Returns {"ranked", "new_best", "streak", "mended"}.
static func record(result: Dictionary) -> Dictionary:
	_ensure_loaded()
	var day := int(result["day"])
	var key := str(day)
	var out := {"ranked": false, "new_best": false, "streak": streak, "mended": false}
	var ranked_ok: bool = String(result.get("mode", "daily")) == "daily" and clock_status() == "ok" \
		and day == today() and not days.has(key)
	if ranked_ok:
		days[key] = result.duplicate(true)
		out["ranked"] = true
		out["new_best"] = true
		out["mended"] = _advance_streak(day)
		out["streak"] = streak
	var best: int = int(practice.get(key, -1))
	if int(result["score"]) > best:
		practice[key] = int(result["score"])
		out["new_best"] = out["new_best"] or not ranked_ok
	save()
	return out


## Moves the streak for a ranked completion on `day`. Returns true if a mend
## covered a missed day.
static func _advance_streak(day: int) -> bool:
	var mended := false
	if last_day == day:
		return false
	if day < last_day:
		return false
	if last_day == day - 1:
		streak += 1
	elif last_day == day - 2 and day - last_mend_day >= MEND_EVERY:
		streak += 1
		last_mend_day = day
		mended = true
	else:
		streak = 1
	last_day = day
	best_streak = maxi(best_streak, streak)
	return mended


## The streak as it stands today: it lapses (shows 0) if yesterday was missed
## and no mend is left, without waiting for the next result.
static func current_streak() -> int:
	_ensure_loaded()
	var t := today()
	if last_day < 0 or streak == 0:
		return 0
	if last_day >= t - 1:
		return streak
	if last_day == t - 2 and t - last_mend_day >= MEND_EVERY:
		return streak
	return 0


## Whether a mend is ready (it forgives one missed day).
static func mend_ready() -> bool:
	_ensure_loaded()
	return today() - last_mend_day >= MEND_EVERY


# ------------------------------------------------------------------ friends

## Adds a friend's pasted share code. Returns "" or the reason it was refused.
static func add_friend(friend_name: String, code: String) -> String:
	_ensure_loaded()
	var result := DailyScore.decode(code)
	if result.is_empty():
		return "That doesn't look like a result code (check for typos)."
	if bool(result.get("endless", false)):
		return "That is an Endless run; the board is for daily puzzles."
	var clean := _clean_name(friend_name)
	if clean == "":
		clean = "Friend"
	# one entry per (name, day): a newer paste replaces the older
	for i in friends.size():
		if friends[i]["name"] == clean and int(friends[i]["day"]) == int(result["day"]):
			friends.remove_at(i)
			break
	friends.append({"name": clean, "code": code.strip_edges().to_upper(), "day": int(result["day"]),
		"score": int(result["score"]), "time": float(result["time"]), "stars": 0})
	while friends.size() > MAX_FRIENDS:
		friends.remove_at(0)
	save()
	return ""


## Reads user://friends.txt (one "Name CODE" per line), for a handheld with no
## keyboard: copy the file in over USB. Returns how many were added.
static func import_friends_file(path := "user://friends.txt") -> int:
	if not FileAccess.file_exists(path):
		return 0
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var added := 0
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var cut := line.rfind(" ")
		if cut < 0:
			continue
		if add_friend(line.substr(0, cut), line.substr(cut + 1)) == "":
			added += 1
	return added


## The board for a day: the player, the friends, sorted by score then time.
## [{name, score, time, you}]
static func board_for(day: int) -> Array:
	_ensure_loaded()
	var rows: Array = []
	var mine := result_for(day)
	if not mine.is_empty():
		rows.append({"name": player_name if player_name != "" else "You", "score": int(mine["score"]),
			"time": float(mine["time"]), "you": true})
	for f in friends:
		if int(f["day"]) == day:
			rows.append({"name": f["name"], "score": int(f["score"]), "time": float(f["time"]), "you": false})
	rows.sort_custom(func(a, b):
		if a["score"] != b["score"]:
			return a["score"] > b["score"]
		return a["time"] < b["time"])
	return rows


static func set_player_name(value: String) -> void:
	_ensure_loaded()
	player_name = _clean_name(value)
	save()


static func _clean_name(value: String) -> String:
	var out := ""
	for ch in value.strip_edges():
		if out.length() >= MAX_NAME:
			break
		if ch.unicode_at(0) < 128 and (ch == " " or ch == "_" or ch == "-" or ch == "." or ch.to_lower() != ch.to_upper() or ch.is_valid_int()):
			out += ch
	return out.strip_edges()


# ------------------------------------------------------------------ the file

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	load_file()


## Forgets everything in memory (tests); the next use loads again.
static func forget() -> void:
	endless_best = {}
	_loaded = false
	days = {}
	practice = {}
	streak = 0
	best_streak = 0
	last_day = -1
	last_mend_day = -100000
	last_seen_day = -1
	player_name = ""
	friends = []


static func save() -> void:
	if not persist:
		return
	var file := ConfigFile.new()
	file.set_value("daily", "endless_best", endless_best)
	file.set_value("daily", "days", days)
	file.set_value("daily", "practice", practice)
	file.set_value("daily", "streak", streak)
	file.set_value("daily", "best_streak", best_streak)
	file.set_value("daily", "last_day", last_day)
	file.set_value("daily", "last_mend_day", last_mend_day)
	file.set_value("daily", "last_seen_day", last_seen_day)
	file.set_value("daily", "player_name", player_name)
	file.set_value("daily", "friends", friends)
	file.save(file_path)


## Loads a file (the default, or another for the tests). Anything of the
## wrong type or out of range keeps its default.
static func load_file(path := "") -> void:
	if path == "" and not persist:
		return
	var file := ConfigFile.new()
	if file.load(path if path != "" else file_path) != OK:
		return
	endless_best = {}
	var raw_best: Variant = file.get_value("daily", "endless_best", {})
	if raw_best is Dictionary:
		for key in raw_best:
			if not key in ["1", "2", "3", "4"] or not raw_best[key] is Dictionary:
				continue
			var entry: Dictionary = raw_best[key]
			if not entry.has_all(["rooms", "score", "level"]):
				continue
			var value: Variant = entry["level"]
			var level_value := float(value) if (value is int or value is float) else 1.0
			if not is_finite(level_value):
				level_value = 1.0
			endless_best[key] = {"rooms": _int_in(entry["rooms"], 0, 100000), "score": _int_in(entry["score"], 0, 100000000), "level": snappedf(clampf(level_value, 1.0, 5.0), 0.25)}
	days = _clean_results(file.get_value("daily", "days", {}))
	var p = file.get_value("daily", "practice", {})
	practice = {}
	if p is Dictionary:
		for k in p:
			if _is_day_key(k) and (p[k] is int or p[k] is float):
				practice[str(k)] = clampi(int(p[k]), 0, 1023)
	streak = _int_in(file.get_value("daily", "streak", 0), 0, 100000)
	best_streak = _int_in(file.get_value("daily", "best_streak", 0), 0, 100000)
	last_day = _int_in(file.get_value("daily", "last_day", -1), -1, 100000)
	last_mend_day = _int_in(file.get_value("daily", "last_mend_day", -100000), -100000, 100000)
	last_seen_day = _int_in(file.get_value("daily", "last_seen_day", -1), -1, 100000)
	var name_value = file.get_value("daily", "player_name", "")
	player_name = _clean_name(name_value) if name_value is String else ""
	friends = []
	var f = file.get_value("daily", "friends", [])
	if f is Array:
		for entry in f:
			if entry is Dictionary and entry.has("name") and entry.has("code"):
				var decoded := DailyScore.decode(String(entry["code"]))
				if not decoded.is_empty() and not bool(decoded.get("endless", false)) and friends.size() < MAX_FRIENDS:
					friends.append({"name": _clean_name(String(entry["name"])), "code": String(entry["code"]),
						"day": int(decoded["day"]), "score": int(decoded["score"]), "time": float(decoded["time"]), "stars": 0})


static func _is_day_key(k: Variant) -> bool:
	return k is String and String(k).is_valid_int() and int(k) >= 0 and int(k) < 100000


static func _int_in(v: Variant, lo: int, hi: int) -> int:
	if v is int or v is float:
		var f := float(v)
		if is_nan(f) or is_inf(f):
			return lo
		return clampi(int(f), lo, hi)
	return lo


static func _clean_results(raw: Variant) -> Dictionary:
	var out := {}
	if not raw is Dictionary:
		return out
	for k in raw:
		if not _is_day_key(k) or not raw[k] is Dictionary:
			continue
		var r: Dictionary = raw[k]
		var clean := {}
		for field in ["day", "score", "stars", "deaths", "resets", "hints", "casts", "assist", "difficulty", "tier", "version", "rooms", "digest"]:
			clean[field] = _int_in(r.get(field, 0), 0, 4294967295)
		clean["time"] = float(_int_in(r.get("time", 0), 0, 1000000))
		clean["mode"] = "daily"
		clean["score"] = clampi(int(clean["score"]), 0, 1023)
		clean["stars"] = clampi(int(clean["stars"]), 1, 3)
		clean["day"] = int(k)
		out[str(k)] = clean
	return out


static var endless_best := {}

static func endless_best_for(start: int) -> Dictionary:
	_ensure_loaded()
	return endless_best.get(str(start), {}).duplicate(true)

static func record_endless(start: int, rooms: int, score: int, level: float) -> bool:
	_ensure_loaded()
	if start < 1 or start > 4 or rooms <= 0:
		return false
	var best := endless_best_for(start)
	if not best.is_empty() and (rooms < int(best["rooms"]) or (rooms == int(best["rooms"]) and score <= int(best["score"]))):
		return false
	endless_best[str(start)] = {"rooms": rooms, "score": score, "level": snappedf(level, 0.25)}
	save()
	return true
