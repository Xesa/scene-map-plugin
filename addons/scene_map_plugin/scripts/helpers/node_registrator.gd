extends Node

const SM_ResourceTools := preload("uid://b71h2bnocse6c")


static func register_scene(
		graph : SceneMapGraph,
		scene_path : String,
		scene_uid : String = "",
		shoud_register_slots : bool = true
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
	var graph_node = SceneMapNode.new(scene_uid, scene_name)
	graph.add_child(graph_node)