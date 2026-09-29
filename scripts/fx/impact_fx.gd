class_name ImpactFX
extends RefCounted

## Small, shared effects that make hits land: a burst of sparks with a quick
## flash of light where a spell strikes, a brief hit-stop, and a camera kick.
## Everything that moves the view or freezes time respects "reduce motion".


## Sparks and a flash of light at `at`. `stone` adds grey chips (walls).
static func burst(parent: Node, at: Vector2, color := Color(1.0, 0.6, 0.28), stone := false, amount := 14) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var sparks := CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	sparks.amount = amount
	sparks.lifetime = 0.45
	sparks.spread = 180.0
	sparks.gravity = Vector2(0, 220)
	sparks.initial_velocity_min = 50.0
	sparks.initial_velocity_max = 130.0
	sparks.damping_min = 60.0
	sparks.damping_max = 120.0
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.5
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.95, 0.8))
	ramp.set_color(1, Color(color, 0.0))
	sparks.color_ramp = ramp
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sparks.material = additive
	sparks.z_index = 6
	parent.add_child(sparks)
	sparks.global_position = at
	sparks.emitting = true
	sparks.finished.connect(sparks.queue_free)
	if stone:
		var chips := CPUParticles2D.new()
		chips.one_shot = true
		chips.explosiveness = 1.0
		chips.amount = 6
		chips.lifetime = 0.6
		chips.spread = 70.0
		chips.direction = Vector2.UP
		chips.gravity = Vector2(0, 420)
		chips.initial_velocity_min = 40.0
		chips.initial_velocity_max = 90.0
		chips.scale_amount_min = 1.5
		chips.scale_amount_max = 2.5
		chips.color = Color(0.45, 0.42, 0.55)
		parent.add_child(chips)
		chips.global_position = at
		chips.emitting = true
		chips.finished.connect(chips.queue_free)
	var flash := PointLight2D.new()
	flash.texture = LightTextures.radial(128)
	flash.color = color
	flash.energy = 1.6
	flash.texture_scale = 1.4
	parent.add_child(flash)
	flash.global_position = at
	var tween := flash.create_tween()
	tween.tween_property(flash, "energy", 0.0, 0.16)
	tween.tween_callback(flash.queue_free)


## Freezes the action for a heartbeat so a hit reads as a hit.
static func hit_stop(tree: SceneTree, seconds := 0.05, scale := 0.05) -> void:
	if Settings.reduce_motion or tree == null:
		return
	Engine.time_scale = scale
	await tree.create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0


## A small shake of the current camera.
static func kick(tree: SceneTree, strength := 1.5, duration := 0.12) -> void:
	if tree == null or tree.root == null:
		return
	var camera := tree.root.get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(strength, duration)
