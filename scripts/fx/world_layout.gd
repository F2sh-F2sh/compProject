extends RefCounted

## Cosmetic floor placement is checked against actual physics surfaces.
## Interactive puzzle objects keep their authored positions.
const FLOOR_ART := ["skull_pile", "rocks_a", "rocks_b", "skeleton", "tombstone_rubble", "candelabra", "candle", "barrel", "crate", "bones", "urn", "pot", "chest"]

static func settle(level: Node2D) -> void:
	await level.get_tree().physics_frame
	await level.get_tree().physics_frame
	if not is_instance_valid(level) or not level.is_inside_tree():
		return
	var space := level.get_world_2d().direct_space_state
	var occupied: Array[Rect2] = []
	for node in level.find_children("*", "", true, false):
		if node is HintStone:
			occupied.append(Rect2(node.global_position + Vector2(-12, -28), Vector2(24, 28)))
		elif node is ChapterCheckpoint or node is AbilityShrine or node is RuneTablet:
			occupied.append(Rect2(node.global_position + Vector2(-22, -68), Vector2(44, 68)))
		elif node is PushableBlock:
			occupied.append(Rect2(node.global_position - Vector2(node.block_size.x / 2.0, node.block_size.y), node.block_size))
	var images := {}
	for node in level.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite.texture == null or sprite.centered or sprite.offset.y >= 0:
			continue
		var file := sprite.texture.resource_path.get_file().get_basename()
		if file not in FLOOR_ART:
			continue
		# A checkpoint's candle and flame belong to the checkpoint (which stands
		# on the floor where it was put); moving them alone would part them.
		if sprite.get_parent() is HazardCheckpoint or sprite.get_parent() is ChapterCheckpoint:
			continue
		# Measure the part of the texture the sprite actually draws: a sprite
		# with a region shows only that part, and its last painted row is not
		# the whole texture's (measuring the whole lifted region sprites into
		# the air).
		var key := file + (str(sprite.region_rect) if sprite.region_enabled else "")
		if not images.has(key):
			var image := sprite.texture.get_image()
			if image and sprite.region_enabled:
				image = image.get_region(Rect2i(sprite.region_rect))
			images[key] = Rect2(image.get_used_rect()) if image else Rect2(Vector2.ZERO, sprite.texture.get_size())
		var ink: Rect2 = images[key]
		# Align the actual last painted pixel, including textures with a
		# transparent bottom margin. Canvas padding is not the object's foot.
		sprite.offset.y = -ink.end.y
		var original := sprite.global_position
		var room: Room
		for candidate_room in level.find_children("*", "Room", true, false):
			if candidate_room.contains(original):
				room = candidate_room
				break
		var placed := false
		for offset in [0.0, 24.0, -24.0, 48.0, -48.0, 72.0, -72.0, 96.0, -96.0]:
			var foot := original + Vector2(offset, 0)
			if room and not room.contains(foot):
				continue
			var query := PhysicsRayQueryParameters2D.create(foot + Vector2(0, -16), foot + Vector2(0, 96), 2)
			var hit := space.intersect_ray(query)
			if hit.is_empty() or hit["normal"].y > -0.8:
				continue
			sprite.global_position = Vector2(foot.x, hit["position"].y)
			var rect := Rect2(sprite.to_global(ink.position + sprite.offset), ink.size * sprite.global_scale)
			if occupied.any(func(other): return other.intersects(rect.grow(3))):
				continue
			occupied.append(rect)
			placed = true
			break
		if not placed:
			# Keep the source asset, but omit a loose prop where there is no
			# grounded, uncluttered space for it in its own room.
			sprite.hide()
