@tool
class_name SceneMapIO extends Node

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_GraphResource := preload("uid://c2qiuif0u7poj")
const SM_NodeResource := preload("uid://cu1fsenurp8wr")
const SM_SlotResource := preload("uid://p2mmnni4huyo")


static func save(graph : SceneMapGraph) -> void:

	var path = SM_Constants.USER_DATA_PATH + "graph_1.tres"

	# Creates a new resource
	var resource := SM_GraphResource.new()

	# Adds the graph connections
	resource.connections = graph.connections

	# Iterates each SceneMapNode in the graph and adds it to the resource
	for node in graph.get_children():
		if node is SceneMapNode:
			var node_res := SM_NodeResource.new()
			node_res.offset = node.position_offset
			node_res.scene_path = node.scene_path
			node_res.scene_uid = node.scene_uid
			node_res.component_slots = []

			for slot in node.component_slots:
				var slot_res = SM_SlotResource.new()
				slot_res.slot_id = slot.slot_id
				slot_res.scene_uid = slot.scene_uid
				slot_res.component_uid = slot.component_uid

				slot_res.index = slot.index
				slot_res.specific_index = slot.specific_index
				slot_res.left = slot.left
				slot_res.right = slot.right
				slot_res.left_icon = slot.left_icon
				slot_res.right_icon = slot.right_icon

				slot_res.type = slot.type
				slot_res.side = slot.side
				slot_res.type_string = slot.type_string

				slot_res.connected_to_ids = slot.connected_to_ids
				slot_res.connected_from_ids = slot.connected_from_ids
				
				node_res.component_slots.append(slot_res)

			resource.nodes.append(node_res)

	# Saves the resource in disk
	ResourceSaver.save(resource, path)


static func load(graph : SceneMapGraph) -> void:

	var path = SM_Constants.USER_DATA_PATH + "graph_1.tres"

	# Loads the resource
	var graph_resource : SM_GraphResource

	if FileAccess.file_exists(path):
		graph_resource = load(path)

	var slot_ids : Dictionary[String, SceneMapSlot] = {}

	# Iterates each graph node in the resource
	for node_resource in graph_resource.nodes:

		# Creates an actual graph node
		var node = SceneMapNode.new(node_resource.scene_uid, node_resource.scene_path, false)
		node.position_offset = node_resource.offset

		graph.add_child(node)
		await node.node_ready

		node.set_slot(0, true, 1, Color.TRANSPARENT, true, 1, Color.TRANSPARENT)
		
		# Iterates each slot in the node
		for slot_resource in node_resource.component_slots:

			var slot := SceneMapSlot.new(
				slot_resource.type,
				slot_resource.side,
				slot_resource.index,
				slot_resource.specific_index,
				slot_resource.left,
				slot_resource.right,
				slot_resource.left_icon,
				slot_resource.right_icon,
				slot_resource.scene_uid,
				slot_resource.component_uid
			)

			slot_ids[slot.slot_id] = slot
			
			# Creates a label
			var label = Label.new()
			label.text = "%s %d" % [slot.type_string, slot.index]
			node.add_child(label)

			# Loads the icons
			var left_icon := load(slot_resource.left_icon)
			var right_icon := load(slot_resource.right_icon)

			# Sets the slot to the node
			node.set_slot(slot.index, slot.left, 0, Color.WHITE, slot.right, 0, Color.WHITE, left_icon, right_icon)
			node.component_slots.append(slot)
			node.add_child(slot)


	# Iterates the slot_ids array and hydrates the connections with actual slots
	for key in slot_ids.keys():
		var slot = slot_ids[key]

		for id in slot.connected_to_ids:
			slot.connected_to.append(slot_ids[id])

		for id in slot.connected_from_ids:
			slot.connected_from.append(slot_ids[id])

	# Iterates the connection dictionary and adds them to the graph
	for conn in graph_resource.connections:
		graph.connect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)

