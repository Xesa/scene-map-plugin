extends Node
## SM_SceneSaver
##
## SceneManager is responsible for opening, caching, and saving scenes in the editor.
##
## To start a save process, call [start()] first. Then, add scenes using [open_scene()]. 
## Adding the same scene twice won't duplicate it; the cached instance is reused.
## Finally, call [save()] to write all cached scenes to disk, reload them in the editor,
## and clear the memory. The editor returns to the plugin's main screen afterward.
##
## Main methods:[br]
## - start(): prepares the manager, saves unsaved scenes, and clears cache.[br]
## - open_scene(scene_uid): loads, instantiates, and stores a scene by UID.[br]
## - save(): saves all opened scenes, reloads them in the editor, and clears cache.[br]
## Helper methods: [br]
## - has_pending_changes(): checks if there is any change pending to save.[br]
## - is_scene_open(scene_uid): checks if a scene is currently open in the editor.


const SM_ResourceTools := preload(SceneMapConstants.RESOURCE_TOOLS)
const SM_NodeRefresher := preload(SceneMapConstants.NODE_REFRESHER)
const SM_EventBus := preload(SceneMapConstants.EVENT_BUS)

static var scenes := {}
static var scene_tabs : TabBar

#region MainMethods

## Call this method first when starting a new save process.
## This method initializes the manager, saves any unsaved scenes in the editor and clears cache.
static func start() -> void:
	await Engine.get_main_loop().process_frame
	
	_get_scene_tabs()

	# Iterates each opened scene in search of unsaved changes
	var any_unsaved_scene := false
	for i in range(0, scene_tabs.tab_count):
		if scene_tabs.get_tab_title(i).ends_with("(*)"):
			any_unsaved_scene = true
			break

	# If there is any unsaved scene, saves them all
	if any_unsaved_scene:
		EditorInterface.save_all_scenes()
		
	
	scenes = {}


## Call this method for each scene that needs to be saved in this saving process.
## Each scene added by this method will be instantiated and ready to be edited.
## If the same scene is opened twice, the copy in memory will be reused instead of creating a new one.[br]
## Returns a dictionary that contains:[br]
## - "resource": The PackedScene resource.[br]
## - "instance": The instantiated scene node.[br]
## - "path": The scene's file path.[br]
static func open_scene(scene_uid : String) -> Dictionary:

	# If the scene is already open returns it
	if scenes.get(scene_uid):
		if ResourceLoader.exists(scenes[scene_uid]["path"]):
			return scenes[scene_uid]

		# If the scene was deleted, removes it from the list
		else:
			scenes.erase(scene_uid)
			return {}

	# If the scene is not open, loads the resource and instantiates the scene
	var scene_resource : PackedScene = SM_ResourceTools.load_from_uid(scene_uid)

	if !scene_resource:
		return {}

	var scene_instance : Node = scene_resource.instantiate()
	var scene_path := scene_resource.resource_path

	# Appends the opened scene to the dictionary
	scenes[scene_uid] = {
		"resource" : scene_resource,
		"instance" : scene_instance,
		"path" : scene_path
	}

	return scenes[scene_uid]
	

# Saves all cached scenes to disk, reloads them in the editor to reflect changes,
# frees scene instances from memory, and clears the cache.
# After saving, the editor returns to the plugin's main screen.
static func save() -> void:

	# Iterates each scene in the dictionary
	for scene in scenes.values():
		var scene_resource : PackedScene = scene["resource"]
		var scene_instance : Node = scene["instance"]
		var scene_path : String = scene["path"]

		# Saves the new changes to the scene
		scene_resource.pack(scene_instance)
		await ResourceSaver.save(scene_resource, scene_path)
		#await Engine.get_main_loop().process_frame

		# Reloads the scene to show the changes in the editor
		EditorInterface.reload_scene_from_path(scene_path)
		await Engine.get_main_loop().process_frame

		scene_instance.queue_free()

	scenes = {}

	# Returns back to the Scene Map screen
	EditorInterface.set_main_screen_editor(SceneMapConstants.PLUGIN_NAME)


#endregion

#region HelperMethods

## Returns [true] if there are pending saves.
static func has_pending_changes() -> bool:
	return scenes != null and scenes.size() > 0


## Returns [true] if the given scene is currently open in the editor.
static func is_scene_open(scene_uid : String) -> bool:
	var open_scenes := EditorInterface.get_open_scenes()
	var scene_path := SM_ResourceTools.get_path_from_uid(scene_uid)
	return open_scenes.has(scene_path)


## Finds and caches the TabBar that contains the editor's scene tabs.
static func _get_scene_tabs() -> void:
	if scene_tabs == null:
		var base_control := EditorInterface.get_base_control()
		var scene_tabs_container := base_control.find_child("*EditorSceneTabs*", true, false)
		scene_tabs = scene_tabs_container.find_child("*TabBar*", true, false)

#endregion