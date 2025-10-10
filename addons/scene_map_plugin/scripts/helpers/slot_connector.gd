extends Node

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_ResourceTools := preload("uid://b71h2bnocse6c")
const SM_ConnectionValidator := preload("uid://btnhphtrcwk72")
const SM_SceneSaver := preload("uid://7svcgc01kw2b")
const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")

static var graph : SceneMapGraph

enum Action {
	CONNECT,
	DISCONNECT,
	UPDATE
}

## Searches and connects two components based on their node and port indexes. This method is used by
## the [SceneMapGraph] to find the [SceneMapSlot] that are part of a connection/disconnection request.
static func make_connection(from_node, from_port, to_node, to_port, connect : bool, _graph : SceneMapGraph) -> void:

	if not graph:
		graph = _graph

	var from_slot := graph.get_slot_info(from_node, from_port, 1)
	var to_slot := graph.get_slot_info(to_node, to_port, 0)

	var connection_type := SM_ConnectionValidator.get_connection_type(from_slot, to_slot, connect)
	var action := Action.CONNECT if connect else Action.DISCONNECT

	# Initiates the scene saver
	await SM_SceneSaver.start()

	match connection_type:
		1:
			await from_slot.update_connection(to_slot, action)
		-1:
			await to_slot.update_connection(from_slot, action)
		2:
			await from_slot.update_connection(to_slot, action)
			await to_slot.update_connection(from_slot, action)

	# Saves all the changes made to the scenes
	await SM_SceneSaver.save()
	SceneMapIO.save(graph)


## Creates, updates or deletes a connection from one [SceneMapSlot] to another, and updates
## [next_scene_uid] and [next_component_uid] metadata values in their associated [SceneMapComponent].[br]
## Once the connection is completed, both [SceneMapSlot] will have their [connected_to]
## and [connected_from] properties updated, pointing to each other.
static func update_connection(from_slot : SceneMapSlot, to_slot : SceneMapSlot, action : Action) -> void:
	
	# Opens the node's scene
	var scene_values := await SM_SceneSaver.open_scene(from_slot.scene_uid)

	var scene_resource : PackedScene = scene_values["resource"]
	var scene_instance : Node = scene_values["instance"]

	# Gets the slots info
	var from_node := from_slot.scene_uid
	var from_port := from_slot.index
	var to_node := to_slot.scene_uid
	var to_port := to_slot.index

	var direction := SM_ConnectionValidator.get_connection_direction(from_slot, to_slot)

	if direction == -1:
		from_node = to_slot.scene_uid
		from_port = to_slot.index
		to_node = from_slot.scene_uid
		to_port = from_slot.index

	# Gets the component
	var component := SM_ComponentFinder.search_component_by_uid(scene_instance, from_slot.component_uid)

	# If the component is inside a packed scene, sets the owner's children as editable
	if component.owner != scene_instance and scene_instance.is_editable_instance(component.owner) == false:
		scene_instance.set_editable_instance(component.owner, true)


	# Updates connection info to the slot
	if action == Action.CONNECT:
		component._set_next_scene(to_slot.scene_uid, to_slot.component_uid)
		await from_slot.add_connection(to_slot, 1)
		await to_slot.add_connection(from_slot, 0)
		graph.connect_node(from_node, from_port, to_node, to_port)
	
	if action == Action.DISCONNECT:
		graph.disconnect_node(from_node, from_port, to_node, to_port)
		await from_slot.remove_connection(to_slot, 1)
		await to_slot.remove_connection(from_slot, 0)
		component._remove_next_scene()