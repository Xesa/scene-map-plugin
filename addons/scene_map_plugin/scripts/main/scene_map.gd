@tool
extends EditorPlugin

const SM_AutoUpdater := preload(SceneMapConstants.AUTO_UPDATER)
const SM_ResourceTools := preload(SceneMapConstants.RESOURCE_TOOLS)
const SceneMapPanel := preload(SceneMapConstants.SCENE_MAP_PANEL)
const SceneMapGraph := preload(SceneMapConstants.SCENE_MAP_GRAPH)
const SceneMapIO := preload(SceneMapConstants.SCENE_MAP_IO)

var panel : SceneMapPanel

func _enter_tree() -> void:

	# Waits until the filesystem is fully loaded
	while EditorInterface.get_resource_filesystem().is_scanning():
		await Engine.get_main_loop().process_frame

	SceneMapConstants.PLUGIN_REFERENCE = self

	# Loads the config file and checks if it is ok
	if SM_ResourceTools.check_config_file() != OK:
		EditorInterface.set_plugin_enabled.call_deferred(_get_plugin_name, false)
		return

	# Adds the main panel
	panel = load(SceneMapConstants.PANEL_TSCN).instantiate()
	panel.name = "SceneMapPanel"
	SceneMapConstants.PANEL_REFERENCE = panel
	get_editor_interface().get_editor_main_screen().add_child(panel)
	
	# Adds the graph to the main panel
	var graph : SceneMapGraph = panel.get_node("SceneMapGraph")
	graph.plugin = self

	# Loads the saved data
	SceneMapIO.load(graph)

	# Checks for updates
	_check_for_updates.call_deferred()
	
	_make_visible(false)


func _exit_tree() -> void:
	if panel:
		panel.queue_free()


func _has_main_screen() -> bool:
	return true


func _make_visible(visible : bool) -> void:
	if panel:
		panel.visible = visible


func _get_plugin_name():
	return "SceneMap"


func _get_plugin_icon():
	var svg : Texture2D = load(SceneMapConstants.MAP_ICON)
	var img := svg.get_image()
	img.resize(16, 16, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


## Checks for updates using the AutoUpdater helper.
## If updates are available, shows the update button in the panel.
func _check_for_updates() -> void:
	var auto_updater := SM_AutoUpdater.new(get_tree())
	await auto_updater.check_for_updates()

	if SceneMapConstants.UPDATES_AVAILABLE:
		panel.update_button.toggle_visibility(true)
