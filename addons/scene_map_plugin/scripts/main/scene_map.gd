@tool
extends EditorPlugin

const SceneMapGraph := preload(SceneMapConstants.SCENE_MAP_GRAPH)
const SceneMapIO := preload(SceneMapConstants.SCENE_MAP_IO)

var main_panel : Control

func _enter_tree() -> void:

	# Waits until the filesystem is fully loaded
	while EditorInterface.get_resource_filesystem().is_scanning():
		await Engine.get_main_loop().process_frame

	# Loads the config file
	if _load_config_file() != OK:
		EditorInterface.set_plugin_enabled.call_deferred(_get_plugin_name, false)
		return

	# Adds the main panel
	main_panel = load(SceneMapConstants.PANEL_TSCN).instantiate()
	main_panel.name = "SceneMapPanel"
	get_editor_interface().get_editor_main_screen().add_child(main_panel)

	# Adds the graph to the main panel
	var graph : SceneMapGraph = main_panel.get_node("SceneMapGraph")
	graph.plugin = self

	# Loads the saved data
	SceneMapIO.load(graph)
	
	_make_visible(false)


func _exit_tree() -> void:
	if main_panel:
		main_panel.queue_free()


func _has_main_screen() -> bool:
	return true


func _make_visible(visible : bool) -> void:
	if main_panel:
		main_panel.visible = visible


func _get_plugin_name():
	return "SceneMap"


func _get_plugin_icon():
	var svg : Texture2D = load(SceneMapConstants.MAP_ICON)
	var img := svg.get_image()
	img.resize(16, 16, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func _load_config_file() -> int:
	var config := ConfigFile.new()
	var err := config.load(SceneMapConstants.CONFIG_PATH)

	if err == OK:
		SceneMapConstants.VERSION = config.get_value("plugin", "version")
	else:
		printerr("Error loading .cfg file. Please, reinstall the plugin")

	return err