@tool
class_name SceneMapNode extends GraphNode
## Representation of a scene in the SceneMap plugin.
##
## This class represents a scene in the SceneMap plugin in the form of a node.
## It is composed by a preview of the scene and slots that represent each [SceneMapComponent] inside the scene.[br]
## Slots can be connected to other slots that are compatible and are represented by the [SceneMapSlot] class.
## To get a reference to a specific slot, use the [get_component_slot()] method.[br]
##
## This class is instantiated from the [NodeRegistrator] helper class.[br]
## In order to register the slots, this class makes use of the [SlotRegistrator] helper class.

const SM_NodePreviewer := preload("uid://brgihuj5exdgu")
const SM_SlotRegistrator := preload("uid://bj10g5ips4ubj")
const SM_SceneSaver := preload("uid://7svcgc01kw2b")

var graph_edit : SceneMapGraph

var scene_name : String
var scene_uid : String

var set_to_create : bool
var set_to_delete := false

var preview : TextureRect
var component_slots : Array[SceneMapSlot]

signal node_deleted(node : SceneMapNode)
signal node_ready()


func _init(_graph_edit : SceneMapGraph, _scene_uid : String, _scene_name : String,  _set_to_create : bool = true) -> void:
	graph_edit = _graph_edit
	scene_name = _scene_name
	scene_uid = _scene_uid
	title = scene_name
	name = scene_uid
	set_to_create = _set_to_create


func _ready() -> void:

	# Initiates the scene saver and opens the scene
	await SM_SceneSaver.start()
	var scene_values := SM_SceneSaver.open_scene(scene_uid)

	# Gets the scene preview
	await SM_NodePreviewer.create_preview(self)

	# Registers the slots if needed
	if set_to_create:
		await SM_SlotRegistrator.new(self).register_slots()
		await SM_SceneSaver.save()
		SceneMapIO.save(get_parent())

	# Connects the node_deleted signal to the graph node
	node_deleted.connect(get_parent()._on_node_deleted)
	node_ready.emit()


func _process(delta : float) -> void:
	if Input.is_key_pressed(KEY_DELETE) and selected and not set_to_delete:
		_delete()


## Deletes this node and all its connections. This will also clear the [component_uid] values
## of each [SceneMapComponent] that is attached to every [SceneMapSlot] owned by this node.
func _delete() -> void:
	set_to_delete = true

	# Initiates the scene saver and opens the scene
	await SM_SceneSaver.start()
	var scene_values := SM_SceneSaver.open_scene(scene_uid)
	
	# Iterates each slot and removes their connections
	for slot in component_slots:
		await slot.delete()

	# Saves all the changes made to the scenes
	await SM_SceneSaver.save()

	# Emits a signal for the graph to delete this node
	node_deleted.emit(self)


## Returns the [SceneMapSlot] from this node at the given [index] and [side].[br]
## If the [SceneMapSlot] at the given [index] is of type [FUNNEL],
## it will be returned no matter which value has been passed for the [side] parameter.
func get_component_slot(index : int, side : int) -> SceneMapSlot:
	for slot in component_slots:
		if slot.index == index and (slot.side == side or slot.type == SceneMapComponent2D.Type.FUNNEL):
			return slot
	return null


func get_component_slot_by_uid(component_uid) -> SceneMapSlot:
	for slot in component_slots:
		if slot.component_uid == component_uid:
			return slot
	return null