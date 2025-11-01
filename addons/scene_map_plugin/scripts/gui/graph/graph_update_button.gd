@tool
extends Button
## SM_UpdateButton
##
## A Button that opens the [SM_UpdateDialog] when pressed.


func _ready() -> void:
	toggle_visibility(false)
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	Engine.get_singleton("SceneMapPlugin").panel.update_dialog.toggle_visiblity(true)


func toggle_visibility(toggle : bool) -> void:
	visible = toggle