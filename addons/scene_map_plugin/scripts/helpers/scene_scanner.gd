extends Node

const SM_SceneSaver := preload("uid://7svcgc01kw2b")
const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")
const SM_SlotRegistrator := preload("uid://bj10g5ips4ubj")


static func scan_all_scenes(graph : SceneMapGraph) -> void:

	SM_SceneSaver.start()

	var node_connections := {}

	for child in graph.get_children():
		if child is SceneMapNode:
			await scan_scene(child)

	SM_SceneSaver.save()
	SceneMapIO.save(graph)


static func scan_scene(graph_node : SceneMapNode) -> void:

	# Opens the scene and gets graph edit
	var graph_edit := graph_node.graph_edit
	var slot_registrator := SM_SlotRegistrator.new(graph_node)
	var scene_info := SM_SceneSaver.open_scene(graph_node.scene_uid)

	# Finds all the components currently in the scene
	var components := SM_ComponentFinder.find_all_components(scene_info["instance"])
	var original_connections := graph_edit.get_node_connections(graph_node)
	var updated_connections := original_connections.duplicate(true)

	print(graph_node.scene_name)
	print()
	print("Original connections:")
	for conn in original_connections:
		print(conn, ": ", original_connections[conn])

	# Removes all the slots that don't have their component present anymore
	var slot_modifications := get_slots_to_remove(graph_node, components)
	print()
	print("Removed connections:")
	updated_connections = apply_modifications(graph_node, slot_registrator, slot_modifications, original_connections, updated_connections, false)

	# Add the new components
	var component_modifications := get_components_to_add(graph_node, components)
	print()
	print("Added or reorganized connections:")
	updated_connections = apply_modifications(graph_node, slot_registrator, component_modifications, original_connections, updated_connections, true)

	# Reorders connections
	reorder_connections(graph_edit, original_connections, updated_connections)

	print()


static func get_components_to_add(graph_node : SceneMapNode, components : Array) -> Array:
	var component_modifications := []
	var index := 0

	for component in components:
		index += 1
		var component_stats := {"index": index, "component": component, "slot": null, "is_new": true}

		for slot in graph_node.component_slots:
			if component.get_component_uid_or_null() != null and component.get_component_uid_or_null() == slot.component_uid:
				component_stats["slot"] = slot
				component_stats["is_new"] = false
				break
		
		component_modifications.append(component_stats)

	return component_modifications


static func get_slots_to_remove(graph_node : SceneMapNode, components : Array) -> Array:
	var slot_modifications := []

	for slot in graph_node.component_slots:
		var slot_stats := {"index": slot.index, "slot": slot, "component": null, "is_removed": true}

		for component in components:
			if component.get_component_uid_or_null() != null and component.get_component_uid_or_null() == slot.component_uid:
				slot_stats["component"] = component
				slot_stats["is_removed"] = false
				break

		slot_modifications.append(slot_stats)

	return slot_modifications


static func apply_modifications(graph_node : SceneMapNode, slot_registrator : SM_SlotRegistrator, modifications : Array,
							original_connections : Dictionary, updated_connections : Dictionary, add : bool) -> Dictionary:

	var index_modifier := 0

	for stats in modifications:
		var slot : SceneMapSlot = stats["slot"]
		var component : SceneMapComponent2D = stats["component"]
		var original_index : int = slot.index if slot else -1
		var updated_index : int = stats["index"]

		if !add and stats["is_removed"]:
			slot.delete()
			updated_connections.erase(original_index)
			index_modifier += 1
			updated_index -= index_modifier
			
		if add and stats["is_new"]:
			slot_registrator.slot_counter = updated_index - 1
			var new_slot := slot_registrator.register_new_slot(component)
			graph_node.move_child(new_slot.control, updated_index)
			new_slot._update_slot_configuration()

		else:
			slot.index = updated_index
			graph_node.move_child(slot.control, updated_index)
			slot._update_slot_configuration()
			updated_connections = update_connection(graph_node, original_connections, updated_connections, original_index, updated_index)
		
	return updated_connections


static func update_connection(graph_node : SceneMapNode, original_connections : Dictionary, updated_connections : Dictionary,
							original_index : int, updated_index : int) -> Dictionary:
	
	if original_connections.has(original_index):
		var connection : Dictionary = original_connections[original_index]

		if connection["from_node"] == graph_node.scene_uid:
			updated_connections[original_index]["from_port"] = updated_index
			print(original_index, " -> ", updated_index," - From: ", updated_connections[original_index])

		elif connection["to_node"] == graph_node.scene_uid:
			updated_connections[original_index]["to_port"] = updated_index
			print(original_index, " -> ", updated_index," - To: ", updated_connections[original_index])

	return updated_connections


static func reorder_connections(graph_edit : SceneMapGraph, original_connections : Dictionary, updated_connections : Dictionary) -> void:
	for original_index in original_connections.keys():

		for connection in graph_edit.connections:

			if connection == original_connections[original_index]:
				var oc := original_connections.get(original_index)

				if updated_connections.has(original_index):
					var uc := updated_connections.get(original_index)
					if oc != uc:
						print("sdfsdf")
						graph_edit.disconnect_node(oc["from_node"], oc["from_port"], oc["to_node"], oc["to_port"])
						graph_edit.connect_node(uc["from_node"], uc["from_port"], uc["to_node"], uc["to_port"])
				else:
					graph_edit.disconnect_node(oc["from_node"], oc["from_port"], oc["to_node"], oc["to_port"])