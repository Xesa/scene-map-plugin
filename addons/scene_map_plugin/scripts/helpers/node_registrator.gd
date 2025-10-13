extends Node

const SM_ResourceTools := preload("uid://b71h2bnocse6c")


## Registers a new scene to the SceneMap in the form of a [SceneMapNode].
## If the scene is already present in the SceneMap it prints an error.
static func register_scene(
		graph : SceneMapGraph,
		scene_path : String,
		scene_uid : String = "",
		should_register_slots : bool = true,
		at_position : Vector2 = Vector2.ZERO
) -> void:

	# Gets the scene UID if not present
	if scene_uid == "":
		scene_uid = SM_ResourceTools.get_uid_from_tscn(scene_path)

	# Checks if the scene is already in the map
	var existing_node : SceneMapNode = graph.get_node_or_null(scene_uid)
	if existing_node:
		printerr(scene_path + " is already in the map.")
		return

	# Adds the graph node to the graph
	var scene_name = SM_ResourceTools.get_name_from_path(scene_path)
	var graph_node = SceneMapNode.new(graph, scene_uid, scene_name)

	# Calculates the position offset
	var offset : Vector2
	
	if at_position == Vector2.ZERO:
		offset = ((graph.size / 2) + graph.scroll_offset) / graph.zoom
	else:
		offset = (at_position + graph.scroll_offset) / graph.zoom

	graph_node.position_offset = offset

	graph.add_child(graph_node)