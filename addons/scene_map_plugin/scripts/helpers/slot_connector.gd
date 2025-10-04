extends Node

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_ResourceTools := preload("uid://cwik34k5w34y1")
const SM_ConnectionValidator := preload("uid://btnhphtrcwk72")

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

	match connection_type:
		1:
			await from_slot.update_connection(to_slot, action)
		-1:
			await to_slot.update_connection(from_slot, action)
		2:
			await from_slot.update_connection(to_slot, action)
			await to_slot.update_connection(from_slot, action)


static func update_connection(from_slot : SceneMapSlot, to_slot : SceneMapSlot, action : Action ) -> void:
	
	await SM_ResourceTools.pre_save_scene(from_slot.scene_path)

	# Instantiates the node's scene
	var scene_resource := load(from_slot.scene_path) as PackedScene
	var scene_instance := scene_resource.instantiate()

	# Gets the component
	var component : SceneMapComponent = scene_instance.get_node(from_slot.component_path)

	# If the component is inside a packed scene, sets the owner's children as editable
	if component.owner != scene_instance and scene_instance.is_editable_instance(component.owner) == false:
		scene_instance.set_editable_instance(component.owner, true)

	# Sets the component values
	var next_scene_uid = "" if action == Action.DISCONNECT else to_slot.scene_uid
	var next_component_uid = "" if action == Action.DISCONNECT else to_slot.component_uid
	component._set_next_scene(next_scene_uid, next_component_uid)

	# Updates connection info to the slot
	if action == Action.CONNECT:
		from_slot.add_connection(to_slot, true)
		to_slot.add_connection(from_slot, false)
	
	if action == Action.DISCONNECT:
		from_slot.remove_connection(to_slot, true)
		to_slot.remove_connection(from_slot, false)

	# Save both the from scene and the to scene
	await SM_ResourceTools.post_save_scene(scene_resource, scene_instance, from_slot.scene_path)

	EditorInterface.reload_scene_from_path(to_slot.scene_path)
	await Engine.get_main_loop().process_frame

	# Returns back to the Scene Map screen
	EditorInterface.set_main_screen_editor(SM_Constants.PLUGIN_NAME)

	SceneMapIO.save(graph)