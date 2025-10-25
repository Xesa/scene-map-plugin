@tool
extends Node
## Representation of a [SceneMapComponent] in the SceneMap plugin.
##
## This class represents a [SceneMapComponent] in the SceneMap plugin in the form of a connection slot.
## It is always attached to a parent [SceneMapNode] which represents the scene in which the component is.[br]
## Slots can be connected to other slots that are compatible. Connections are always requested by the [SceneMapGraph].
## 
## To add or remove a connection use the [update_connection()]. To delete the slot use the [delete()] method.
## There are other useful methods such as [get_connections()], [has_incoming_connections()] or [has_outgoing_connections()].
##
## When a connection is added or removed, the [connection_added] and [connection_removed] signals are triggered.[br]
##
## The [connected_from] and [connected_to] properties represent an array of other [SceneMapSlot] to which this one is connected.
## The terms "from" and "to" mean that the slot represents an entrance or an exit. In the case of double sided connections each slot
## will appear in both "from" and "to" arrays. In some cases this is also represented by a parameter called [direction] which can be
## represented as [0] for "from" and [1] for "to".[br]
##
## This class is instantiated from the [SlotRegistrator] helper class.[br]
## In order to make a connection with another node, this class makes use of the [SlotConnector] helper class.
## To check whether two slots are compatible or not, see the [ConnectionValidator] helper class.

const SM_Constants := preload(SceneMapConstants.CONSTANTS)
const SM_ComponentFinder := preload(SceneMapConstants.COMPONENT_FINDER)
const SM_SlotConnector := preload(SceneMapConstants.SLOT_CONNECTOR)
const SM_SceneSaver := preload(SceneMapConstants.SCENE_SAVER)
const SM_SlotControl := preload(SceneMapConstants.SLOT_CONTROL)
const SM_Enums := preload(SceneMapConstants.ENUMS)
const SceneMapNode := preload(SceneMapConstants.SCENE_MAP_NODE)
const SceneMapSlot := preload(SceneMapConstants.SCENE_MAP_SLOT)
const SceneMapIO := preload(SceneMapConstants.SCENE_MAP_IO)


var graph_node : SceneMapNode
var control : SM_SlotControl

var slot_id : String
var index : int

var left : bool
var right : bool
var left_icon : String
var right_icon : String

var scene_uid : String
var component_uid : String
var component_name : String
var component_name_is_custom := false

var type : SM_Enums.Type
var side : SM_Enums.Side

var connected_to_ids : Array[String]
var connected_from_ids : Array[String]

var connected_to : Array[SceneMapSlot]
var connected_from : Array[SceneMapSlot]

signal connection_added(connection : SceneMapSlot, direction : int)
signal connection_removed(connection : SceneMapSlot, direction : int)
signal side_changed(side : SM_Enums.Side)
signal type_changed(type : SM_Enums.Type)


func _init(_graph_node : SceneMapNode, _type : SM_Enums.Type = 0, _side : SM_Enums.Side = 0,
		_index : int = 0, _left : bool = false, _right : bool = false,
		_left_icon : String = "", _right_icon : String = "",
		_scene_uid : String = "", _component_uid = null,
		_component_name : String = "", _component_name_is_custom : bool = false)-> void:

	graph_node = _graph_node
	component_uid = _component_uid
	scene_uid = _scene_uid
	component_name = _component_name
	component_name_is_custom = _component_name_is_custom
	slot_id = scene_uid + ":" + component_uid

	type = _type
	side = _side
	index = _index
	left = _left
	right = _right
	left_icon = _left_icon
	right_icon = _right_icon

	connected_to = []
	connected_from = []

	connection_added.connect(graph_node._on_connection_added_or_removed)
	connection_removed.connect(graph_node._on_connection_added_or_removed)


