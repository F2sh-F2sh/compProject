class_name DailyRng
extends RefCounted

## The daily puzzle's own random numbers and calendar. Nothing here uses
## Godot's hash(), randi() or RandomNumberGenerator: their output is not
## promised to stay the same between engine versions, and the daily puzzle
## must be the same puzzle for everyone, on every platform, on a given date.
## Everything is 32-bit integer arithmetic (xorshift32, murmur3's finaliser,
## FNV-1a), so a seed always produces the same numbers.

const MASK := 0xFFFFFFFF
## Day 0 of the daily calendar.
const EPOCH_YEAR := 2026
const EPOCH_MONTH := 1
const EPOCH_DAY := 1

var state := 1


func _init(seed_value := 1) -> void:
	state = mix(seed_value)
	if state == 0:
		state = 0x9E3779B9


## Scrambles a number into 32 well-mixed bits (the murmur3 finaliser).
static func mix(value: int) -> int:
	var x := value & MASK
	x ^= x >> 16
	x = (x * 0x85EBCA6B) & MASK
	x ^= x >> 13
	x = (x * 0xC2B2AE35) & MASK
	x ^= x >> 16
	return x


## 32-bit FNV-1a of a string's UTF-8 bytes.
static func fnv(text: String) -> int:
	var h := 0x811C9DC5
	for b in text.to_utf8_buffer():
		h ^= int(b)
		h = (h * 0x01000193) & MASK
	return h


## The next 32 random bits.
func next_u32() -> int:
	var x := state
	x ^= (x << 13) & MASK
	x ^= x >> 17
	x ^= (x << 5) & MASK
	state = x & MASK
	return state


## A whole number from lo to hi, both included.
func int_range(lo: int, hi: int) -> int:
	if hi <= lo:
		return lo
	return lo + next_u32() % (hi - lo + 1)


## True with probability p (0..1).
func chance(p: float) -> bool:
	return float(next_u32()) / 4294967296.0 < p


## One item of a non-empty array.
func pick(items: Array) -> Variant:
	return items[next_u32() % items.size()]


## A shuffled copy of an array (Fisher-Yates).
func shuffled(items: Array) -> Array:
	var out := items.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := next_u32() % (i + 1)
		var swap: Variant = out[i]
		out[i] = out[j]
		out[j] = swap
	return out


## An independent generator named by a label, so each part of a puzzle
## (the third room, the decoration) draws its own numbers and adding a draw
## in one part never shifts another.
func fork(label: String) -> DailyRng:
	return DailyRng.new(mix(state ^ fnv(label)))


# ------------------------------------------------------------------ calendar

## Days since 1970-01-01 of a civil date (proleptic Gregorian).
static func days_from_civil(year: int, month: int, day: int) -> int:
	var y := year - (1 if month <= 2 else 0)
	var era := floori(y / 400.0)
	var yoe := y - era * 400
	var mp := month + (9 if month <= 2 else -3)
	var doy := floori((153.0 * mp + 2.0) / 5.0) + day - 1
	var doe := yoe * 365 + floori(yoe / 4.0) - floori(yoe / 100.0) + doy
	return era * 146097 + doe - 719468


## {year, month, day} of a day count since 1970-01-01.
static func civil_from_days(days: int) -> Dictionary:
	var z := days + 719468
	var era := floori(z / 146097.0)
	var doe := z - era * 146097
	var yoe := floori((doe - floori(doe / 1460.0) + floori(doe / 36524.0) - floori(doe / 146096.0)) / 365.0)
	var y := yoe + era * 400
	var doy := doe - (365 * yoe + floori(yoe / 4.0) - floori(yoe / 100.0))
	var mp := floori((5.0 * doy + 2.0) / 153.0)
	var d := doy - floori((153.0 * mp + 2.0) / 5.0) + 1
	var m := mp + (3 if mp < 10 else -9)
	if m <= 2:
		y += 1
	return {"year": y, "month": m, "day": d}


static func epoch_days() -> int:
	return days_from_civil(EPOCH_YEAR, EPOCH_MONTH, EPOCH_DAY)


## The daily puzzle's day number for a civil date (0 = 2026-01-01).
static func day_index(year: int, month: int, day: int) -> int:
	return days_from_civil(year, month, day) - epoch_days()


## The civil date of a day number.
static func date_of(index: int) -> Dictionary:
	return civil_from_days(index + epoch_days())


## 0 = Sunday ... 6 = Saturday.
static func weekday(index: int) -> int:
	return posmod(index + epoch_days() + 4, 7)


## "2026-10-10"
static func label_of(index: int) -> String:
	var d := date_of(index)
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]
