extends Node

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")
const SM_ResourceTools := preload("uid://cwik34k5w34y1")
const SM_SceneSaver := preload("uid://7svcgc01kw2b")

var graph_node : SceneMapNode

var general_counter : int
var specific_counters : Dictionary

var slot_config : Dictionary


func _init(_graph_node : SceneMapNode) -> void:
	graph_node = _graph_node
	

## Creates connection slots for each [SceneMapComponent] found in the scene.
## Depending on the property [type] of the [SceneMapComponent], the connection slot will be either on the left side, right side or both sides.
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
	
	# Gets all the [SceneMapComponent] in the scene
	var components := SM_ComponentFinder.find_all_components(scene_values.instance)

	# Sets an invisible node, otherwise the rest of nodes won't work properly
	graph_node.set_slot(0, true, 1, Color.TRANSPARENT, true, 1, Color.TRANSPARENT)

	# Iterates each component from each type and registers them
	for key in specific_counters.keys():
		for component in components[key]:
			general_counter += 1
			specific_counters[key] += 1
			_register_component_as_slot(scene_values.instance, component, key)

	# Saves the scene
	await SM_SceneSaver.save()


## Registers a new connection slot. Depending on the parameter [type] it will create it
## on the left side, right side or both sides.
func _register_component_as_slot(scene_instance : Node, component : SceneMapComponent, key : String) -> void:

	# Gets the slot configuration for this component type
	var config = SM_Constants.SLOT_CONFIG[component.type]

	var component_path : NodePath = scene_instance.get_path_to(component)

	# Creates a text label
	var label = Label.new()
	label.text = "%s %d" % [config.label, specific_counters[key]]
	graph_node.add_child(label)

	# Sets the the left and right slots as enabled or disabled depending on the combination of type and side
	var left_side := true if component.side == SceneMapComponent.Side.LEFT else false
	var right_side := true if component.side == SceneMapComponent.Side.RIGHT else false

	var left_icon_path : String = config["icons"][0]
	var right_icon_path : String = config["icons"][1]

	if component.type == SceneMapComponent.Type.FUNNEL:
		left_side = true
		right_side = true

		if component.side == SceneMapComponent.Side.LEFT:
			left_icon_path = config["icons"][0]
			right_icon_path = config["icons"][0]

		if component.side == SceneMapComponent.Side.RIGHT:
			left_icon_path = config["icons"][1]
			right_icon_path = config["icons"][1]

	var left_icon : Texture2D = load(left_icon_path)
	var right_icon : Texture2D = load(right_icon_path)

	# Adds the slot to the graph node
	graph_node.set_slot(
		general_counter,
		left_side, 0, Color.WHITE,
		right_side, 0, Color.WHITE,
		left_icon, right_icon
	)

	# Creates a slot object
	var slot := SceneMapSlot.new(
				component.type,
				component.side,
				general_counter,
				specific_counters[key],
				left_side,
				right_side,
				left_icon_path,
				right_icon_path,
				graph_node.scene_uid,
	)

	# Adds the slot object to the graph node
	graph_node.add_child(slot)
	graph_node.component_slots.append(slot)

	# Sets a UID to the component
	component._set_component_uid(slot.component_uid)