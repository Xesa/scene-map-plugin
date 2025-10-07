extends Node
## Class in charge of registering new [SceneMapSlot] and associating them to the [SceneMapNode].[br]
##
## The [register_slots()] method is used for creating brand new slots when the node
## is being created for the first time or refreshed after adding new components to the scene.[br]
##
## For creating a single brand new slot, see the [register_slot()] method. There is also the
## [load_existing_slot()] used for loading the information from a saved resource.
##
## This class makes use of the [ComponentFinder] helper class for listing all the [SceneMapComponent] present in the scene.[br]

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")
const SM_ResourceTools := preload("uid://b71h2bnocse6c")
const SM_SceneSaver := preload("uid://7svcgc01kw2b")
const SM_DisconnectButton := preload("uid://0s4l0pgfen4i")
const SM_SlotResource := preload("uid://p2mmnni4huyo")

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
	graph_node.set_slot(0, true, -1, Color.TRANSPARENT, true, 1, Color.TRANSPARENT)

	# Iterates each component from each type and registers them
	for key in components.keys():
		for component in components[key]:
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

	# Retrieves the information from the ocmponent
	var component_name = component.custom_name if component.custom_name else SM_ResourceTools.convert_string_to_readable_name(component.name)
	
	var data := {
		"type": component.type,
		"side": component.side,
		"index": slot_counter,
		"left": left_side,
		"right": right_side,
		"left_icon": left_icon_path,
		"right_icon": right_icon_path,
		"scene_uid": graph_node.scene_uid,
		"component_name": component_name,
		"component_uid": null
	}

	# Creates the slot and sets a UID to the component
	var slot = _create_and_attach_slot(data)
	component._set_component_uid(slot.component_uid)
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
		"component_name": resource.component_name,
		"component_uid": resource.component_uid
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
		data.type,
		data.side,
		data.index,
		data.left,
		data.right,
		data.left_icon,
		data.right_icon,
		data.scene_uid,
		data.component_name,
		data.component_uid
	)

	# Creates the buttons and text from the slot
	generate_slot_controls(data.index, data.component_name, data.type, data.side, slot)

	# Sets the slot index and position in the graph node
	set_slot(data.index, data.left, data.right, data.left_icon, data.right_icon)

	graph_node.add_child(slot)
	graph_node.component_slots.append(slot)

	return slot


## Returns the sides in which the slot should be active and the icon paths.
func _get_slot_sides(component : SceneMapComponent2D) -> Array:

	# Gets the slot configuration for this component type
	var config = SM_Constants.SLOT_CONFIG[component.type]

	# Sets different variables for the slot configuration
	var left_side := false
	var right_side := false
	var left_icon_path : String
	var right_icon_path : String

	# Sets the values if the component type is Funnel
	if component.type == SceneMapComponent2D.Type.FUNNEL:
		left_side = true
		right_side = true

		if component.side == SceneMapComponent2D.Side.LEFT:
			left_icon_path = config["icons"][0]
			right_icon_path = config["icons"][0]

		if component.side == SceneMapComponent2D.Side.RIGHT:
			left_icon_path = config["icons"][1]
			right_icon_path = config["icons"][1]

	# Sets the values for any other component type
	else:
		left_icon_path = config["icons"][0]
		right_icon_path = config["icons"][1]

		if component.side == SceneMapComponent2D.Side.LEFT:
			left_side = true

		if component.side == SceneMapComponent2D.Side.RIGHT:
			right_side = true

	return [left_side, right_side, left_icon_path, right_icon_path]


## Sets the slot's index, position, color and icons in the [SceneMapNode].
func set_slot(index : int, left_side : bool, right_side : bool, left_icon_path : String, right_icon_path : String) -> void:
	# Loads the textures for the icons
	var left_icon : Texture2D = load(left_icon_path)
	var right_icon : Texture2D = load(right_icon_path)

	var left_type := 0 if left_side else -1
	var right_type := 0 if right_side else 1
	var left_color := Color.WHITE if left_side else Color.BLACK
	var right_color := Color.WHITE if right_side else Color.BLACK

	# Adds the slot to the graph node
	graph_node.set_slot(
		index,
		true, left_type, left_color,
		true, right_type, right_color,
		left_icon, right_icon
	)


## Creates the buttons and text labels for the slot depending on the [SceneMapComponent] type and side.
func generate_slot_controls(index : int, name : String, type : SceneMapComponent2D.Type, side : SceneMapComponent2D.Side, slot : SceneMapSlot) -> void:
	var control := _create_control()

	if type == SceneMapComponent2D.Type.FUNNEL:
		_create_disconnect_button(control, slot, 0)
		_create_label(control, index, name)
		_create_disconnect_button(control, slot, 1)

	else:
		if side == SceneMapComponent2D.Side.LEFT:
			_create_disconnect_button(control, slot, 0)
			_create_label(control, index, name)
			_create_empty_space(control)

		if side == SceneMapComponent2D.Side.RIGHT:
			_create_empty_space(control)
			_create_label(control, index, name)
			_create_disconnect_button(control, slot, 1)


func _create_control() -> HBoxContainer:
	var control := HBoxContainer.new()
	control.add_theme_constant_override("separation", -5)
	control.set_anchors_preset(Control.LayoutPreset.PRESET_HCENTER_WIDE)
	graph_node.add_child(control)
	return control


func _create_disconnect_button(control : HBoxContainer, slot : SceneMapSlot, side : int) -> SM_DisconnectButton:
	var button := SM_DisconnectButton.new(graph_node.get_parent(), slot, side)
	control.add_child(button)
	return button


func _create_label(control : HBoxContainer, index, text : String) -> Label:
	var label = Label.new()
	label.text = str(index) + ". " + text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.add_child(label)
	return label


func _create_empty_space(control) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size.x = 28
	control.add_child(spacer)
	return spacer