@tool
class_name SlotRegistrator extends SceneMapHelper

var graph_node : SceneMapNode

var arrow_left : Texture2D
var arrow_right : Texture2D
var arrow_double : Texture2D

var general_counter : int
var specific_counters : Dictionary

var scene_instance : Node

const ARROW_LEFT := "res://addons/SceneMap/Assets/arrow-left.svg"
const ARROW_RIGHT := "res://addons/SceneMap/Assets/arrow-right.svg"
const ARROW_DOUBLE := "res://addons/SceneMap/Assets/arrow-double.svg"

var SLOT_CONFIG = {
	SceneMapComponent.Type.ENTRY:	{"label": "Entrance",	"icons": [arrow_right, arrow_left]},
	SceneMapComponent.Type.EXIT:	{"label": "Exit",		"icons": [arrow_left, arrow_right]},
	SceneMapComponent.Type.TWO_WAY:	{"label": "Two-way",	"icons": [arrow_double, arrow_double]},
	SceneMapComponent.Type.FUNNEL:	{"label": "Funnel",		"icons": [arrow_double, arrow_double]},
}


func _init(_graph_node : SceneMapNode) -> void:
	graph_node = _graph_node
	arrow_left = load(ARROW_LEFT)
	arrow_right = load(ARROW_RIGHT)
	arrow_double = load(ARROW_DOUBLE)


## Creates connection slots for each [SceneMapComponent] found in the scene.
## Depending on the property [type] of the [SceneMapComponent], the connection slot will be either on the left side, right side or both sides.
func register_slots() -> void:

	EditorInterface.save_all_scenes()

	# Reloads the scene to avoid overwriting data
	EditorInterface.reload_scene_from_path(graph_node.scene_path)
	await Engine.get_main_loop().process_frame

	# Instantiates the node's scene
	graph_node.scene = load("uid://"+graph_node.scene_uid)
	scene_instance = graph_node.scene.instantiate()

	graph_node.component_slots = []

	general_counter = 0
	specific_counters = {
		"funnels" : 0,
		"entrances" : 0,
		"exits" : 0,
		"two_ways" : 0
	}

	# Gets all the [SceneMapComponent] in the scene
	var slots := ComponentFinder.new(graph_node).find()

	# Iterates each component from each type and registers them
	for key in specific_counters.keys():
		for slot in slots[key]:
			general_counter += 1
			specific_counters[key] += 1

			register_slot(slot, key)


	# Saves the changes to the scene
	graph_node.scene.pack(scene_instance)
	await ResourceSaver.save(graph_node.scene, graph_node.scene_path)
	await Engine.get_main_loop().process_frame

	# Reloads the scene to show the changes in the editor
	EditorInterface.reload_scene_from_path(graph_node.scene_path)
	await Engine.get_main_loop().process_frame


## Registers a new connection slot. Depending on the parameter [type] it will create it
## on the left side, right side or both sides.
func register_slot(slot : SceneMapSlot, key : String) -> void:

	# Gets the slot configuration for this component type
	var config = SLOT_CONFIG[slot.type]

	# Creates a text label
	var label = Label.new()
	label.text = "%s %d" % [config.label, specific_counters[key]]
	graph_node.add_child(label)

	# Sets the the left and right slots as enabled or disabled depending on the combination of type and side
	var left_side := true if slot.side == SceneMapComponent.Side.LEFT else false
	var right_side := true if slot.side == SceneMapComponent.Side.RIGHT else false

	if slot.type == SceneMapComponent.Type.FUNNEL:
		left_side = true
		right_side = true

	# Adds the slot
	graph_node.set_slot(
		general_counter,
		left_side, 0, Color.WHITE,
		right_side, 0, Color.WHITE,
		config.icons[0], config.icons[1]
	)

	slot.set_slot_info(general_counter, specific_counters[key], left_side, right_side)
	graph_node.component_slots.append(slot)

	slot.component.component_id = ResourceUID.create_id()