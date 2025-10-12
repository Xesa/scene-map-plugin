@tool
extends Button

const SM_NodeRefresher := preload("uid://up5v7v7p5u60")

var panel : Control
var graph : SceneMapGraph

signal dialog_created(dialog : SceneMapAddDialog)
signal node_created(node : SceneMapNode)


func _ready() -> void:
	panel = owner as Control
	graph = panel.get_node("SceneMapGraph")
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	SM_NodeRefresher.scan_all_scenes(graph)