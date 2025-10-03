@tool
class_name ComponentFinder extends SceneMapHelper

var graph_node : SceneMapNode
var slots : Dictionary

func _init(_graph_node : SceneMapNode) -> void:
	graph_node = _graph_node


## Gets all the [SceneMapComponent] paths from the scene.
func find() -> Dictionary:

	slots = {"entrances": [], "exits": [], "two_ways": [], "funnels": []}

	_set_slot_info(graph_node.scene_instance)
	_find_all_children_nodes(graph_node.scene_instance)

	return slots.duplicate(true)


## Iterates every children and sub-children recursively until checking each node in the scene.
func _find_all_children_nodes(node : Node) -> void:
	
	for child in node.get_children():
		_set_slot_info(child)
		_find_all_children_nodes(child) # Loops recursively


## Adds the [SceneMapComponent] path to the correspondent array depending on its type.
func _set_slot_info(child : Node) -> void:

	if child is SceneMapComponent:
		var node_path := graph_node.scene_instance.get_path_to(child)

		var slot := SceneMapSlot.new(
			graph_node.scene_path,
			graph_node.scene_uid,
			node_path,
			child.type,
			child.side)

		graph_node.add_child(slot)

		match child.type:
			SceneMapComponent.Type.ENTRY: slots.entrances.append(slot)
			SceneMapComponent.Type.EXIT: slots.exits.append(slot)
			SceneMapComponent.Type.TWO_WAY: slots.two_ways.append(slot)
			SceneMapComponent.Type.FUNNEL: slots.funnels.append(slot)