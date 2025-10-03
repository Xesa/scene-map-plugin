@tool
class_name SceneMapSlot extends Node

var slot_id : String
var index : int
var specific_index : int

var left : bool
var right : bool

var scene_path : String
var scene_uid : String
var component_path : NodePath

var type : SceneMapComponent.Type
var side : SceneMapComponent.Side
var type_string : String

var connected_to_ids : Array[String]
var connected_from_ids : Array[String]

var component : SceneMapComponent
var connected_to : Array[SceneMapSlot]
var connected_from : Array[SceneMapSlot]


func _init(_component : SceneMapComponent = null, _scene_path : String = "", _scene_uid : String = "",
			_component_path : NodePath = "", _type : SceneMapComponent.Type = 0, _side : SceneMapComponent.Side = 0) -> void:
	
	scene_path = _scene_path
	scene_uid = _scene_uid
	component_path = _component_path
	slot_id = scene_uid + ":" + str(_component_path)
	side = _side
	component = _component
	connected_to = []
	connected_from = []

	set_type(_type)


func set_slot_info(_index : int, _specific_index :int, _left : bool, _right : bool):
	index = _index
	specific_index = _specific_index
	left = _left
	right = _right


func set_type(_type : SceneMapComponent.Type) -> void:
	type = _type
	match type:
		SceneMapComponent.Type.ENTRY: type_string = "Entrance"
		SceneMapComponent.Type.EXIT: type_string = "Exit"
		SceneMapComponent.Type.TWO_WAY: type_string = "Two-way"
		SceneMapComponent.Type.FUNNEL: type_string = "Funnel"


func add_connection(connection : SceneMapSlot, to : bool) -> void:
	if to and not connected_to.has(connection):
		connected_to.append(connection)
		connected_to_ids.append(connection.slot_id)
	elif !to and not connected_from.has(connection): 
		connected_from.append(connection)
		connected_from_ids.append(connection.slot_id)


func set_connections(connections : Array[SceneMapSlot], to : bool) -> void:

	if to:
		connected_to = []
		connected_to_ids = []

		for connection in connections:
			add_connection(connection, true)
	
	else:
		connected_from = []
		connected_from_ids = []

		for connection in connections:
			add_connection(connection, false)


func remove_connection(connection : SceneMapSlot, to : bool) -> void:
	if to:
		connected_to.erase(connection)
		connected_to_ids.erase(connection.slot_id)
	else:
		connected_from.erase(connection)
		connected_from_ids.erase(connection.slot_id)


func has_connection(connection: SceneMapSlot, to : bool) -> bool:
	if to:
		return connected_to.has(connection)
	else:
		return connected_from.has(connection)


func get_connections(to : bool) -> Array[SceneMapSlot]:
	if to:
		return connected_to
	else:
		return connected_from


func get_all_connections() -> Array[SceneMapSlot]:
	var all_connections : Array[SceneMapSlot] = []
	all_connections.append_array(get_connections(true))
	all_connections.append_array(get_connections(false))
	return all_connections


func remove_all_connections() -> void:

	for to_slot in get_connections(true):
		update_connection(to_slot, SlotConnector.Action.DISCONNECT)

	for from_slot in get_connections(false):
		from_slot.update_connection(self, SlotConnector.Action.DISCONNECT)


func update_connection(to_slot : SceneMapSlot, action : SlotConnector.Action) -> void:
	SlotConnector.update_connection(self, to_slot, action)


func _on_component_path_renamed(new_path : NodePath) -> void:
	print("sdfsdf")
	print(new_path)

	var old_path := component_path
	var old_slot_id := slot_id
	component_path = new_path
	slot_id = scene_path + "::" + str(new_path)

	for slot : SceneMapSlot in connected_to:
		var id_index = slot.connected_from_ids.find(old_slot_id)
		slot.connected_from_ids[id_index] = slot_id

	for slot : SceneMapSlot in connected_from:
		var id_index = slot.connected_to_ids.find(old_slot_id)
		slot.connected_to_ids[id_index] = slot_id
		slot.update_connection(self, SlotConnector.Action.UPDATE)




