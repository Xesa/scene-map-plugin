extends Node


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
	var scene_resource := load_from_uid(scene_uid)
	return scene_resource.resource_path


static func get_name_from_uid(scene_uid : String) -> String:
	var scene_path := get_path_from_uid(scene_uid)
	return get_name_from_path(scene_path)


static func get_name_from_path(scene_path : String) -> String:
	var file_name = scene_path.get_file().get_file()
	var extension = scene_path.get_file().get_extension()
	var temp = file_name.replace("."+extension, "") # Removes the file extension
	return convert_string_to_readable_name(temp)


static func convert_string_to_readable_name(string : String) -> String:
	var temp = string.replace("_", " ") # Replaces underscores for spaces
	var regex = RegEx.new()

	regex.compile("([a-zA-Z])([0-9]+)")
	temp = regex.sub(temp, "$1 $2") # Separates numbers from letters but keeps them united by hyphen

	regex.compile("([a-z])([A-Z])")
	temp = regex.sub(temp, "$1 $2") # Separates camel-case letters

	# Capitalizes each word
	var words = temp.split(" ")
	for i in range(words.size()):
		words[i] = words[i].capitalize()

	var name = " ".join(words)
	return name


static func load_from_uid(scene_uid : String) -> PackedScene:
	var uid := "uid://" + scene_uid if scene_uid != null and scene_uid != "" else null
	if uid != null:
		return load(uid) as PackedScene
	return null