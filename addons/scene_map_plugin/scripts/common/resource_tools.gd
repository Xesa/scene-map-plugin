extends Node
## SM_ResourceTools
##
## Provides helper methods for working with SceneMap scenes, UIDs, names, and plugin configuration.
##
## UID methods:[br]
## - get_uid_from_tscn(): get UID from .tscn file[br]
## - get_path_from_uid(): get scene path from UID[br]
## - get_name_from_uid(): get readable name from UID[br]
## - get_name_from_path(): get readable name from path[br]
## - load_from_uid(): load PackedScene from UID[br][br]
##
## Config methods:[br]
## - load_config(): read plugin config value[br]
## - save_config(): write plugin config value[br]
## - check_config_file(): load config and update version[br][br]
##
## String methods:[br]
## - convert_string_to_readable_name(): format string nicely


#region UIDMethods

## Extracts the UID from a .tscn file at the given path.
## Returns an empty string if the file cannot be read or UID is not found.
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


## Returns the resource path of a scene given its UID.
static func get_path_from_uid(scene_uid : String) -> String:
	var scene_resource := load_from_uid(scene_uid)
	return scene_resource.resource_path


## Returns a readable name of a scene given its UID.
static func get_name_from_uid(scene_uid : String) -> String:
	var scene_path := get_path_from_uid(scene_uid)
	return get_name_from_path(scene_path)


## Returns a readable name of a scene given its path.
static func get_name_from_path(scene_path : String) -> String:
	var file_name = scene_path.get_file().get_file()
	var extension = scene_path.get_file().get_extension()
	var temp = file_name.replace("."+extension, "") # Removes the file extension
	return convert_string_to_readable_name(temp)


## Loads a PackedScene resource from its UID.
## Returns null if the UID is invalid or empty.
static func load_from_uid(scene_uid : String) -> PackedScene:
	var uid := "uid://" + scene_uid if scene_uid != null and scene_uid != "" else null
	if uid != null:
		return load(uid) as PackedScene
	return null

#endregion

#region ConfigMethods

## Reads a value from the plugin configuration file.
## Returns [default_value] if the key does not exist or config file cannot be loaded.
static func load_config(key : String, default_value : Variant) -> Variant:
	var cfg = ConfigFile.new()
	var err = cfg.load(SceneMapConstants.CONFIG_PATH)

	if err == OK:
		return cfg.get_value("plugin", key, default_value)
	
	return default_value


## Saves a value to the plugin configuration file.
static func save_config(key : String, value : Variant) -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(SceneMapConstants.CONFIG_PATH)

	if err == OK:
		cfg.set_value("plugin", key, value)
		cfg.save(SceneMapConstants.CONFIG_PATH)


## Checks and loads the plugin configuration file.
## Sets [SceneMapConstants.VERSION] if successful.
static func check_config_file() -> int:
	var config := ConfigFile.new()
	var err := config.load(SceneMapConstants.CONFIG_PATH)

	if err == OK:
		SceneMapConstants.VERSION = config.get_value("plugin", "version")
	else:
		printerr("Error loading .cfg file. Please, reinstall the plugin")

	return err

#endregion

#region StringMethods

## Converts a string into a more readable name format.
## Replaces underscores, separates camel-case and numbers, and capitalizes words.
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

#endregion