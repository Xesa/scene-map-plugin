@tool
class_name SceneMapIO extends Node


static func save(graph : SceneMapGraph) -> void:

	return

	var path = SceneMapConstants.USER_DATA_PATH + "test.tres"

	# Creates a new resource
	var resource := SceneMapResource.new()

	# Adds the graph connections
	resource.connections = graph.connections

	# Iterates each SceneMapNode in the graph and adds it to the resource
	for node in graph.get_children():
		if node is SceneMapNode:
			var node_res := SceneMapNodeResource.new()
			node_res.offset = node.position_offset
			node_res.scene_path = node.scene_path
			node_res.component_slots = []

			for slot in node.component_slots:
				var slot_res = SceneMapSlotResource.new()
				slot_res.slot_id = slot.slot_id
				slot_res.index = slot.index
				slot_res.specific_index = slot.specific_index
				slot_res.left = slot.left
				slot_res.right = slot.right
				slot_res.scene_path = slot.scene_path
				slot_res.component_path = slot.component_path
				slot_res.type = slot.type
				slot_res.side = slot.side
				slot_res.type_string = slot.type_string
				slot_res.connected_to_ids = slot.connected_to_ids
				slot_res.connected_from_ids = slot.connected_from_ids
				
				node_res.component_slots.append(slot_res)

			resource.nodes.append(node_res)

	# Saves the resource in disk
	#ResourceSaver.save(resource, path)


static func load(graph : SceneMapGraph) -> void:

	return

	var path = SceneMapConstants.USER_DATA_PATH + "test.tres"

	# Loads the resource
	var resource : SceneMapResource

	if FileAccess.file_exists(path):
		resource = load(path)

	var slot_ids : Dictionary[String, SceneMapSlot] = {}

	# Iterates each graph node in the resource
	for node_resource in resource.nodes:

		# Creates an actual graph node
		var node = SceneMapNode.new(node_resource.scene_uid, node_resource.scene_path, false)
		node.component_slots = node_resource.component_slots
		node.position_offset = node_resource.offset

		graph.add_child(node)
		
		# Iterates each slot in the node
		for slot in node.component_slots:

			slot_ids[slot.slot_id] = slot

			# Retrieves the actual component and adds it to the slot
			var scene_instance = load(slot.scene_path).instantiate()
			var component = scene_instance.get_node(slot.component_path)
			slot.component = component
			
			# Creates a label
			var label = Label.new()
			label.text = "%s %d" % [slot.type_string, slot.index]
			node.add_child(label)

			# Sets the slot to the node
			node.set_slot(slot.index, slot.left, 0, Color.WHITE, slot.right, 0, Color.WHITE)


	# Iterates the slot_ids array and hydrates the connections with actual slots
	for key in slot_ids.keys():
		var slot = slot_ids[key]

		for id in slot.connected_to_ids:
			slot.connected_to.append(slot_ids[id])

		for id in slot.connected_from_ids:
			slot.connected_from.append(slot_ids[id])

	# Iterates the connection dictionary and adds them to the graph
	for conn in resource.connections:
		graph.connect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)