## Connects this slot to the given [SceneMapSlot]. The [direction] parameter represents that the slot is an entrance or an exit [SceneMapNode]:[br]
## - [1] means that this slot is an exit and the other slot is an entrance. Hence, the connection goes "to" the other slot.[br]
## - [0] means that this slot is an entrance and the other slot is an exit. Hence, the connection comes "from" the other slot.
func add_connection(connection : SceneMapSlot, direction : int) -> void:
	if direction == 1 and not connected_to.has(connection):
		connected_to.append(connection)
		connected_to_ids.append(connection.slot_id)
		connection_added.emit(connection, direction)
		
	elif direction == 0 and not connected_from.has(connection): 
		connected_from.append(connection)
		connected_from_ids.append(connection.slot_id)
		connection_added.emit(connection, direction)


## Disconnects this slot to the given [SceneMapSlot]. The [direction] parameter represents that the slot is an entrance or an exit [SceneMapNode]:[br]
## - [1] means that this slot is an exit and the other slot is an entrance. Hence, the connection goes "to" the other slot.[br]
## - [0] means that this slot is an entrance and the other slot is an exit. Hence, the connection comes "from" the other slot.
func remove_connection(connection : SceneMapSlot, direction : int) -> void:
	if direction == 1:
		connected_to.erase(connection)
		connected_to_ids.erase(connection.slot_id)
	else:
		connected_from.erase(connection)
		connected_from_ids.erase(connection.slot_id)

	#graph_node.check_connections()
	connection_removed.emit(connection, direction)


## Returns [true] if there is any [SceneMapSlot] connected to this one. This represents "from" connections, or direction [0].
func has_incoming_connections() -> bool:
	if connected_from == null:
		return false
	return connected_from.size() > 0


## Returns [true] if this slot is connected to another [SceneMapSlot]. This represents "to" connections, or direction [1].
func has_outgoing_connections() -> bool:
	if connected_to == null:
		return false
	return connected_to.size() > 0


## Returns all the [SceneMapSlot] connected to or from this one in the given [direction].
func get_connections(direction : int) -> Array[SceneMapSlot]:
	if direction == 1:
		return connected_to
	else:
		return connected_from


## Returns all the [SceneMapSlot] connected to and from this one.
func get_all_connections() -> Array[SceneMapSlot]:
	var all_connections : Array[SceneMapSlot] = []
	all_connections.append_array(get_connections(1))
	all_connections.append_array(get_connections(0))
	return all_connections


## Removes all the connections established with other [SceneMapSlot]. This effectively removes
## this slot from the [connected_to] and [connected_from] properties in the other slot.
func remove_all_connections() -> void:

	# Iterates every connected slot and removes the connection
	for to_slot in get_connections(true):
		await update_connection(to_slot, SM_SlotConnector.Action.DISCONNECT)

	for from_slot in get_connections(false):
		await from_slot.update_connection(self, SM_SlotConnector.Action.DISCONNECT)


## Deletes this slot, removing all the connections established with other [SceneMapSlot]. This effectively removes
## this slot from the [connected_to] and [connected_from] properties in the other slot.
## Deleting a slot will also remove the [component_uid], [next_scene_uid] and [next_component_uid]
## metadata values from the [SceneMapComponent]
func delete() -> void:
	await remove_all_connections()
	var scene_values := SM_SceneSaver.open_scene(scene_uid)
	var component := SM_ComponentFinder.search_component_by_uid(scene_values["instance"], component_uid)

	if component:
		component._remove_next_scene()

	if control:
		control.queue_free()

	if graph_node.component_slots.has(self):
		graph_node.component_slots.erase(self)


## Adds or removes a connection with another [SceneMapSlot]. This method uses the
## [SlotConnector] helper class, which will perform some checks and call this class'
## [add_connection()] or [remove_connection()] depending on the given [action].[br]
## Once the connection is completed, both [SceneMapSlot] will have their [connected_to]
## and [connected_from] properties updated, pointing to each other. The [SceneMapComponent]
## associated to this slot will also have its [next_scene_uid] and [next_component_uid]
## metadata values updated.
func update_connection(to_slot : SceneMapSlot, action : SM_SlotConnector.Action) -> void:
	await SM_SlotConnector.update_connection(self, to_slot, action)


