@tool
class_name ObjectiveStep
extends Node

## One milestone of a room's objective, placed as a child of its Room in
## order. The HUD shows a pip per step and names each step only once it is
## done, so progress is visible without giving the solution away. A step,
## once done, stays done until the room is reset (steps whose puzzle is saved
## complete again straight away).

enum Condition {
	POWERED,  ## target.is_powered() (plates, levers, braziers, crystals, circuits)
	SOLVED,   ## target.is_solved() (a latched circuit)
	OPEN,     ## a gate at least mostly open, or a seal that has opened
	RUNG,     ## a bell that has been rung
	FROZEN,   ## a gargoyle turned to stone
	REACHED,  ## the player inside `area` (world coordinates)
	FLAG,     ## GameState has `flag`
	MOVED,    ## a lantern wisp that has left its first perch
	PROPERTY, ## target.get(property) == value (e.g. a mirror's facing)
}

## What the HUD says once the step is done.
@export var label := ""
@export var condition: Condition = Condition.POWERED
@export var target: Node
@export var area := Rect2()
@export var flag := ""
@export var property := ""
@export var value := 0
## Optional steps show as hollow pips and don't count toward clearing the room.
@export var optional := false

var done := false
var _start_perch: Node


func _ready() -> void:
	if not Engine.is_editor_hint() and condition == Condition.MOVED and is_instance_valid(target):
		_start_perch = target.get("current_perch")


## Re-checks the condition; returns true the moment the step completes.
func update(player: Node2D) -> bool:
	if done:
		return false
	if _met(player):
		done = true
		return true
	return false


func reset() -> void:
	done = false


func _met(player: Node2D) -> bool:
	if condition == Condition.REACHED:
		return player != null and area.has_point(player.global_position)
	if condition == Condition.FLAG:
		return GameState.has_flag(flag)
	if not is_instance_valid(target):
		return false
	match condition:
		Condition.POWERED:
			return target.has_method("is_powered") and target.is_powered()
		Condition.SOLVED:
			return target.has_method("is_solved") and target.is_solved()
		Condition.OPEN:
			if target.get("is_open") != null:
				return target.is_open
			var amount = target.get("open_amount")
			return amount != null and amount >= 0.9
		Condition.RUNG:
			return target.has_method("is_ready") and not target.is_ready()
		Condition.FROZEN:
			return target.get("is_frozen") == true
		Condition.MOVED:
			return target.get("current_perch") != _start_perch or target.get("state") != 0
		Condition.PROPERTY:
			return target.get(property) == value
	return false
