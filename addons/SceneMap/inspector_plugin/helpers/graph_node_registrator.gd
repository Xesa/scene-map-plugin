class_name NodeRegistrator extends SceneMapHelper


static func register_scene(graph : SceneMapGraph, scene_path : String) -> void:

	# Gets the scene UID and checks if it's already in the map
	var scene_uid = SceneMapResourceUIDScrapper.get_uid_from_tscn(scene_path)
	var existing_node : SceneMapNode = graph.get_node_or_null(scene_uid)

	if existing_node:
		printerr(scene_path + " is already in the map.")
		return

	# Adds the graph node to the graph
	var graph_node = SceneMapNode.new(scene_uid, scene_path)
	graph.add_child(graph_node)