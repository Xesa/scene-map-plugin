extends Node

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")
const SM_ResourceTools := preload("uid://cwik34k5w34y1")

var graph_node : SceneMapNode

var arrow_left : Texture2D
var arrow_right : Texture2D
var arrow_double : Texture2D

var general_counter : int
var specific_counters : Dictionary

var SLOT_CONFIG = {
	SceneMapComponent.Type.ENTRY:	{"label": "Entrance",	"icons": [arrow_right, arrow_left]},
	SceneMapComponent.Type.EXIT:	{"label": "Exit",		"icons": [arrow_left, arrow_right]},
	SceneMapComponent.Type.TWO_WAY:	{"label": "Two-way",	"icons": [arrow_double, arrow_double]},
	SceneMapComponent.Type.FUNNEL:	{"label": "Funnel",		"icons": [arrow_double, arrow_double]},
}


func _init(_graph_node : SceneMapNode) -> void:
	graph_node = _graph_node
	arrow_left = load(SM_Constants.ARROW_LEFT)
	arrow_right = load(SM_Constants.ARROW_RIGHT)
	arrow_double = load(SM_Constants.ARROW_DOUBLE)


## Creates connection slots for each [SceneMapComponent] found in the scene.
## Depending on the property [type] of the [SceneMapComponent], the connection slot will be either on the left side, right side or both sides.
func register_slots() -> void:

	graph_node.component_slots = []

	general_counter = 0
	specific_counters = {
		"funnels" : 0,
		"entrances" : 0,
		"exits" : 0,
		"two_ways" : 0
	}

	# Gets all the [SceneMapComponent] in the scene
	var components := SM_ComponentFinder.find_all_components(graph_node.scene_instance)

	# Iterates each component from each type and registers them
	for key in specific_counters.keys():
		for component in components[key]:
			general_counter += 1
			specific_counters[key] += 1

			_register_component_as_slot(component, key)


## Registers a new connection slot. Depending on the parameter [type] it will create it
## on the left side, right side or both sides.
func _register_component_as_slot(component : SceneMapComponent, key : String) -> void:

	# Gets the slot configuration for this component type
	var config = SLOT_CONFIG[component.type]

	var component_path := graph_node.scene_instance.get_path_to(component)

	# Creates a text label
	var label = Label.new()
	label.text = "%s %d" % [config.label, specific_counters[key]]
	graph_node.add_child(label)

	# Sets the the left and right slots as enabled or disabled depending on the combination of type and side
	var left_side := true if component.side == SceneMapComponent.Side.LEFT else false
	var right_side := true if component.side == SceneMapComponent.Side.RIGHT else false

	if component.type == SceneMapComponent.Type.FUNNEL:
		left_side = true
		right_side = true

	# Adds the slot to the graph node
	graph_node.set_slot(
		general_counter,
		left_side, 0, Color.WHITE,
		right_side, 0, Color.WHITE,
		config.icons[0], config.icons[1]
	)

	var slot := SceneMapSlot.new(
				graph_node.scene_path,
				graph_node.scene_uid,
				component_path,
				component.type,
				component.side,
				general_counter,
				specific_counters[key],
				left_side,
				right_side
	)

	graph_node.add_child(slot)
	graph_node.component_slots.append(slot)

	# Sets a UID to the component
	slot.component_uid = SM_ResourceTools.generate_component_uid()
	var component_instance : SceneMapComponent = graph_node.scene_instance.get_node(slot.component_path)
	component_instance._set_component_uid(slot.component_uid)