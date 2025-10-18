extends Node

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_ResourceTools := preload("uid://b71h2bnocse6c")
const SM_NodeRefresher := preload("uid://up5v7v7p5u60")
const SM_EventBus := preload("uid://xyfuxcmkl0hb")


static var scenes := {}
static var scene_tabs : TabBar


static func get_scene_tabs() -> void:
	if scene_tabs == null:
		var base_control := EditorInterface.get_base_control()
		var scene_tabs_container := base_control.find_child("*EditorSceneTabs*", true, false)
		scene_tabs = scene_tabs_container.find_child("*TabBar*", true, false)


static func start() -> void:
	await Engine.get_main_loop().process_frame
	
	get_scene_tabs()

	var any_unsaved_scene := false
	for i in range(0, scene_tabs.tab_count):
		if scene_tabs.get_tab_title(i).ends_with("(*)"):
			any_unsaved_scene = true
			break

	if any_unsaved_scene:
		EditorInterface.save_all_scenes()
		
	
	scenes = {}


static func open_scene(scene_uid : String) -> Dictionary:

	# If the scene is already open returns it
	if scenes.get(scene_uid):
		return scenes[scene_uid]

	# If the scene is not open, loads the resource and instantiates the scene
	var scene_resource : PackedScene = SM_ResourceTools.load_from_uid(scene_uid)
	var scene_instance : Node = scene_resource.instantiate()
	var scene_path := scene_resource.resource_path

	# Appends the opened scene to the dictionary
	scenes[scene_uid] = {
		"resource" : scene_resource,
		"instance" : scene_instance,
		"path" : scene_path
	}

	return scenes[scene_uid]
	

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
	EditorInterface.set_main_screen_editor(SM_Constants.PLUGIN_NAME)