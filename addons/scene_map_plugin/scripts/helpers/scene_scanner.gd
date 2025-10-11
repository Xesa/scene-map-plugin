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
	var scene_info := SM_SceneSaver.open_scene(graph_node.scene_uid)

	# Finds all the components currently in the scene
	var components := SM_ComponentFinder.find_all_components(scene_info["instance"])
	var original_connections := graph_edit.get_node_connections(graph_node)
	var updated_connections := original_connections.duplicate(true)

	print(graph_node.scene_name)
	for conn in original_connections:
		print(conn, ": ", original_connections[conn])

	# Removes all the slots that don't have their component present anymore
	var slot_modifications := get_slots_to_remove(graph_node, components)
	var index_modifier := 0

	for slot_stats in slot_modifications:
		var slot : SceneMapSlot = slot_stats["slot"]
		var connection_index : int = slot_stats["index"]

		if slot_stats["is_removed"]:
			slot.delete()
			updated_connections.erase(connection_index)
			index_modifier += 1

		else:
			slot.index -= index_modifier
			slot._update_slot_configuration()

			if original_connections.has(connection_index):
				var connection : Dictionary = original_connections[connection_index]

				if connection["from_node"] == graph_node.scene_uid:
					updated_connections[connection_index]["from_port"] -= index_modifier
					#print("From: ", updated_connections[connection_index])

				elif connection["to_node"] == graph_node.scene_uid:
					updated_connections[connection_index]["to_port"] -= index_modifier
					#print("To: ", updated_connections[connection_index])

	# Add the new components
	var slot_registrator := SM_SlotRegistrator.new(graph_node)
	var component_modifications := get_components_to_add(graph_node, components)

	for component_stats in component_modifications:
		var component : SceneMapComponent2D = component_stats["component"]
		var component_index : int = component_stats["index"]
		
		if !component_stats["is_new"]:
			var slot : SceneMapSlot = component_stats["slot"]
			var original_index := slot.index
			slot.index = component_index
			graph_node.move_child(slot.control, component_index)
			slot._update_slot_configuration()

			if original_connections.has(original_index):
				var connection : Dictionary = original_connections[original_index]

				if connection["from_node"] == graph_node.scene_uid:
					updated_connections[original_index]["from_port"] = component_index
					print("From: ", updated_connections[original_index])

				elif connection["to_node"] == graph_node.scene_uid:
					updated_connections[original_index]["to_port"] = component_index
					print("To: ", updated_connections[original_index])

		else:
			slot_registrator.slot_counter = component_index - 1
			var slot := slot_registrator.register_new_slot(component)
			graph_node.move_child(slot.control, component_index)
			slot._update_slot_configuration()

		print(component_index, ": ", component.name)

	# Reorders connections
	for original_index in original_connections.keys():

		for connection in graph_edit.connections:

			if connection == original_connections[original_index]:
				var oc := original_connections.get(original_index)

				if updated_connections.has(original_index):
					var uc := updated_connections.get(original_index)
					if oc != uc:
						graph_edit.disconnect_node(oc["from_node"], oc["from_port"], oc["to_node"], oc["to_port"])
						graph_edit.connect_node(uc["from_node"], uc["from_port"], uc["to_node"], uc["to_port"])
				else:
					graph_edit.disconnect_node(oc["from_node"], oc["from_port"], oc["to_node"], oc["to_port"])



	print(graph_edit.connections)
	print()

	




static func get_components_to_add(graph_node : SceneMapNode, components : Array) -> Array:
	var component_modifications := []
	var index := 0

	for component in components:
		index += 1
		var component_stats := {"index": index, "component": component, "slot": null, "is_new": true}

		for slot in graph_node.component_slots:
			if component.has_meta(&"_component_uid") and component.get_meta(&"_component_uid") == slot.component_uid:
				component_stats["slot"] = slot
				component_stats["is_new"] = false
				break
		
		component_modifications.append(component_stats)

	return component_modifications


static func get_slots_to_remove(graph_node : SceneMapNode, components : Array) -> Array:
	var slot_modifications := []
	var index := 0

	for slot in graph_node.component_slots:
		index += 1
		var slot_stats := {"index": index, "slot": slot, "component": null, "is_removed": true}

		for component in components:
			if component.has_meta(&"_component_uid") and component.get_meta(&"_component_uid") == slot.component_uid:
				slot_stats["component"] = component
				slot_stats["is_removed"] = false
				break

		slot_modifications.append(slot_stats)

	return slot_modifications