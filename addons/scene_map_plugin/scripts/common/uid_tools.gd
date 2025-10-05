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
	var scene_resource : PackedScene = load_from_uid(scene_uid)
	return scene_resource.resource_path


static func load_from_uid(scene_uid : String) -> PackedScene:
	var uid := "uid://" + scene_uid if scene_uid != null and scene_uid != "" else null
	if uid != null:
		return load(uid) as PackedScene
	return null