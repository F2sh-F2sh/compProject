extends TextureRect

## A real, low-resolution 3D case. The approved artwork is sampled directly
## from its front and spine, so Echidna and the cover remain unchanged.
const ART := preload("res://assets/ui/menu/belfry_box.png")
var _pivot: Node3D
var _turn_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var viewport := SubViewport.new()
	viewport.size = Vector2i(128, 192)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	texture = viewport.get_texture()
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 35.0
	camera.position = Vector3(0, 0, 5)
	viewport.add_child(camera)
	camera.current = true
	_pivot = Node3D.new()
	viewport.add_child(_pivot)
	var w := 0.95
	var h := 1.425
	var d := 0.14
	# Source pixel corners compensate for the perspective baked into the art.
	_face([Vector3(-w, h, d), Vector3(w, h, d), Vector3(w, -h, d), Vector3(-w, -h, d)],
		[Vector2(20, 5), Vector2(124, 20), Vector2(123, 180), Vector2(20, 186)], Color.WHITE)
	_face([Vector3(-w, h, -d), Vector3(-w, h, d), Vector3(-w, -h, d), Vector3(-w, -h, -d)],
		[Vector2(5, 10), Vector2(20, 5), Vector2(20, 186), Vector2(5, 182)], Color.WHITE)
	_face([Vector3(w, h, d), Vector3(w, h, -d), Vector3(w, -h, -d), Vector3(w, -h, d)], [], Color("343c61"))
	_face([Vector3(-w, h, -d), Vector3(w, h, -d), Vector3(w, h, d), Vector3(-w, h, d)], [], Color("667392"))
	_face([Vector3(-w, -h, d), Vector3(w, -h, d), Vector3(w, -h, -d), Vector3(-w, -h, -d)], [], Color("12182c"))
	_face([Vector3(w, h, -d), Vector3(-w, h, -d), Vector3(-w, -h, -d), Vector3(w, -h, -d)], [], Color("171e36"))
	_pivot.rotation.y = deg_to_rad(24)

func _process(delta: float) -> void:
	_turn_time += delta
	if _pivot:
		_pivot.rotation.y = deg_to_rad(24.0 if Settings.reduce_motion else 24.0 * cos(_turn_time * 0.65))

func _face(vertices: Array, pixels: Array, colour: Color) -> void:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	if not pixels.is_empty():
		var uvs := PackedVector2Array()
		for point in pixels: uvs.append(point / Vector2(128, 192))
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = colour
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if not pixels.is_empty():
		material.albedo_texture = ART
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = 0.5
	var face := MeshInstance3D.new()
	face.mesh = mesh
	face.material_override = material
	_pivot.add_child(face)
