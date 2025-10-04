@tool
class_name SceneMapSlot extends Node

const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")
const SM_SlotConnector := preload("uid://1mcwq8t36pgx")
const SM_ResourceTools := preload("uid://cwik34k5w34y1")

var slot_id : String
var index : int
var specific_index : int

var left : bool
var right : bool

var scene_path : String
var scene_uid : String
var component_path : String
var component_uid : String

var type : SceneMapComponent.Type
var side : SceneMapComponent.Side
var type_string : String

var connected_to_ids : Array[String]
var connected_from_ids : Array[String]

var connected_to : Array[SceneMapSlot]
var connected_from : Array[SceneMapSlot]


func _init(_scene_path : String = "", _scene_uid : String = "", _component_path : NodePath = "",
			_type : SceneMapComponent.Type = 0, _side : SceneMapComponent.Side = 0,
			_index : int = 0, _specific_index : int = 0, _left : bool = false, _right : bool = false) -> void:
	
	scene_path = _scene_path
	scene_uid = _scene_uid
	component_path = _component_path
	slot_id = scene_uid + ":" + str(_component_path)
	side = _side
	index = _index
	specific_index = _specific_index
	left = _left
	right = _right

	connected_to = []
	connected_from = []

	set_type(_type)


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
		await update_connection(to_slot, SM_SlotConnector.Action.DISCONNECT)

	for from_slot in get_connections(false):
		await from_slot.update_connection(self, SM_SlotConnector.Action.DISCONNECT)

	# Instantiates the node's scene
	var scene_resource := load("uid://"+scene_uid) as PackedScene
	var scene_instance := scene_resource.instantiate()
	var component_instance := SM_ComponentFinder.search_component_by_uid(scene_instance, component_uid)
	component_instance._remove_component_uid()

	await SM_ResourceTools.post_save_scene(scene_resource, scene_instance, scene_path)


func update_connection(to_slot : SceneMapSlot, action : SM_SlotConnector.Action) -> void:
	await SM_SlotConnector.update_connection(self, to_slot, action)

