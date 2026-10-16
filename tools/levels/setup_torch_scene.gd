extends SceneTree

## Adds the glow and embers to the wall torch (scenes/world/torch_light.tscn), which
## every level instances: a breathing blue halo around the flame and sparks
## rising off it. Safe to run again.
##   godot --headless --path . --script res://tools/levels/setup_torch_scene.gd

const TORCH := "res://scenes/world/torch_light.tscn"

var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		var root: Node2D = (load(TORCH) as PackedScene).instantiate()
		for node_name in ["Halo", "Embers"]:
			var old := root.get_node_or_null(node_name)
			if old:
				root.remove_child(old)
				old.free()
		var halo := GlowFX.halo(Color(0.4, 0.6, 1.0), 26.0, 0.42, 1.7, 0.16, 0.2)
		halo.position = Vector2(0, -3)
		root.add_child(halo)
		halo.owner = root
		var embers := GlowFX.embers(Color(0.55, 0.75, 1.0), 6, 26.0, 3.0, 1.4)
		embers.position = Vector2(0, -8)
		root.add_child(embers)
		embers.owner = root
		var packed := PackedScene.new()
		var err := packed.pack(root)
		if err == OK:
			err = ResourceSaver.save(packed, TORCH)
		print("Torch scene updated: ", error_string(err))
		root.free()
		quit()
	return false
