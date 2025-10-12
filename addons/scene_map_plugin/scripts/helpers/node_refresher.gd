extends Node

const SM_SceneSaver := preload("uid://7svcgc01kw2b")
const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")
const SM_SlotRegistrator := preload("uid://bj10g5ips4ubj")


## Iterates through all the graph node's in the SceneMap and checks all the [SceneMapComponent] present
## on their scenes in search for any changes made to the order or names of the components as well as
## if there are new components or any of them have been removed.
static func scan_all_scenes(graph : SceneMapGraph) -> void:

	await SM_SceneSaver.start()

	var node_connections := {}

	for child in graph.get_children():
		if child is SceneMapNode:
			await scan_scene(child)

	await SM_SceneSaver.save()
	SceneMapIO.save(graph)


## Scans one scene in search of any changes and applies those changes to each [SceneMapSlot].
## If there are new [SceneMapComponent], creates the respective [SceneMapSlot]. If any component
## has been removed or modified removes or updates the slot.
static func scan_scene(graph_node : SceneMapNode) -> void:

	# Opens the scene and gets graph edit
	var graph_edit := graph_node.graph_edit
	var slot_registrator := SM_SlotRegistrator.new(graph_node)
	var scene_info := SM_SceneSaver.open_scene(graph_node.scene_uid)

	# Finds all the components currently in the scene
	var components := SM_ComponentFinder.find_all_components(scene_info["instance"])
	var original_connections := graph_edit.get_node_connections(graph_node)
	var updated_connections := original_connections.duplicate(true)

	# Removes all the slots that don't have their component present anymore
	var slot_modifications := get_slots_to_remove(graph_node, components)
	updated_connections = apply_modifications(graph_node, slot_registrator, slot_modifications, original_connections, updated_connections, false)

	# Add the new components
	var component_modifications := get_components_to_add(graph_node, components)
	updated_connections = apply_modifications(graph_node, slot_registrator, component_modifications, original_connections, updated_connections, true)

	# Reorders connections
	await reorder_connections(graph_edit, original_connections, updated_connections)
	await reorder_component_slots(graph_node)

	resize_node.call_deferred(graph_node)
	

## Returns all the components found in the scene and marks them if they are new.
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


## Returns all the slots in the graph node and marks them if their component has been removed from the scene.
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


## Applies the modifications given by the [modifications] array. Such modifications can be
## adding, removing or updating [SceneMapSlot] from the given [SceneMapNode].
## Then, it updates the [updated_connections] array according to the changes made.
static func apply_modifications(graph_node : SceneMapNode, slot_registrator : SM_SlotRegistrator, modifications : Array,
							original_connections : Dictionary, updated_connections : Dictionary, add : bool) -> Dictionary:

	var index_modifier := 0

	for stats in modifications:
		var slot : SceneMapSlot = stats["slot"]
		var component : SceneMapComponent2D = stats["component"]
		var original_index : int = slot.index if slot else -1
		var updated_index : int = stats["index"]

		# If the component was removed, deletes the slot and increases the index modifier
		if !add and stats["is_removed"]:
			slot.delete()
			updated_connections.erase(original_index)
			index_modifier += 1
			
		# If the component was added, adds a new slot
		elif add and stats["is_new"]:
			slot_registrator.slot_counter = updated_index - 1
			var new_slot := slot_registrator.register_new_slot(component)
			graph_node.move_child(new_slot.control, updated_index)
			new_slot._update_slot_configuration()

		# If the component already existed it rearranges the index in case any component was added or removed previously
		# and updates the control's labels to match its new index and name
		else:
			slot.index = updated_index
			slot.component_name = component.get_custom_name()
			graph_node.move_child(slot.control, updated_index)
			slot._update_slot_configuration()
			slot.control.refresh_label()
			updated_connections = update_connection(graph_node, original_connections, updated_connections, original_index, updated_index)
		
	return updated_connections


## Updates a connection based on its original index. This method determines the direction of the connection
## taking in account if the [from_node] or [to_node] properties of the connection point to the graph node's [scene_uid] property.
static func update_connection(graph_node : SceneMapNode, original_connections : Dictionary, updated_connections : Dictionary,
							original_index : int, updated_index : int) -> Dictionary:
	
	if original_connections.has(original_index):
		var connection : Dictionary = original_connections[original_index]

		if connection["from_node"] == graph_node.scene_uid:
			updated_connections[original_index]["from_port"] = updated_index

		elif connection["to_node"] == graph_node.scene_uid:
			updated_connections[original_index]["to_port"] = updated_index

	return updated_connections


## Reorders all the graph edit's connections by disconnecting the old connections and adding the updated ones when needed.
static func reorder_connections(graph_edit : SceneMapGraph, original_connections : Dictionary, updated_connections : Dictionary) -> void:
	
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


## Reorders the [component_slots] array from the [graph_node] according to each slot's [index] property.
static func reorder_component_slots(graph_node : SceneMapNode) -> void:
	var component_slots : Array[SceneMapSlot] = []
	component_slots.resize(graph_node.component_slots.size())

	for slot in graph_node.component_slots:
		component_slots[slot.index-1] = slot

	graph_node.component_slots = component_slots


## Resizes the graph node to fit the new amount of slots.
static func resize_node(graph_node : SceneMapNode) -> void:
	await Engine.get_main_loop().process_frame
	#graph_node.size = graph_node.get_combined_minimum_size()
	#graph_node.queue_redraw()