extends Node


static func find_all_components(node: Node) -> Dictionary:
	var components := {
		"entrances": [],
		"exits": [],
		"two_ways": [],
		"funnels": []
	}

	_collect_components(node, components)
	return components


static func _collect_components(node: Node, components: Dictionary) -> void:
	if node is SceneMapComponent:
		match node.type:
			SceneMapComponent.Type.ENTRY: components.entrances.append(node)
			SceneMapComponent.Type.EXIT: components.exits.append(node)
			SceneMapComponent.Type.TWO_WAY: components.two_ways.append(node)
			SceneMapComponent.Type.FUNNEL: components.funnels.append(node)

	for child in node.get_children():
		_collect_components(child, components)


static func search_component_by_uid(node: Node, component_uid: String) -> SceneMapComponent:
	if node is SceneMapComponent and node.get_component_uid_or_null() == component_uid:
		return node

	for child in node.get_children():
		var found = search_component_by_uid(child, component_uid)
		if found:
			return found

	return null
