extends Node
## SM_NodePreviewer
##
## Provides methods for creating or refreshing a scene preview.
## Supports adding visual markers for components and fitting the scene into a preview box.
##
## Main methods:[br]
## - [create_preview()]: Creates the viewport and generates a preview.[br]
## - [refresh_preview()]: Refreshes an existing viewport preview.[br]

const SM_SceneSaver := preload(SceneMapConstants.SCENE_SAVER)
const SM_ComponentFinder := preload(SceneMapConstants.COMPONENT_FINDER)
const SceneMapNode := preload(SceneMapConstants.SCENE_MAP_NODE)

#region PublicMethods

## Creates the preview box and calls the [_refresh_preview()] method.
static func create_preview(graph_node : SceneMapNode) -> void:
	var preview = TextureRect.new()
	preview.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	preview.custom_minimum_size = SceneMapConstants.VIEWPORT_SIZE

	graph_node.preview = preview
	graph_node.add_child(preview)

	refresh_preview(graph_node)


## Generates a [Texture2D] image in low resolution as a preview of the scene.
static func refresh_preview(graph_node : SceneMapNode) -> void:

	# Creates a subviewport that will hold the scene
	var viewport := SubViewport.new()
	viewport.size = SceneMapConstants.VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	graph_node.add_child(viewport)

	# Gets the scene instance
	var scene_values := await SM_SceneSaver.open_scene(graph_node.scene_uid)

	if scene_values == {}:
		printerr("Could not find the scene. If you deleted the .tscn file, refresh the SceneMap.")
		return

	var scene_resource : PackedScene = scene_values["resource"]
	var scene_instance : Node = scene_resource.instantiate()
	viewport.add_child(scene_instance)

	# Creates a preview if the scene is 2D
	if scene_instance is Node2D:
		graph_node.preview.texture = await _get_preview_2d(viewport, scene_instance)

	# Creates a preview if the scene is 3D
	if scene_instance is Node3D:
		graph_node.preview.texture = await _get_preview_3d(viewport, scene_instance)

#endregion

#region Preview2DMethods

## Generates the preview from a Node2D instance.
static func _get_preview_2d(viewport : SubViewport, scene_instance : Node) -> ImageTexture:
	# Calculates the scene size
	var scene_rect = _get_node_rect_2d(scene_instance, Rect2(Vector2.ONE, Vector2.ONE))

	# Adds markers to the scene
	scene_instance = _put_markers_2d(scene_instance, scene_rect.size)

	# Creates a camera and sets its position and zoom to fit the entire scene into the subviewport
	var camera := _fit_camera_to_scene_2d(viewport, scene_rect, SceneMapConstants.VIEWPORT_SIZE)

	# Generates the image and assigns it to the preview box
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()

	# Frees the nodes that are no longer necessary
	scene_instance.queue_free()
	camera.queue_free()
	viewport.queue_free()

	return ImageTexture.create_from_image(image)


## Returns a [Rect2] with the position and size of all the occupied space in each child of [node].
## This function is recursive so it will scan every node inside the [node] parameter's tree.
static func _get_node_rect_2d(node : Node, rect : Rect2) -> Rect2:

	# Gets the used space by a TileMapLayer
	if node is TileMapLayer:
		var cell_size : Vector2i = node.tile_set.tile_size
		var used_rect = node.get_used_rect()
		var pixel_rect := Rect2(used_rect.position * cell_size, used_rect.size * cell_size)
		
		rect = rect.merge(pixel_rect)

	# Gets the used space by regular Node2Ds
	elif node.get("size") and node.get("global_position"):
		var used_rect := Rect2(node.global_position, node.size)
		rect = rect.merge(used_rect)

	# Iterates each child recursively
	for child in node.get_children():
		rect = _get_node_rect_2d(child, rect)

	return rect


## Sets the camera position and size to fit the entire scene into the preview box.
static func _fit_camera_to_scene_2d(viewport : SubViewport, scene_rect : Rect2, viewport_size : Vector2) -> Camera2D:
	var camera := Camera2D.new()
	camera.enabled = true

	var center = scene_rect.position + scene_rect.size * 0.5
	var scale_x = viewport_size.x / scene_rect.size.x
	var scale_y = viewport_size.y / scene_rect.size.y
	var zoom_factor = min(scale_x, scale_y)

	camera.position = center
	camera.zoom = Vector2(zoom_factor, zoom_factor)

	viewport.add_child(camera)
	camera.make_current()

	return camera


