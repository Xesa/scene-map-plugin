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
	var scene_resource : PackedScene = await SM_SceneSaver.open_scene(graph_node.scene_uid)["resource"]
	var scene_instance : Node = scene_resource.instantiate()
	viewport.add_child(scene_instance)

	# Calculates the scene size
	var scene_rect = _get_node_rect(scene_instance, Rect2(Vector2.ONE, Vector2.ONE))

	# Adds markers to the scene
	scene_instance = _put_markers(scene_instance, scene_rect.size)

	# Creates a camera and sets its position and zoom to fit the entire scene into the subviewport
	var camera := Camera2D.new()
	camera.enabled = true
	camera = _fit_camera_to_scene(camera, scene_rect, SceneMapConstants.VIEWPORT_SIZE)
	viewport.add_child(camera)
	camera.make_current()
	
	# Generates the image and assigns it to the preview box
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	graph_node.preview.texture = ImageTexture.create_from_image(image)

	# Frees the nodes that are no longer necessary
	scene_instance.queue_free()
	camera.queue_free()
	viewport.queue_free()

#endregion

#region PrivateMethods

## Returns a [Rect2] with the position and size of all the occupied space in each child of [node].
## This function is recursive so it will scan every node inside the [node] parameter's tree.
static func _get_node_rect(node : Node, rect : Rect2) -> Rect2:

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
		rect = _get_node_rect(child, rect)

	return rect


## Sets the camera position and size to fit the entire scene into the preview box.
static func _fit_camera_to_scene(camera : Camera2D, scene_rect : Rect2, viewport_size : Vector2) -> Camera2D:
	var center = scene_rect.position + scene_rect.size * 0.5
	var scale_x = viewport_size.x / scene_rect.size.x
	var scale_y = viewport_size.y / scene_rect.size.y
	var zoom_factor = min(scale_x, scale_y)

	camera.position = center
	camera.zoom = Vector2(zoom_factor, zoom_factor)

	return camera


## Places numbered markers in the position of each component that will be shown in the node's preview.
static func _put_markers(scene_instance : Node, scene_size : Vector2) -> Node:

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