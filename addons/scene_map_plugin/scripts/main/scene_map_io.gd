@tool
extends Node
## Handles saving and loading the SceneMap graph to and from disk.
##
## Converts [SceneMapNodes] and [SceneMapSlots] into resource data for persistence,
## and restores nodes, slots, and their connections when loading.
## Ensures that all scenes and connections are properly initialized and refreshed.

const SM_SlotRegistrator := preload(SceneMapConstants.SLOT_REGISTRATOR)
const SM_GraphResource := preload(SceneMapConstants.GRAPH_RESOURCE)
const SM_NodeResource := preload(SceneMapConstants.NODE_RESOURCE)
const SM_SlotResource := preload(SceneMapConstants.SLOT_RESOURCE)
const SM_NodeRefresher := preload(SceneMapConstants.NODE_REFRESHER)
const SceneMapGraph := preload(SceneMapConstants.SCENE_MAP_GRAPH)
const SceneMapNode := preload(SceneMapConstants.SCENE_MAP_NODE)
const SceneMapSlot := preload(SceneMapConstants.SCENE_MAP_SLOT)


## Saves the given [SceneMapGraph] to disk as a .tres resource.
## Converts each [SceneMapNode] and its [SceneMapSlots] into [SM_NodeResource] and [SM_SlotResource],
## stores connections, and ensures the plugin_data folder exists.
static func save() -> void:

	var graph : SceneMapGraph = Engine.get_singleton("SceneMapPlugin").graph
	var path = SceneMapConstants.USER_DATA_PATH + "graph_1.tres"

	# Creates a new resource
	var resource := SM_GraphResource.new()

	# Adds the graph connections
	resource.connections = graph.connections

	# Iterates each SceneMapNode in the graph and adds it to the resource
	for node in graph.get_children():
		if node is SceneMapNode:
			var node_res := SM_NodeResource.new()
			node_res.offset = node.position_offset
			node_res.scene_name = node.scene_name
			node_res.scene_uid = node.scene_uid
			node_res.component_slots = []

			for slot in node.component_slots:
				var slot_res = SM_SlotResource.new()
				slot_res.slot_id = slot.slot_id
				slot_res.scene_uid = slot.scene_uid
				slot_res.component_uid = slot.component_uid
				slot_res.component_name = slot.component_name
				slot_res.component_name_is_custom = slot.component_name_is_custom

				slot_res.index = slot.index
				slot_res.left = slot.left
				slot_res.right = slot.right
				slot_res.left_icon = slot.left_icon
				slot_res.right_icon = slot.right_icon

				slot_res.type = slot.type
				slot_res.side = slot.side

				slot_res.connected_to_ids = slot.connected_to_ids
				slot_res.connected_from_ids = slot.connected_from_ids
				
				node_res.component_slots.append(slot_res)

			resource.nodes.append(node_res)

	# Creates the plugin_data folder if doesn't exists
	var base_dir := SceneMapConstants.USER_DATA_PATH.get_base_dir()
	var dir := DirAccess.open("res://")
	var subdirs := base_dir.replace("res://", "").split("/")

	for sub in subdirs:
		if sub == "":
			continue
		if not dir.dir_exists(sub):
			dir.make_dir(sub)
		dir.change_dir(sub)

	# Saves the resources in disk
	ResourceSaver.save(resource, path)


## Loads a [SceneMapGraph] from a previously saved .tres resource.
## Reconstructs [SceneMapNodes] and [SceneMapSlots], hydrates their connections,
## reconnects nodes in the graph, and refreshes all scenes.
static func load() -> void:

	var graph : SceneMapGraph = Engine.get_singleton("SceneMapPlugin").graph
	var path = SceneMapConstants.USER_DATA_PATH + "graph_1.tres"

	# Loads the resource
	var graph_resource : SM_GraphResource

	if FileAccess.file_exists(path):
		graph_resource = load(path)

	else:
		return

	var slot_ids : Dictionary[String, SceneMapSlot] = {}

	# Iterates each graph node in the resource
	for node_resource in graph_resource.nodes:

		# Creates an actual graph node
		var node = SceneMapNode.new(node_resource.scene_uid, node_resource.scene_name, false)
		node.position_offset = node_resource.offset

		graph.add_child(node)
		await node.node_ready

		node.set_slot(0, true, -1, Color.TRANSPARENT, true, -1, Color.TRANSPARENT)
		
		# Iterates each slot in the node
		for slot_resource in node_resource.component_slots:
			var slot = SM_SlotRegistrator.new(node).load_existing_slot(slot_resource)
			slot_ids[slot.slot_id] = slot

	# Iterates the slot_ids array and hydrates the connections with actual slots
	for key in slot_ids.keys():
		var slot = slot_ids[key]

		for id in slot.connected_to_ids:
			slot.connected_to.append(slot_ids[id])
			slot.connection_added.emit(slot_ids[id], 1)
			slot_ids[id].connection_added.emit(slot, 0)

		for id in slot.connected_from_ids:
			slot.connected_from.append(slot_ids[id])
			slot.connection_added.emit(slot_ids[id], 0)
			slot_ids[id].connection_added.emit(slot, 1)

	# Iterates the connection dictionary and adds them to the graph
	for conn in graph_resource.connections:
		graph.connect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)

	# Scans all scenes in search of changes
	await Engine.get_main_loop().process_frame
	await SM_NodeRefresher.scan_all_scenes()

	# Checks all the connections for each node
	for node in graph.get_children():
		if node is SceneMapNode:
			node.check_connections()