## Places numbered markers in the position of each component that will be shown in the node's preview.
static func _put_markers_2d(scene_instance : Node, scene_size : Vector2) -> Node:

	var components := SM_ComponentFinder.find_all_components(scene_instance)

	var index := 0
	for component in components:

		index += 1

		var font_size := scene_size.x * 0.08
		var outline_size := scene_size.x * 0.02

		var label := Label.new()
		label.text = str(index)
		label.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", Color.RED)
		label.add_theme_color_override("font_outline_color", Color.WHITE)
		label.add_theme_constant_override("outline_size", outline_size)


		var theme_font := label.get_theme_font("font")
		var label_size := theme_font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		label.pivot_offset = label_size / 2
		label.global_position = component.global_position - label.pivot_offset

		scene_instance.add_child(label)

	return scene_instance

#endregion

#region Preview3DMethods

## Generates the preview from a Node3D instance.
static func _get_preview_3d(viewport : SubViewport, scene_instance : Node) -> ImageTexture:
	
	# Calculates the scene size
	var scene_aabb = _get_node_aabb_3d(scene_instance)

	# Creates a camera and sets its position and zoom to fit the entire scene into the subviewport
	var camera := _fit_camera_to_scene_3d(viewport, scene_aabb)

	# Adds markers to the scene
	scene_instance = _put_markers_3d(scene_instance, scene_aabb, camera)
	
	# Generates the image and assigns it to the preview box
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()

	# Frees the nodes that are no longer necessary
	scene_instance.queue_free()
	camera.queue_free()
	viewport.queue_free()

	return ImageTexture.create_from_image(image)


## Returns a [AABB] with the position and size of all the occupied space in each child of [node].
## This function is recursive so it will scan every node inside the [node] parameter's tree.
static func _get_node_aabb_3d(node : Node, aabb: AABB = AABB()) -> AABB:

	# If the node has a mesh or shape to calculate its size
	if node is MeshInstance3D:
		var mesh_aabb = node.get_aabb()
		aabb = aabb.merge(mesh_aabb)

	# If it's a Node3D with a custom size
	elif node is Node3D:
		var pos = node.global_transform.origin
		var size : Vector3

		if node.get("size") and node.size is Vector3:
			size = node.size
		elif node.get("scale") and node.scale is Vector3:
			size = node.scale

		if size:
			var mesh_aabb = AABB(pos, size)
			aabb = aabb.merge(mesh_aabb)
		
	# Iterates recursively
	for child in node.get_children():
		if child is Node3D:
			aabb = _get_node_aabb_3d(child, aabb)

	return aabb


## Sets the camera position and size to fit the entire scene into the preview box.
static func _fit_camera_to_scene_3d(viewport : SubViewport, scene_aabb : AABB) -> Camera3D:

	# Creates a new camera
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL

	viewport.add_child(camera)
	camera.make_current()

	# Sets its position and rotation to fit the whole scene
	var center = scene_aabb.position
	var radius : float = max(scene_aabb.size.x, scene_aabb.size.z) * 0.5
	var height := radius * 2.0
	var z_offset := height / tan(deg_to_rad(75))

	camera.global_position = Vector3(0, height, z_offset)
	camera.rotate_x(deg_to_rad(-75))

	# Calculates viewport's proportions and adjusts camera size
	var viewport_aspect = viewport.size.x / viewport.size.y
	var half_width  = scene_aabb.size.x * 0.5
	var half_depth  = scene_aabb.size.z * 0.5

	camera.size = max(half_width, half_depth * viewport_aspect)

	return camera


## Places numbered markers in the position of each component that will be shown in the node's preview.
static func _put_markers_3d(scene_instance: Node3D, scene_aabb: AABB, camera: Camera3D) -> Node3D:

	var components = SM_ComponentFinder.find_all_components(scene_instance)
	var pixels_per_unit = SceneMapConstants.VIEWPORT_SIZE.y / camera.size

	var index = 0

	for component in components:
		index += 1

		var label = Label3D.new()
		scene_instance.add_child(label)
		label.text = str(index)

		# Billboarding
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		# Font style, size and outline
		label.font_size = scene_aabb.size.x * 15
		label.outline_size = scene_aabb.size.x * 5

		label.modulate = Color.RED
		label.outline_modulate = Color.WHITE

		# Position
		var pivot_offset := Vector3(0, scene_aabb.size.y, 0)
		label.global_position = component.get_global_position() + pivot_offset

	return scene_instance

#endregion