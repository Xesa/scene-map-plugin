@tool
extends GraphEdit
## Custom GraphEdit for managing [SceneMapNodes] and their connections.
##
## Handles connection and disconnection requests between [SceneMapSlots],
## validates connections, tracks slot assignments, and supports drag-and-drop
## registration of new scenes. Automatically refreshes nodes when changes occur
## and ensures graph state is saved.

const SM_SlotConnector := preload(SceneMapConstants.SLOT_CONNECTOR)
const SM_NodeRegistrator := preload(SceneMapConstants.NODE_REGISTRATOR)
const SM_ConnectionValidator := preload(SceneMapConstants.GRAPH_CONNECTION_VALIDATOR)
const SM_EventBus := preload(SceneMapConstants.EVENT_BUS)
const SM_NodeRefresher := preload(SceneMapConstants.NODE_REFRESHER)
const SceneMapNode := preload(SceneMapConstants.SCENE_MAP_NODE)
const SceneMapSlot := preload(SceneMapConstants.SCENE_MAP_SLOT)
const SceneMapIO := preload(SceneMapConstants.SCENE_MAP_IO)


func _ready() -> void:
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)
	focus_entered.connect(_auto_refresh)

#region PublicMethods

## Returns the [SceneMapSlot] allocated in the node and port specified in the parameters.
func get_slot_info(node_index, port, side) -> SceneMapSlot:
	var graph_node : SceneMapNode = get_node(NodePath(node_index))
	return graph_node.get_component_slot(port, side)


## Initiates a connection between two nodes using their component UIDs.
## Resolves the slots based on UID and emits a [connection_request] signal.
func make_connection_by_uid(from_node, from_port, to_node, to_port) -> void:
	var from_graph_node : SceneMapNode = get_node(NodePath(from_node))
	var to_graph_node : SceneMapNode = get_node(NodePath(to_node))

	var from_slot := from_graph_node.get_component_slot_by_uid(from_port)
	var to_slot := to_graph_node.get_component_slot_by_uid(to_port)

	connection_request.emit(from_node, from_slot.index, to_node, to_slot.index)


## Returns all connections associated with the given [SceneMapNode].
## Maps each slot index to its connection dictionary.
func get_node_connections(graph_node : SceneMapNode) -> Dictionary:
	var node_connections := {}

	for connection in connections:

		if connection["from_node"] == graph_node.scene_uid:
			var from_slot := get_slot_info(connection["from_node"], connection["from_port"], 1)
			node_connections[from_slot.index] = connection

		if connection["to_node"] == graph_node.scene_uid:
			var to_slot := get_slot_info(connection["to_node"], connection["to_port"], 0)
			node_connections[to_slot.index] = connection

	return node_connections


## Programmatically releases any current drag operation.
## If a node is selected, it deselects it before releasing the drag.
func force_drag_release(graph_node : SceneMapNode = null):
	if graph_node:
		graph_node.selected = false
		
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	ev.position = get_global_mouse_position()
	gui_input.emit(ev)

#endregion

#region PrivateMethods

## Handles a connection request between two nodes and delegates it to [SM_SlotConnector].
func _on_connection_request(from_node, from_port, to_node, to_port) -> void:
	SM_SlotConnector.make_connection(from_node, from_port, to_node, to_port, true)


## Handles a disconnection request between two nodes and delegates it to [SM_SlotConnector].
func _on_disconnection_request(from_node, from_port, to_node, to_port) -> void:
	SM_SlotConnector.make_connection(from_node, from_port, to_node, to_port, false)


## Determines if a connection between the given nodes and ports is valid.
## Returns true if the connection is allowed, false otherwise.
func _is_node_hover_valid(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> bool:
	var from_slot := get_slot_info(from_node, from_port, 1)
	var to_slot := get_slot_info(to_node, to_port, 0)

	return SM_ConnectionValidator.get_connection_type(from_slot, to_slot) != 0


## Handles cleanup when a SceneMapNode is deleted.
## Queues the node for deletion and saves the current graph state.
func _on_node_deleted(node : SceneMapNode) -> void:
	node.queue_free()
	await Engine.get_main_loop().process_frame
	SceneMapIO.save()


## Determines whether the dragged data can be dropped onto the graph.
## Accepts only .tscn files.
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has("files"):
		for f in data["files"]:
			if f.ends_with(".tscn"):
				return true
	return false


## Handles the actual dropping of scene files onto the graph.
## Registers each dropped .tscn file as a new [SceneMapNode].
func _drop_data(at_position: Vector2, data: Variant) -> void:
	for file_path in data["files"]:
		if file_path.ends_with(".tscn"):
			SM_NodeRegistrator.register_scene(file_path, "", true, at_position)


## Automatically refreshes all nodes if there are changes flagged in [SM_EventBus].
## Calls [SM_NodeRefresher] to scan all scenes and then clears the event bus.
func _auto_refresh() -> void:
	if SM_EventBus.has_changes():
		await SM_NodeRefresher.scan_all_scenes()
		SM_EventBus.clear_changes()
		force_drag_release()

#endregion