extends Node

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")
const SM_ResourceTools := preload("uid://b71h2bnocse6c")
const SM_SceneSaver := preload("uid://7svcgc01kw2b")
const SM_DisconnectButton := preload("uid://0s4l0pgfen4i")
const SM_SlotResource := preload("uid://p2mmnni4huyo")

var graph_node : SceneMapNode

var general_counter : int
var specific_counters : Dictionary

var slot_config : Dictionary


func _init(_graph_node : SceneMapNode) -> void:
	graph_node = _graph_node
	

## Creates connection slots for each [SceneMapComponent2D] found in the scene.
## Depending on the property [type] of the [SceneMapComponent2D], the connection slot will be either on the left side, right side or both sides.
func register_slots() -> void:

	# Sets a blank list for the component slots
	graph_node.component_slots = []

	# Resets all slot counters
	general_counter = 0
	specific_counters = {
		"funnels" : 0,
		"entrances" : 0,
		"exits" : 0,
		"two_ways" : 0
	}

	# Gets the scene instance
	var scene_values := await SM_SceneSaver.open_scene(graph_node.scene_uid)
	
	# Gets all the [SceneMapComponent2D] in the scene
	var components := SM_ComponentFinder.find_all_components(scene_values.instance)

	# Sets an invisible node, otherwise the rest of nodes won't work properly
	graph_node.set_slot(0, true, 1, Color.TRANSPARENT, true, 1, Color.TRANSPARENT)

	# Iterates each component from each type and registers them
	for key in specific_counters.keys():
		for component in components[key]:
			general_counter += 1
			specific_counters[key] += 1
			register_new_slot(component, key)

	# Saves the scene
	await SM_SceneSaver.save()


func register_new_slot(component: SceneMapComponent2D, key: String) -> SceneMapSlot:
	var slot_sides = _get_slot_sides(component, key)
	var left_side = slot_sides[0]
	var right_side = slot_sides[1]
	var left_icon_path = slot_sides[2]
	var right_icon_path = slot_sides[3]

	var component_name = component.custom_name if component.custom_name else SM_ResourceTools.convert_string_to_readable_name(component.name)

	var data := {
		"type": component.type,
		"side": component.side,
		"index": general_counter,
		"specific_index": specific_counters[key],
		"left": left_side,
		"right": right_side,
		"left_icon": left_icon_path,
		"right_icon": right_icon_path,
		"scene_uid": graph_node.scene_uid,
		"component_name": component_name,
		"component_uid": null,
	}

	var slot = _create_and_attach_slot(data)
	component._set_component_uid(slot.component_uid)
	return slot


func load_existing_slot(resource: SM_SlotResource) -> SceneMapSlot:
	var data := {
		"type": resource.type,
		"side": resource.side,
		"index": resource.index,
		"specific_index": resource.specific_index,
		"left": resource.left,
		"right": resource.right,
		"left_icon": resource.left_icon,
		"right_icon": resource.right_icon,
		"scene_uid": resource.scene_uid,
		"component_name": resource.component_name,
		"component_uid": resource.component_uid
	}

	var slot = _create_and_attach_slot(data)

	slot.connected_from_ids = resource.connected_from_ids
	slot.connected_to_ids = resource.connected_to_ids

	return slot


func _create_and_attach_slot(data: Dictionary) -> SceneMapSlot:
	var slot := SceneMapSlot.new(
		data.type,
		data.side,
		data.index,
		data.specific_index,
		data.left,
		data.right,
		data.left_icon,
		data.right_icon,
		data.scene_uid,
		data.component_name,
		data.component_uid
	)

	generate_slot_controls(data.component_name, data.type, data.side, slot)
	set_slot(data.index, data.left, data.right, data.left_icon, data.right_icon)

	graph_node.add_child(slot)
	graph_node.component_slots.append(slot)

	return slot


func _get_slot_sides(component : SceneMapComponent2D, key : String) -> Array:

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


func set_slot(index, left_side, right_side, left_icon_path, right_icon_path) -> void:
	# Loads the textures for the icons
	var left_icon : Texture2D = load(left_icon_path)
	var right_icon : Texture2D = load(right_icon_path)

	# Adds the slot to the graph node
	graph_node.set_slot(
		index,
		left_side, 0, Color.WHITE,
		right_side, 0, Color.WHITE,
		left_icon, right_icon
	)


func generate_slot_controls(name : String, type : SceneMapComponent2D.Type, side : SceneMapComponent2D.Side, slot : SceneMapSlot) -> void:
	var control := _create_control()

	if type == SceneMapComponent2D.Type.FUNNEL:

		_create_disconnect_button(control, slot, 0)
		_create_label(control, name)
		_create_disconnect_button(control, slot, 1)

	else:

		if side == SceneMapComponent2D.Side.LEFT:
			_create_disconnect_button(control, slot, 0)
			_create_label(control, name)
			_create_empty_space(control)

		if side == SceneMapComponent2D.Side.RIGHT:
			_create_empty_space(control)
			_create_label(control, name)
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


func _create_label(control : HBoxContainer, text : String) -> Label:
	var label = Label.new()
	label.text = text
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