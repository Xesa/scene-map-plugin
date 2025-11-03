extends Node
## SM_ComponentFinder
##
## Provides utility functions to find and traverse SceneMap components within a scene tree.
##
## Search methods:[br]
## - find_all_components(node): returns an array of all [SceneMapComponent] under the given node[br]
## - search_component_by_uid(node, component_uid): finds a component by its UID[br]
## - get_root_node(node): returns the root node of a given node[br]
## - get_scene_root_uid(node): returns the scene's root UID from a given node[br]
## UID methods:[br]
## - save_component_uid(component_uid, scene_uid): saves a component UID to avoid duplicate conflicts
## - remove_component_uid(component_uid): removes a component UID from the list
## - check_component_uid(component_uid, scene_uid): checks if a component UID is already present in the list

const SM_ResourceTools := preload(SceneMapConstants.RESOURCE_TOOLS)

#region SearchMethods

## Finds all [SceneMapComponent] instances under the given node.
static func find_all_components(node: Node) -> Array:
	var components := []

	_collect_components(node, components)
	return components


## Internal helper function that recursively collects components.
static func _collect_components(node: Node, components: Array) -> void:
	if node.has_method("get_scene_map_component_type"):
		components.append(node)

	for child in node.get_children():
		_collect_components(child, components)


## Searches recursively for a [SceneMapComponent] with the given UID.
static func search_component_by_uid(node: Node, component_uid: String) -> Node:
	if node.has_method("get_scene_map_component_type") and node.get_component_uid() == component_uid:
		return node

	for child in node.get_children():
		var found = search_component_by_uid(child, component_uid)
		if found:
			return found

	return null


## Retrieves the root node in the tree from a given node.
## Traverses up through the owners until the top-most node is reached.
static func get_root_node(node : Node) -> Node:
	while node.owner != null:
		node = node.owner
	return node


## Returns the root node of the give node's scene. If the node belongs to an
## instantiated scene, it will return the root of that scene
## unless the instance is set to have editable children.
static func get_scene_root_uid(node: Node) -> Variant:

	# Returns null if there is no UID
	var root_scene := get_root_node(node)
	if root_scene == null:
		return null

	# Returns the root scene's UID if the node is the root of the scene
	if node == root_scene:
		return SM_ResourceTools.get_uid_from_tscn(root_scene.scene_file_path)

	# Returns the node's UID if the node is the root of an instantiated scene
	if node.scene_file_path != "":
		return SM_ResourceTools.get_uid_from_tscn(node.scene_file_path)

	# Checks if the node belongs to an instantiated scene
	var node_owner := node.get_owner()
	if node_owner != null and node_owner != root_scene:

		# Returns the root scene's UID if the node is an editable child of an instantiated scene
		if root_scene.is_editable_instance(node_owner):
			return SM_ResourceTools.get_uid_from_tscn(root_scene.scene_file_path)

		# Returns the node's owner UID if the node belongs to an instantiated scene
		return SM_ResourceTools.get_uid_from_tscn(node_owner.scene_file_path)

	# Returns the root scene's UID if the node belongs to the root scene
	return SM_ResourceTools.get_uid_from_tscn(root_scene.scene_file_path)

#endregion

#region UIDMethods

## Saves a component UID in a .cfg file. The scene uid must be provided to avoid duplication conflicts.[br]
## The file is stored in [plugin_data/scene_map_plugin] and if the file doesn't exists, it creates a new one.[br]
## See [remove_component_uid()] and [check_component_uid()].
static func save_component_uid(component_uid : String, scene_uid : String) -> void:
	SM_ResourceTools.create_absolute_path(SceneMapConstants.USER_DATA_PATH)
	var uids := ConfigFile.new()
	uids.load(SceneMapConstants.UID_PATH)
	uids.set_value("uids", component_uid, scene_uid)
	uids.save(SceneMapConstants.UID_PATH)


## Removes a component UID from a .cfg file.[br]
## See [save_component_uid()] and [check_component_uid()].
static func remove_component_uid(component_uid : String) -> void:
	SM_ResourceTools.create_absolute_path(SceneMapConstants.USER_DATA_PATH)
	var uids := ConfigFile.new()
	var err := uids.load(SceneMapConstants.UID_PATH)
	if err == OK:
		uids.set_value("uids", component_uid, null)
		uids.save(SceneMapConstants.UID_PATH)


## Checks if a component UID exists in the .cfg file and compares it against the scene's uid.[br]
## - If the component UID exists and the scene's UID matches, it is considered as a valid UID and this method will return [0].[br]
## - If the component UID exists but the scene's UID doesn't match, it is considered a duplicate and this method will return [1].[br]
## - If the component UID doesn't exist in the file, it is considered as a missing value and this method will return [-1].[br]
## See [save_component_uid()] and [remove_component_uid()].
static func check_component_uid(component_uid : String, scene_uid : String) -> int:
	var uids := ConfigFile.new()
	var err := uids.load(SceneMapConstants.UID_PATH)
	if err != OK:
		return -1
	var value = uids.get_value("uids", component_uid, "")
	if value == "":
		return -1
	if value != scene_uid:
		return 1
	return 0


## Removes all unused UIDs from the .cfg file.
static func clear_unused_component_uids() -> void:
	var uids := ConfigFile.new()
	var err := uids.load(SceneMapConstants.UID_PATH)
	if err != OK:
		return

	var keys := uids.get_section_keys("uids")
	var scene_uid : String
	var scene_resource : PackedScene
	var scene_instance : Node

	# Iterates each UID in the file
	for component_uid in keys:
		var current_scene_uid := uids.get_value("uids", component_uid)

		# Instantiates the scene
		if scene_uid != current_scene_uid:
			scene_uid = current_scene_uid
			scene_resource = SM_ResourceTools.load_from_uid(scene_uid)

			if scene_resource == null:
				uids.set_value("uids", component_uid, null)
				continue

			scene_instance = scene_resource.instantiate()

		# If there is no component with that UID, deletes the UID from the file
		if !search_component_by_uid(scene_instance, component_uid):
			uids.set_value("uids", component_uid, null)
	
	uids.save(SceneMapConstants.UID_PATH)

#endregion