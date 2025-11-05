@tool
extends EditorPlugin

const SM_AutoUpdater := preload(SceneMapConstants.AUTO_UPDATER)
const SM_ResourceTools := preload(SceneMapConstants.RESOURCE_TOOLS)
const SM_ComponentFinder := preload(SceneMapConstants.COMPONENT_FINDER)
const SceneMap := preload(SceneMapConstants.SCENE_MAP)
const SceneMapPanel := preload(SceneMapConstants.SCENE_MAP_PANEL)
const SceneMapGraph := preload(SceneMapConstants.SCENE_MAP_GRAPH)
const SceneMapIO := preload(SceneMapConstants.SCENE_MAP_IO)

# References
var panel : SceneMapPanel
var graph : SceneMapGraph

# Variables
static var VERSION : String
static var LATEST_VERSION : String
static var LATEST_URL : String
static var UPDATES_AVAILABLE := false
static var GITHUB_TOKEN : String


func _enter_tree() -> void:

	# Waits until the filesystem is fully loaded
	while EditorInterface.get_resource_filesystem().is_scanning():
		await Engine.get_main_loop().process_frame

	# Sets this instance as singleton
	Engine.register_singleton("SceneMapPlugin", self)

	# Loads the config file and checks if it is ok
	if SM_ResourceTools.check_config_file() != OK:
		EditorInterface.set_plugin_enabled.call_deferred(_get_plugin_name, false)
		return

	# Adds the main panel
	panel = load(SceneMapConstants.PANEL_TSCN).instantiate()
	panel.name = "SceneMapPanel"
	get_editor_interface().get_editor_main_screen().add_child(panel)
	
	# Adds the plugin's reference to the graph
	graph = panel.get_node("SceneMapGraph")

	# Loads the saved data
	SceneMapIO.load()

	# Clears all unused component UIDs
	SM_ComponentFinder.clear_unused_component_uids()

	# Checks for updates
	_check_for_updates.call_deferred()
	
	_make_visible(false)


func _exit_tree() -> void:
	Engine.unregister_singleton("SceneMapPlugin")
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
func _check_for_updates() -> void:
	var auto_updater := SM_AutoUpdater.new()
	await auto_updater.check_for_updates()