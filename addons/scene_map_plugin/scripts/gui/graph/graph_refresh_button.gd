@tool
extends Button

const SM_NodeRefresher := preload(SceneMapConstants.NODE_REFRESHER)
const SM_AddDialog := preload(SceneMapConstants.ADD_DIALOG)
const SceneMapGraph := preload(SceneMapConstants.SCENE_MAP_GRAPH)
const SceneMapNode := preload(SceneMapConstants.SCENE_MAP_NODE)

var panel : Control
var graph : SceneMapGraph

signal dialog_created(dialog : SM_AddDialog)
signal node_created(node : SceneMapNode)


func _ready() -> void:
	panel = owner as Control
	graph = panel.get_node("SceneMapGraph")
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	SM_NodeRefresher.scan_all_scenes(graph)