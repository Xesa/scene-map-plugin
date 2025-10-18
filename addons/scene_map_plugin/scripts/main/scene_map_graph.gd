@tool
extends GraphEdit

const SM_SlotConnector := preload(SceneMapConstants.SLOT_CONNECTOR)
const SM_NodeRegistrator := preload(SceneMapConstants.NODE_REGISTRATOR)
const SM_ConnectionValidator := preload(SceneMapConstants.GRAPH_CONNECTION_VALIDATOR)
const SM_EventBus := preload(SceneMapConstants.EVENT_BUS)
const SM_NodeRefresher := preload(SceneMapConstants.NODE_REFRESHER)
const SceneMap := preload(SceneMapConstants.SCENE_MAP)
const SceneMapNode := preload(SceneMapConstants.SCENE_MAP_NODE)
const SceneMapSlot := preload(SceneMapConstants.SCENE_MAP_SLOT)
const SceneMapIO := preload(SceneMapConstants.SCENE_MAP_IO)

var plugin : SceneMap


func _ready() -> void:
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)
	focus_entered.connect(auto_refresh)
	

func _on_connection_request(from_node, from_port, to_node, to_port) -> void:
	SM_SlotConnector.make_connection(from_node, from_port, to_node, to_port, true, self)
	

func _on_disconnection_request(from_node, from_port, to_node, to_port) -> void:
	SM_SlotConnector.make_connection(from_node, from_port, to_node, to_port, false, self)


func _is_node_hover_valid(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> bool:
	var from_slot := get_slot_info(from_node, from_port, 1)
	var to_slot := get_slot_info(to_node, to_port, 0)

	return SM_ConnectionValidator.get_connection_type(from_slot, to_slot) != 0


## Returns the [SceneMapSlot] allocated in the node and port specified in the parameters.
func get_slot_info(node_index, port, side) -> SceneMapSlot:
	var graph_node : SceneMapNode = get_node(NodePath(node_index))
	return graph_node.get_component_slot(port, side)


func _on_node_deleted(node : SceneMapNode) -> void:
	node.queue_free()
	await Engine.get_main_loop().process_frame
	SceneMapIO.save(self)


func make_connection_by_uid(from_node, from_port, to_node, to_port) -> void:
	var from_graph_node : SceneMapNode = get_node(NodePath(from_node))
	var to_graph_node : SceneMapNode = get_node(NodePath(to_node))

	var from_slot := from_graph_node.get_component_slot_by_uid(from_port)
	var to_slot := to_graph_node.get_component_slot_by_uid(to_port)

	connection_request.emit(from_node, from_slot.index, to_node, to_slot.index)


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


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has("files"):
		for f in data["files"]:
			if f.ends_with(".tscn"):
				return true
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	for file_path in data["files"]:
		if file_path.ends_with(".tscn"):
			SM_NodeRegistrator.register_scene(self, file_path, "", true, at_position)


func force_drag_release(graph_node : SceneMapNode = null):
	if graph_node:
		graph_node.selected = false
		
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	ev.position = get_global_mouse_position()
	gui_input.emit(ev)


func auto_refresh() -> void:
	if SM_EventBus.has_changes():
		await SM_NodeRefresher.scan_all_scenes(self)
		SM_EventBus.clear_changes()
		force_drag_release()