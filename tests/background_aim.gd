class_name BackgroundAim
extends RefCounted

## Headless Window mouse position always reads zero. Exercise projectile
## flight/collisions via the real spawn method; this does NOT test mouse aiming
## or the shoot input/cost/cooldown. The no-mana fizzle uses shoot_fireball.
static func fire(player: CharacterBody2D, target: Vector2) -> void:
	if player.current_mana < player.FIREBALL_COST:
		# The fizzle path does not depend on cursor coordinates.
		player.shoot_fireball()
		await player.get_tree().physics_frame
		return
	var origin := player.global_position + Vector2(0, -12)
	var direction := (target - origin).normalized()
	var spawn: Vector2 = player._clear_spawn_point(origin, origin + direction * minf(origin.distance_to(target), 50.0))
	player.spawn_fireball(spawn, direction)
	player.fireball_cast.emit(spawn, direction)
	# Return before a nearby impact: callers must be able to observe the
	# short hit-stop rather than accidentally awaiting past it.
	await player.get_tree().physics_frame
