@tool
class_name SceneMapSlot extends Node

const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")
const SM_SlotConnector := preload("uid://1mcwq8t36pgx")
const SM_ResourceTools := preload("uid://b71h2bnocse6c")
const SM_SceneSaver := preload("uid://7svcgc01kw2b")

var slot_id : String
var index : int
var specific_index : int

var left : bool
var right : bool
var left_icon : String
var right_icon : String

var scene_uid : String
var component_uid : String
var component_name : String

var type : SceneMapComponent2D.Type
var side : SceneMapComponent2D.Side
var type_string : String

var connected_to_ids : Array[String]
var connected_from_ids : Array[String]

var connected_to : Array[SceneMapSlot]
var connected_from : Array[SceneMapSlot]

signal connection_added(connection : SceneMapSlot, direction : int)
signal connection_removed(connection : SceneMapSlot, direction : int)


func _init(_type : SceneMapComponent2D.Type = 0, _side : SceneMapComponent2D.Side = 0,
		_index : int = 0, _specific_index : int = 0,
		_left : bool = false, _right : bool = false,
		_left_icon : String = "", _right_icon : String = "",
		_scene_uid : String = "", _component_name = "", _component_uid = null, )-> void:
	
	if _component_uid:
		component_uid = _component_uid
	else:
		component_uid = str(ResourceUID.create_id())

	scene_uid = _scene_uid
	component_name = _component_name
	slot_id = scene_uid + ":" + component_uid

	side = _side
	index = _index
	specific_index = _specific_index
	left = _left
	right = _right
	left_icon = _left_icon
	right_icon = _right_icon

	connected_to = []
	connected_from = []

	_set_type(_type)


func _set_type(_type : SceneMapComponent2D.Type) -> void:
	type = _type
	match type:
		SceneMapComponent2D.Type.ENTRY: type_string = "Entrance"
		SceneMapComponent2D.Type.EXIT: type_string = "Exit"
		SceneMapComponent2D.Type.TWO_WAY: type_string = "Two-way"
		SceneMapComponent2D.Type.FUNNEL: type_string = "Funnel"


func add_connection(connection : SceneMapSlot, direction : int) -> void:
	if direction == 1 and not connected_to.has(connection):
		connected_to.append(connection)
		connected_to_ids.append(connection.slot_id)
		connection_added.emit(connection, direction)
	elif direction == 0 and not connected_from.has(connection): 
		connected_from.append(connection)
		connected_from_ids.append(connection.slot_id)
		connection_added.emit(connection, direction)


func remove_connection(connection : SceneMapSlot, direction : int) -> void:
	if direction == 1:
		connected_to.erase(connection)
		connected_to_ids.erase(connection.slot_id)
	else:
		connected_from.erase(connection)
		connected_from_ids.erase(connection.slot_id)

	connection_removed.emit(connection, direction)


func has_incoming_connections() -> bool:
	if connected_from == null:
		return false
	return connected_from.size() > 0


func has_outgoing_connections() -> bool:
	if connected_to == null:
		return false
	return connected_to.size() > 0


func get_connections(direction : int) -> Array[SceneMapSlot]:
	if direction == 1:
		return connected_to
	else:
		return connected_from


func get_all_connections() -> Array[SceneMapSlot]:
	var all_connections : Array[SceneMapSlot] = []
	all_connections.append_array(get_connections(1))
	all_connections.append_array(get_connections(0))
	return all_connections


func remove_all_connections() -> void:

	# Iterates every connected slot and removes the connection
	for to_slot in get_connections(true):
		await update_connection(to_slot, SM_SlotConnector.Action.DISCONNECT)

	for from_slot in get_connections(false):
		await from_slot.update_connection(self, SM_SlotConnector.Action.DISCONNECT)


func delete() -> void:
	remove_all_connections()
	var scene_values := SM_SceneSaver.open_scene(scene_uid)
	var component := SM_ComponentFinder.search_component_by_uid(scene_values["instance"], component_uid)
	component._remove_component_uid()
	component._remove_next_scene()


func update_connection(to_slot : SceneMapSlot, action : SM_SlotConnector.Action) -> void:
	await SM_SlotConnector.update_connection(self, to_slot, action)