## Changes the side of this slot (LEFT or RIGHT) and updates the associated component.
func change_sides() -> void:

	var scene_values := SM_SceneSaver.open_scene(scene_uid)
	var component := SM_ComponentFinder.search_component_by_uid(scene_values["instance"], component_uid)

	if type == SM_Enums.Type.FUNNEL:
		if side == SM_Enums.Side.LEFT:
			_update_side_info(true, true, 1, 1, SM_Enums.Side.RIGHT, component)
		else:
			_update_side_info(true, true, 0, 0, SM_Enums.Side.LEFT, component)

	else:
		if side == SM_Enums.Side.LEFT:
			_update_side_info(false, true, 0, 1, SM_Enums.Side.RIGHT, component)
		else:
			_update_side_info(true, false, 0, 1, SM_Enums.Side.LEFT, component)

	await remove_all_connections()

	SM_SceneSaver.save()
	
	_update_slot_configuration()

	side_changed.emit(side)
	SceneMapIO.save(graph_node.get_parent())



## Changes the type of this slot (e.g., FUNNEL, STANDARD) and updates the associated component.
func change_type(new_type : SM_Enums.Type) -> void:

	if type == new_type:
		return

	var scene_values := SM_SceneSaver.open_scene(scene_uid)
	var component := SM_ComponentFinder.search_component_by_uid(scene_values["instance"], component_uid)

	type = new_type
	component._set_component_type(type)

	if type == SM_Enums.Type.FUNNEL:
		if side == SM_Enums.Side.LEFT:
			_update_side_info(true, true, 0, 0, side, component)
		else:
			_update_side_info(true, true, 1, 1, side, component)

	else:
		if side == SM_Enums.Side.LEFT:
			_update_side_info(true, false, 0, 1, side, component)
		else:
			_update_side_info(false, true, 0, 1, side, component)

	await remove_all_connections()

	SM_SceneSaver.save()
	
	_update_slot_configuration()

	type_changed.emit(type)
	SceneMapIO.save(graph_node.get_parent())
	

## Updates internal left/right flags, icons, and side metadata for this slot.
func _update_side_info(_left : bool, _right : bool, _left_icon_index : int, _right_icon_index : int, _side : SM_Enums.Side, component : SceneMapComponent2D) -> void:
	var slot_config : Dictionary = SM_Constants.SLOT_CONFIG[type]
	left = _left
	right = _right
	left_icon = slot_config["icons"][_left_icon_index]
	right_icon = slot_config["icons"][_right_icon_index]
	side = _side
	component._set_component_side(side)


## Refreshes the slot visuals in the GraphNode based on current left/right state and icons.
func _update_slot_configuration() -> void:

	var left_icon := load(left_icon)
	var right_icon := load(right_icon)

	var left_type := 0 if left else -1
	var right_type := 0 if right else -1
	var left_color := Color.WHITE if left else Color.TRANSPARENT
	var right_color := Color.WHITE if right else Color.TRANSPARENT

	graph_node.set_slot(index, true, left_type, left_color, true, right_type, right_color)

	graph_node.set_slot_custom_icon_left(index, left_icon)
	graph_node.set_slot_custom_icon_right(index, right_icon)


## Sets the component's name and indicates if it is custom or not.
func set_component_name(new_name : String) -> void:

	if new_name == component_name:
		return

	var scene_values := SM_SceneSaver.open_scene(scene_uid)
	var component := SM_ComponentFinder.search_component_by_uid(scene_values["instance"], component_uid)

	component_name = new_name
	component_name_is_custom = true

	component._set_custom_name(new_name)
	control.refresh_label()

	SM_SceneSaver.save()
	SceneMapIO.save(graph_node.get_parent())


## Removes the custom name of this slot's component and restores default.
func remove_component_name() -> void:

	if !component_name_is_custom:
		return

	var scene_values := SM_SceneSaver.open_scene(scene_uid)
	var component := SM_ComponentFinder.search_component_by_uid(scene_values["instance"], component_uid)

	component._remove_custom_name()
	component_name = component.get_custom_name()
	component_name_is_custom = false
	control.refresh_label()

	SM_SceneSaver.save()
	SceneMapIO.save(graph_node.get_parent())