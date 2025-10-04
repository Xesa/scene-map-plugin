extends Node

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_ResourceTools := preload("uid://cwik34k5w34y1")
const SM_ConnectionValidator := preload("uid://btnhphtrcwk72")
const SM_SceneSaver := preload("uid://7svcgc01kw2b")
const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")

static var graph : SceneMapGraph

enum Action {
	CONNECT,
	DISCONNECT,
	UPDATE
}

## Connects two components depending on their connection type. If the connection goes from left to right,
## connects the [from_slot] to the [to_slot] or viceversa in case the connection goes from right to left.
## For double sided connections, it connects both slots in both ways.
static func make_connection(from_node, from_port, to_node, to_port, connect : bool, _graph : SceneMapGraph) -> void:

	if not graph:
		graph = _graph

	var from_slot := graph.get_slot_info(from_node, from_port)
	var to_slot := graph.get_slot_info(to_node, to_port)

	var connection_type := SM_ConnectionValidator.get_connection_type(from_slot, to_slot)
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


static func update_connection(from_slot : SceneMapSlot, to_slot : SceneMapSlot, action : Action ) -> void:
	
	# Opens the node's scene
	var scene_values := await SM_SceneSaver.open_scene(from_slot.scene_uid)

	var scene_resource : PackedScene = scene_values["resource"]
	var scene_instance : Node = scene_values["instance"]

	# Gets the component
	var component := SM_ComponentFinder.search_component_by_uid(scene_instance, from_slot.component_uid)
	

	# If the component is inside a packed scene, sets the owner's children as editable
	if component.owner != scene_instance and scene_instance.is_editable_instance(component.owner) == false:
		scene_instance.set_editable_instance(component.owner, true)

	# Updates connection info to the slot
	if action == Action.CONNECT:
		component._set_next_scene(to_slot.scene_uid, to_slot.component_uid)
		await from_slot.add_connection(to_slot, true)
		await to_slot.add_connection(from_slot, false)
	
	if action == Action.DISCONNECT:
		await from_slot.remove_connection(to_slot, true)
		await to_slot.remove_connection(from_slot, false)
		component._remove_next_scene()