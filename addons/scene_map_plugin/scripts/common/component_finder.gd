extends Node
## SM_ComponentFinder
##
## Provides utility functions to find and traverse SceneMap components within a scene tree.
##
## Main methods:[br]
## - find_all_components(node): returns an array of all [SceneMapComponent] under the given node[br]
## - search_component_by_uid(node, component_uid): finds a component by its UID[br]
## - get_root_node(node): returns the root node of a given node[br]


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


## Retrieves the root node of the given node.
## Traverses up through the owners until the top-most node is reached.
static func get_root_node(node : Node) -> Node:
	while node.owner != null:
		node = node.owner
	return node
