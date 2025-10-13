extends Node


static func find_all_components(node: Node) -> Array:
	var components := []

	_collect_components(node, components)
	return components


static func _collect_components(node: Node, components: Array) -> void:
	if node is SceneMapComponent2D:
		components.append(node)

	for child in node.get_children():
		_collect_components(child, components)


static func search_component_by_uid(node: Node, component_uid: String) -> SceneMapComponent2D:
	if node is SceneMapComponent2D and node.get_component_uid() == component_uid:
		return node

	for child in node.get_children():
		var found = search_component_by_uid(child, component_uid)
		if found:
			return found

	return null


static func get_root_node(node : Node) -> Node:
	while node.owner != null:
		node = node.owner
	return node
