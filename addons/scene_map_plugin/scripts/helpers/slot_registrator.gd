extends Node
## SM_SlotRegistrator
##
## Class in charge of registering new [SceneMapSlot] and associating them to the [SceneMapNode].[br]
##
## The [register_slots()] method is used for creating brand new slots when the node
## is being created for the first time or refreshed after adding new components to the scene.[br]
##
## For creating a single brand new slot, see the [register_slot()] method. There is also the
## [load_existing_slot()] used for loading the information from a saved resource.
##
## This class makes use of the [SM_ComponentFinder] helper class for listing all the [SceneMapComponent] present in the scene.[br]

const SM_Enums := preload(SceneMapConstants.ENUMS)
const SM_ComponentFinder := preload(SceneMapConstants.COMPONENT_FINDER)
const SM_ResourceTools := preload(SceneMapConstants.RESOURCE_TOOLS)
const SM_SceneSaver := preload(SceneMapConstants.SCENE_SAVER)
const SM_SlotControl := preload(SceneMapConstants.SLOT_CONTROL)
const SM_SlotResource := preload(SceneMapConstants.SLOT_RESOURCE)
const SceneMapNode := preload(SceneMapConstants.SCENE_MAP_NODE)
const SceneMapSlot := preload(SceneMapConstants.SCENE_MAP_SLOT)

var graph_node : SceneMapNode
var slot_counter : int


func _init(_graph_node : SceneMapNode) -> void:
	graph_node = _graph_node
	

## Creates connection slots for each [SceneMapComponent] found in the scene.
## Depending on the property [type] of the [SceneMapComponent], the connection slot will be either on the left side, right side or both sides.
func register_slots() -> void:

	slot_counter = 0
	graph_node.component_slots = []

	# Gets the scene instance
	var scene_values := await SM_SceneSaver.open_scene(graph_node.scene_uid)
	
	# Gets all the [SceneMapComponent2D] in the scene
	var components := SM_ComponentFinder.find_all_components(scene_values.instance)

	# Sets an invisible node, otherwise the rest of nodes won't work properly
	graph_node.set_slot(0, true, -1, Color.TRANSPARENT, true, -1, Color.TRANSPARENT)

	# Iterates each component from each type and registers them
	for component in components:
		register_new_slot(component)

	# Saves the scene
	await SM_SceneSaver.save()


## Registers a new [SceneMapSlot] that represents the given [SceneMapComponent].
## When a slot is registered this way, this class populates the [component_uid] metadata value in the [SceneMapComponent].
func register_new_slot(component: SceneMapComponent2D) -> SceneMapSlot:

	# Increases the counter
	slot_counter += 1

	# Gets which sides must be active depending on the component type and side
	var slot_sides = _get_slot_sides(component)
	var left_side = slot_sides[0]
	var right_side = slot_sides[1]
	var left_icon_path = slot_sides[2]
	var right_icon_path = slot_sides[3]

	# Retrieves the information from the component
	
	var data := {
		"type": component.get_component_type(),
		"side": component.get_component_side(),
		"index": slot_counter,
		"left": left_side,
		"right": right_side,
		"left_icon": left_icon_path,
		"right_icon": right_icon_path,
		"scene_uid": graph_node.scene_uid,
		"component_uid": component.get_component_uid(),
		"component_name": component.get_custom_name(),
		"component_name_is_custom": component.has_custom_name()
	}

	# Creates the slot and sets a UID to the component
	var slot = _create_and_attach_slot(data)
	return slot


## Registers a [SceneMapSlot] loaded from a [SceneMapSlotResource].
func load_existing_slot(resource: SM_SlotResource) -> SceneMapSlot:

	# Retrieves the information from the resource
	var data := {
		"type": resource.type,
		"side": resource.side,
		"index": resource.index,
		"left": resource.left,
		"right": resource.right,
		"left_icon": resource.left_icon,
		"right_icon": resource.right_icon,
		"scene_uid": resource.scene_uid,
		"component_uid": resource.component_uid,
		"component_name": resource.component_name,
		"component_name_is_custom": resource.component_name_is_custom
	}

	# Creates the slot and populates the connections
	var slot = _create_and_attach_slot(data)

	slot.connected_from_ids = resource.connected_from_ids
	slot.connected_to_ids = resource.connected_to_ids

	return slot


## Creates a new [SceneMapSlot] and attaches it to the [SceneMapNode].
## This method loads the information from a dictionary so it can be called
## for either create a brand new slot or loading an existing one.
func _create_and_attach_slot(data: Dictionary) -> SceneMapSlot:

	# Retrieves the information from the dictionary
	var slot := SceneMapSlot.new(
		graph_node,
		data.type,
		data.side,
		data.index,
		data.left,
		data.right,
		data.left_icon,
		data.right_icon,
		data.scene_uid,
		data.component_uid,
		data.component_name,
		data.component_name_is_custom
	)

	# Creates the buttons and text from the slot
	var control := SM_SlotControl.new(graph_node, slot)
	graph_node.add_child(control)

	# Sets the slot index and position in the graph node
	set_slot(data.index, data.left, data.right, data.left_icon, data.right_icon)
	graph_node.component_slots.append(slot)

	return slot


## Returns the sides in which the slot should be active and the icon paths.
func _get_slot_sides(component : SceneMapComponent2D) -> Array:

	# Gets the slot configuration for this component type
	var config = SceneMapConstants.SLOT_CONFIG[component.get_component_type()]

	# Sets different variables for the slot configuration
	var left_side := false
	var right_side := false
	var left_icon_path : String
	var right_icon_path : String

	# Sets the values if the component type is Funnel
	if component.get_component_type() == SM_Enums.Type.FUNNEL:
		left_side = true
		right_side = true

		if component.get_component_side() == SM_Enums.Side.LEFT:
			left_icon_path = config["icons"][0]
			right_icon_path = config["icons"][0]

		if component.get_component_side() == SM_Enums.Side.RIGHT:
			left_icon_path = config["icons"][1]
			right_icon_path = config["icons"][1]

	# Sets the values for any other component type
	else:
		left_icon_path = config["icons"][0]
		right_icon_path = config["icons"][1]

		if component.get_component_side() == SM_Enums.Side.LEFT:
			left_side = true

		if component.get_component_side() == SM_Enums.Side.RIGHT:
			right_side = true

	return [left_side, right_side, left_icon_path, right_icon_path]


## Sets the slot's index, position, color and icons in the [SceneMapNode].
func set_slot(index : int, left_side : bool, right_side : bool, left_icon_path : String, right_icon_path : String) -> void:
	# Loads the textures for the icons
	var left_icon : Texture2D = load(left_icon_path)
	var right_icon : Texture2D = load(right_icon_path)

	var left_type := 0 if left_side else -1
	var right_type := 0 if right_side else -1
	var left_color := Color.WHITE if left_side else Color.TRANSPARENT
	var right_color := Color.WHITE if right_side else Color.TRANSPARENT

	# Adds the slot to the graph node
	graph_node.set_slot(index, true, left_type, left_color, true, right_type, right_color)

	graph_node.set_slot_custom_icon_left(index, left_icon)
	graph_node.set_slot_custom_icon_right(index, right_icon)