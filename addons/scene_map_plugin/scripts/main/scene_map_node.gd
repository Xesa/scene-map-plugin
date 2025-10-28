@tool
extends GraphNode
## Representation of a scene in the SceneMap plugin.
##
## This class represents a scene in the SceneMap plugin in the form of a node.
## It is composed by a preview of the scene and slots that represent each [SceneMapComponent] inside the scene.[br]
## Slots can be connected to other slots that are compatible and are represented by the [SceneMapSlot] class.
## To get a reference to a specific slot, use the [get_component_slot()] method.[br]
##
## This class is instantiated from the [NodeRegistrator] helper class.[br]
## In order to register the slots, this class makes use of the [SlotRegistrator] helper class.

const SM_Enums := preload(SceneMapConstants.ENUMS)
const SM_NodePreviewer := preload(SceneMapConstants.NODE_PREVIEWER)
const SM_SlotRegistrator := preload(SceneMapConstants.SLOT_REGISTRATOR)
const SM_SceneSaver := preload(SceneMapConstants.SCENE_SAVER)
const SM_ResourceTools := preload(SceneMapConstants.RESOURCE_TOOLS)
const SM_NodeMenu := preload(SceneMapConstants.GRAPH_NODE_MENU)
const SceneMapGraph := preload(SceneMapConstants.SCENE_MAP_GRAPH)
const SceneMapNode := preload(SceneMapConstants.SCENE_MAP_NODE)
const SceneMapSlot := preload(SceneMapConstants.SCENE_MAP_SLOT)
const SceneMapIO := preload(SceneMapConstants.SCENE_MAP_IO)

var graph_edit : SceneMapGraph

var scene_name : String
var scene_uid : String

var set_to_create : bool
var set_to_delete := false

var preview : TextureRect
var menu : SM_NodeMenu
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

	theme = Theme.new()
	theme.set_font_size("font_size", "Label", 18)


func _ready() -> void:

	# Initiates the scene saver and opens the scene
	await SM_SceneSaver.start()
	var scene_values := SM_SceneSaver.open_scene(scene_uid)

	# If the scene file doesn't exist, clears the node
	if scene_values == {}:
		printerr("Could not find the scene. The node will be deleted.")
		clear()
		return

	# Gets the scene preview
	await SM_NodePreviewer.create_preview(self)

	# Registers the slots if needed
	if set_to_create:
		await SM_SlotRegistrator.new(self).register_slots()
		await SM_SceneSaver.save()
		SceneMapIO.save(get_parent())

	# Creates the node's menu
	menu = SM_NodeMenu.new(self)

	# Checks how many connections there are
	check_connections()

	# Connects the node_deleted signal to the graph node
	node_deleted.connect(get_parent()._on_node_deleted)
	gui_input.connect(_on_gui_input)
	node_ready.emit()


## Checks for DELETE key press and deletes this node if selected.
func _process(delta : float) -> void:
	if Input.is_key_pressed(KEY_DELETE) and selected and not set_to_delete:
		delete()


## Handles mouse input for this node.
## Left double-click opens the scene in the editor.
## Right-click opens the node context menu.
func _on_gui_input(event : InputEvent) -> void:

	if event is InputEventMouseButton:
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click and event.is_pressed():
			open_scene_in_editor()

		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			menu.make_visible(event.global_position)
			graph_edit.add_child(menu)


## Triggered when a connection is added or removed.
## Re-evaluates the node's connection state and updates the title accordingly.
func _on_connection_added_or_removed(connection : SceneMapSlot, direction : int) -> void:
	check_connections()


## Deletes this node and all its connections. This will also clear the [component_uid] values
## of each [SceneMapComponent] that is attached to every [SceneMapSlot] owned by this node.
func delete() -> void:
	set_to_delete = true

	# Initiates the scene saver and opens the scene
	await SM_SceneSaver.start()
	var scene_values := SM_SceneSaver.open_scene(scene_uid)

	# If the scene was already deleted, clears the node instead of deleting it
	if scene_values == {}:
		await clear()
		return

	# Iterates each slot and removes their connections
	for slot in component_slots.duplicate():
		await slot.delete()

	# Saves all the changes made to the scenes
	await SM_SceneSaver.save()

	# Emits a signal for the graph to delete this node
	node_deleted.emit(self)


## Alternative version of [delete()] used for when the scene file
## has been deleted and the load/save actions cannot be performed properly.
func clear() -> void:
	set_to_delete = true

	for slot in component_slots:
		await slot.clear()

	if SM_SceneSaver.has_pending_changes():
		await SM_SceneSaver.save()

	node_deleted.emit(self)


## Returns the [SceneMapSlot] from this node at the given [index] and [side].[br]
## If the [SceneMapSlot] at the given [index] is of type [FUNNEL],
## it will be returned no matter which value has been passed for the [side] parameter.
func get_component_slot(index : int, side : int) -> SceneMapSlot:
	for slot in component_slots:
		if slot.index == index and (slot.side == side or slot.type == SM_Enums.Type.FUNNEL):
			return slot
	return null


## Returns the [SceneMapSlot] that matches the given component UID.
func get_component_slot_by_uid(component_uid) -> SceneMapSlot:
	for slot in component_slots:
		if slot.component_uid == component_uid:
			return slot
	return null


## Opens the scene represented by this node in the Godot editor.
## Switches to the 2D editor view and releases any current drag operation.
func open_scene_in_editor() -> void:

	# If the file doesn't exit, clears the node
	if !ResourceLoader.exists("uid://"+scene_uid):
		printerr("Could not find the scene. The node will be deleted.")
		clear()
		return

	EditorInterface.open_scene_from_path("uid://"+scene_uid)
	await Engine.get_main_loop().process_frame
	EditorInterface.set_main_screen_editor("2D")
	graph_edit.force_drag_release(self)


## Checks all component slots for existing connections.
## Updates the node's title with a warning symbol if no connections are found.
func check_connections() -> void:
	for slot in component_slots:
		if slot.connected_from.size() == 0 and slot.connected_to.size() == 0:
			title = "⚠️" + scene_name
			return
	
	title = scene_name
	