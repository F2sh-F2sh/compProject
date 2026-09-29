extends CanvasLayer

@onready var status_bar: Control = $HUDRoot/StatusBar


func set_health(current: int, maximum: int) -> void:
	status_bar.set_health(current, maximum)


func set_mana(current: int, maximum: int, restoring: bool, progress: float) -> void:
	status_bar.set_mana(current, maximum, restoring, progress)


func set_mana_debt(debt: int) -> void:
	status_bar.set_mana_debt(debt)


func set_echo_state(recording: bool, remaining: float, count: int, max_count: int) -> void:
	status_bar.set_echo_state(recording, remaining, count, max_count)
