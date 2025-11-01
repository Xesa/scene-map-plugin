@tool
extends Button
## SM_RefreshButton
##
## A Button that resfreshes all nodes when pressed.
## It makes use of the [SM_NodeRefresher] class.

const SM_NodeRefresher := preload(SceneMapConstants.NODE_REFRESHER)


func _ready() -> void:
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	SM_NodeRefresher.scan_all_scenes()