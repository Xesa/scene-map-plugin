@tool
extends Button

const SM_NodeRegistrator := preload(SceneMapConstants.NODE_REGISTRATOR)
const SM_AddDialog := preload(SceneMapConstants.ADD_DIALOG)
const SceneMapGraph := preload(SceneMapConstants.SCENE_MAP_GRAPH)
const SceneMapNode := preload(SceneMapConstants.SCENE_MAP_NODE)

var panel : Control
var graph : SceneMapGraph
var dialog : SM_AddDialog

signal dialog_created(dialog : SM_AddDialog)
signal node_created(node : SceneMapNode)


func _ready() -> void:
	panel = owner as Control
	graph = panel.get_node("SceneMapGraph")
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	dialog = SM_AddDialog.new()
	dialog.scene_selected.connect(_on_scene_selected)
	dialog.canceled.connect(_on_dialog_closed)
	panel.add_child(dialog)


func _on_scene_selected(scene_path : String) -> void:
	SM_NodeRegistrator.register_scene(graph, scene_path)
	_on_dialog_closed()


func _on_dialog_closed() -> void:
	dialog.queue_free()
	dialog = null