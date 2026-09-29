class_name InputLabels
extends RefCounted

## Turns input actions into the key names the player actually has bound,
## so on-screen text stays correct if the bindings change.

const MOUSE_NAMES := {
	MOUSE_BUTTON_LEFT: "Left Click",
	MOUSE_BUTTON_RIGHT: "Right Click",
	MOUSE_BUTTON_MIDDLE: "Middle Click",
}
## Names for a standard (Xbox-layout) controller.
const PAD_BUTTONS := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_DPAD_UP: "D-pad Up", JOY_BUTTON_DPAD_DOWN: "D-pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-pad Left", JOY_BUTTON_DPAD_RIGHT: "D-pad Right",
}
const PAD_AXES := {
	JOY_AXIS_TRIGGER_LEFT: "LT", JOY_AXIS_TRIGGER_RIGHT: "RT",
}

## True while the player is using a controller (the last input came from
## one), so prompts name pad buttons instead of keys.
static var use_pad := false


## Tracks which kind of device was used last (called for every input event).
static func note_event(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		use_pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		use_pad = false


static func primary(action: StringName) -> String:
	var events := _events(action)
	if use_pad:
		for event in events:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				var pad_label := _event_label(event)
				if pad_label != "":
					return pad_label
	for event in events:
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			continue
		var label := _event_label(event)
		if label != "":
			return label
	return String(action).capitalize()


## Replaces every {action_name} in the text with that action's key name.
## wrap_format lets callers style the key, e.g. "[color=gold]%s[/color]".
static func format(text: String, wrap_format := "%s") -> String:
	var regex := RegEx.create_from_string("\\{([a-zA-Z0-9_]+)\\}")
	var result := text
	for match in regex.search_all(text):
		var action := match.get_string(1)
		result = result.replace(match.get_string(0), wrap_format % primary(action))
	return result


static func _events(action: StringName) -> Array:
	if InputMap.has_action(action):
		return InputMap.action_get_events(action)
	# In the editor the project's own actions only live in ProjectSettings
	var setting = ProjectSettings.get_setting("input/" + String(action), null)
	if setting is Dictionary and setting.has("events"):
		return setting["events"]
	return []


static func _event_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var code: Key = event.keycode
		# Prefer the key printed on this keyboard layout; headless runs can't look it up
		if code == KEY_NONE and DisplayServer.get_name() != "headless":
			code = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
		if code == KEY_NONE:
			code = event.physical_keycode
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		return MOUSE_NAMES.get(event.button_index, "Mouse %d" % event.button_index)
	if event is InputEventJoypadButton:
		return PAD_BUTTONS.get(event.button_index, "Button %d" % event.button_index)
	if event is InputEventJoypadMotion:
		if PAD_AXES.has(event.axis):
			return PAD_AXES[event.axis]
		if event.axis == JOY_AXIS_LEFT_X:
			return "Stick Left" if event.axis_value < 0.0 else "Stick Right"
		if event.axis == JOY_AXIS_LEFT_Y:
			return "Stick Up" if event.axis_value < 0.0 else "Stick Down"
	return ""
