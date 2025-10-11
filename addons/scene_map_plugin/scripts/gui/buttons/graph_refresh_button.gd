@tool
extends Button

const SM_SceneScanner := preload("uid://c4uyy81d0q134")

var panel : Control
var graph : SceneMapGraph

signal dialog_created(dialog : SceneMapAddDialog)
signal node_created(node : SceneMapNode)


func _ready() -> void:
	panel = owner as Control
	graph = panel.get_node("SceneMapGraph")
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	SM_SceneScanner.scan_all_scenes(graph)