class_name DailyScore
extends RefCounted

## Turns a finished run's numbers into a score and stars, and a result into a
## short share code and a line of text.
##
## The score rewards thinking before acting rather than speed alone:
##   1000 base
##   - time over par (up to 300; par is what a careful player needs)
##   - 40 per Reset Room (up to 200)
##   - 60 per hint (up to 240)
##   - 25 per death (up to 150)
##   - 10 per rune cast beyond two a room (up to 150): switching a cube on
##     and off at random is the opposite of a plan
## Three stars need 800 points and no hints, two need 500, a finished run is
## always one.

const BASE := 1000
const TIME_MAX := 300.0
const RESET_EACH := 40
const RESET_MAX := 200
const HINT_EACH := 60
const HINT_MAX := 240
const DEATH_EACH := 25
const DEATH_MAX := 150
const CAST_EACH := 10
const CAST_MAX := 150
const FREE_CASTS_PER_ROOM := 2
const BELL_WALK_SECONDS := 25.0

## The share code's start; the digit is its format version.
const CODE_PREFIX := "SB1"
const ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
## Mixed into the code's checksum: it stops a hand-edited code, no more (the
## game is open source, so this is a typo guard, not security).
const SALT := "belfry-daily-share-v1"


## About how long a careful player takes for a spec's rooms, in seconds.
static func par_seconds(spec: Dictionary) -> float:
	var total := BELL_WALK_SECONDS
	for room in spec["rooms"]:
		var module := DailyModules.make(String(room["module"]))
		if module:
			if room.has("beats"):
				for beat in room["beats"]: total += DailyModules.make(beat["module"]).par_seconds
			else:
				total += module.par_seconds
	return total


## {"score", "stars", "parts": {name: points taken off}} for a run's numbers
## (time, deaths, resets, hints, casts) in a puzzle of `rooms` rooms with a
## par of `par` seconds.
static func compute(stats: Dictionary, par: float, rooms: int) -> Dictionary:
	var parts := {}
	var over := maxf(float(stats["time"]) - par, 0.0)
	parts["time"] = int(round(clampf(over / maxf(par, 1.0) * 150.0, 0.0, TIME_MAX)))
	parts["resets"] = mini(int(stats["resets"]) * RESET_EACH, RESET_MAX)
	parts["hints"] = mini(int(stats["hints"]) * HINT_EACH, HINT_MAX)
	parts["deaths"] = mini(int(stats["deaths"]) * DEATH_EACH, DEATH_MAX)
	parts["casts"] = mini(maxi(int(stats["casts"]) - FREE_CASTS_PER_ROOM * rooms, 0) * CAST_EACH, CAST_MAX)
	var score := BASE
	for key in parts:
		score -= int(parts[key])
	score = maxi(score, 0)
	var stars := 1
	if score >= 800 and int(stats["hints"]) == 0:
		stars = 3
	elif score >= 500:
		stars = 2
	return {"score": score, "stars": stars, "parts": parts}


# ------------------------------------------------------------------ share code

## A result as a short code: "SB1-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-X".
## Fields (all clamped): day, generator version, difficulty, tier, score,
## seconds, deaths, resets, hints, casts, assists. A 24-bit checksum follows.
static func encode(result: Dictionary) -> String:
	var bytes := PackedByteArray()
	var day := clampi(int(result.get("day", 0)), 0, 65535)
	bytes.append(day >> 8)
	bytes.append(day & 255)
	bytes.append((clampi(int(result.get("version", 1)), 0, 15) << 4) | (clampi(int(result.get("difficulty", 1)) - 1, 0, 3) << 2) | (1 if bool(result.get("endless", false)) else 0))
	bytes.append(clampi(int(result.get("tier", 1)), 0, 15))
	var score := clampi(int(result.get("score", 0)), 0, 1023)
	bytes.append(score >> 8)
	bytes.append(score & 255)
	var time := clampi(int(round(float(result.get("time", 0.0)))), 0, 65535)
	bytes.append(time >> 8)
	bytes.append(time & 255)
	for key in ["deaths", "resets", "hints", "casts", "assist"]:
		bytes.append(clampi(int(result.get(key, 0)), 0, 255))
	bytes.append_array(_checksum(bytes))
	var text := _base32(bytes)
	var groups := PackedStringArray([CODE_PREFIX])
	for i in range(0, text.length(), 5):
		groups.append(text.substr(i, 5))
	return "-".join(groups)


## The result a code holds, or {} if it isn't a well-formed code (a typo or a
## hand-edited number fails the checksum).
static func decode(code: String) -> Dictionary:
	var clean := code.strip_edges().to_upper().replace(" ", "")
	var parts := clean.split("-")
	if parts.size() < 2 or parts[0] != CODE_PREFIX:
		return {}
	var text := "".join(parts.slice(1))
	var bytes := _from_base32(text)
	if bytes.size() < 16:
		return {}
	var body := bytes.slice(0, 13)
	var sum := bytes.slice(13, 16)
	if _checksum(body) != sum:
		return {}
	return {
		"endless": bool(body[2] & 1),
		"day": (body[0] << 8) | body[1],
		"version": body[2] >> 4,
		"difficulty": ((body[2] >> 2) & 3) + 1,
		"tier": body[3],
		"score": (body[4] << 8) | body[5],
		"time": float((body[6] << 8) | body[7]),
		"deaths": body[8],
		"resets": body[9],
		"hints": body[10],
		"casts": body[11],
		"assist": body[12],
	}


## A line to paste into a chat.
static func share_text(result: Dictionary, code: String) -> String:
	if bool(result.get("endless", false)):
		return "The Sealed Belfry Endless, %s: %d rooms, %d pts a room  %d hint(s)\n%s" % [DailyDifficulty.name_of(float(result["difficulty"])), int(result["day"]), int(result["score"]), int(result["hints"]), code]
	var stars := "*".repeat(int(result["stars"])) + "-".repeat(3 - int(result["stars"]))
	var seconds := int(round(float(result["time"])))
	return "The Sealed Belfry daily %s  [%s]  %d pts  %d:%02d  %d hint(s)\n%s" % [
		DailyRng.label_of(int(result["day"])), stars, int(result["score"]), seconds / 60, seconds % 60, int(result["hints"]), code]


static func _checksum(bytes: PackedByteArray) -> PackedByteArray:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(SALT.to_utf8_buffer())
	ctx.update(bytes)
	return ctx.finish().slice(0, 3)


static func _base32(bytes: PackedByteArray) -> String:
	var out := ""
	var buffer := 0
	var bits := 0
	for b in bytes:
		buffer = (buffer << 8) | int(b)
		bits += 8
		while bits >= 5:
			out += ALPHABET[(buffer >> (bits - 5)) & 31]
			bits -= 5
		buffer &= (1 << bits) - 1
	if bits > 0:
		out += ALPHABET[(buffer << (5 - bits)) & 31]
	return out


static func _from_base32(text: String) -> PackedByteArray:
	var out := PackedByteArray()
	var buffer := 0
	var bits := 0
	for ch in text:
		var v := ALPHABET.find(ch)
		if v < 0:
			return PackedByteArray()
		buffer = (buffer << 5) | v
		bits += 5
		if bits >= 8:
			out.append((buffer >> (bits - 8)) & 255)
			bits -= 8
		buffer &= (1 << bits) - 1
	return out
