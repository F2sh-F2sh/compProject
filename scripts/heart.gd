extends TextureRect

enum State {
	EMPTY,
	HALF,
	FULL
}

@export var full_texture: Texture2D
@export var half_texture: Texture2D
@export var empty_texture: Texture2D


func set_state(state: State) -> void:
	match state:
		State.FULL:
			texture = full_texture

		State.HALF:
			texture = half_texture

		State.EMPTY:
			texture = empty_texture

func set_health_amount(amount: int, max_amount: int) -> void:
	if amount <= 0:
		set_state(State.EMPTY)
	elif amount >= max_amount:
		set_state(State.FULL)
	else:
		set_state(State.HALF)
