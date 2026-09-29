class_name InputLabels
extends RefCounted

## Turns input actions into the key names the player actually has bound,
## so on-screen text stays correct if the bindings change.

const MOUSE_NAMES := {
	MOUSE_BUTTON_LEFT: "Left Click",
	MOUSE_BUTTON_RIGHT: "Right Click",
	MOUSE_BUTTON_MIDDLE: "Middle Click",
}


static func primary(action: StringName) -> String:
	for event in _events(action):
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
	return ""
