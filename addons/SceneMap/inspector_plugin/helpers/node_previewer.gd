extends Node

const SM_Constants := preload("uid://cjynbj0oq1sx1")

## Creates the preview box and calls the [_refresh_preview] method.
static func create_preview(graph_node : SceneMapNode) -> void:
	var preview = TextureRect.new()
	preview.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED

	graph_node.preview = preview
	graph_node.add_child(preview)

	refresh_preview(graph_node)


## Generates a [Texture2D] image in low resolution as a preview of the scene.
static func refresh_preview(graph_node : SceneMapNode) -> void:

	# Creates a subviewport that will hold the scene
	var viewport := SubViewport.new()
	viewport.size = SM_Constants.VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	graph_node.add_child(viewport)

	# Gets the total size of the scene
	var scene_instance = graph_node.scene_resource.instantiate()
	var scene_size = get_scene_size(scene_instance)
	viewport.add_child(scene_instance)

	# Creates a camera and sets its position and zoom to fit the entire scene into the subviewport
	var camera := Camera2D.new()
	camera.enabled = true
	camera = fit_camera_to_scene(camera, scene_size, SM_Constants.VIEWPORT_SIZE)
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


## Returns a [Rect2] with the position and size of all the occupied space in the scene.
## TODO: need more ways to determine the total size of the scene.
static func get_scene_size(scene_instance : Node) -> Rect2:

	var rect := Rect2()
	var first := true

	# Iterates every tile layer and sums all their positions and sizes
	var tile_map : Node2D = scene_instance.get_node("TileMap")
	for node in tile_map.get_children():
		if node is TileMapLayer:

			var cell_size : Vector2i = node.tile_set.tile_size
			var used_rect = node.get_used_rect()
			var pixel_rect := Rect2(used_rect.position * cell_size, used_rect.size * cell_size)

			if first:
				rect = pixel_rect
				first = false
			else:
				rect.merge(pixel_rect)

	return rect


## Sets the camera position and size to fit the entire scene into the preview box.
static func fit_camera_to_scene(camera : Camera2D, scene_size : Rect2, viewport_size : Vector2) -> Camera2D:
	var center = scene_size.position + scene_size.size * 0.5
	var scale_x = viewport_size.x / scene_size.size.x
	var scale_y = viewport_size.y / scene_size.size.y
	var zoom_factor = min(scale_x, scale_y)

	camera.position = center
	camera.zoom = Vector2(zoom_factor, zoom_factor)

	return camera