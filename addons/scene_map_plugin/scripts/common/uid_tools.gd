extends Node

const SM_Constants := preload("uid://cjynbj0oq1sx1")

static func get_uid_from_tscn(scene_path : String) -> String:

	var file = FileAccess.open(scene_path, FileAccess.READ)

	if not file:
		return ""

	var regex = RegEx.new()
	regex.compile('^\\[gd_scene.*uid="uid://([^"]+)"')

	while not file.eof_reached():
		var line = file.get_line()
		var result = regex.search(line)

		if result:
			file.close()
			return result.get_string(1)

	file.close()
	return ""


static func get_path_from_uid(scene_uid : String) -> String:
	var scene_resource := load("uid://"+scene_uid)
	return scene_resource.resource_path

"""
static func pre_save_scene(scene_path : String) -> void:

	# Saves all the progress
	await Engine.get_main_loop().process_frame
	EditorInterface.save_all_scenes()

	# Reloads the scene to avoid overwriting data
	EditorInterface.reload_scene_from_path(scene_path)
	await Engine.get_main_loop().process_frame


static func post_save_scene(scene_resource : PackedScene, scene_instance : Node, scene_path : String) -> void:

	# Saves the changes to the scene
	scene_resource.pack(scene_instance)
	await ResourceSaver.save(scene_resource, scene_path)
	await Engine.get_main_loop().process_frame

	# Reloads the scene to show the changes in the editor
	EditorInterface.reload_scene_from_path(scene_path)
	await Engine.get_main_loop().process_frame

	# Returns back to the Scene Map screen
	EditorInterface.set_main_screen_editor(SM_Constants.PLUGIN_NAME)
"""