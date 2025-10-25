@tool
extends Button
## SM_UpdateButton
##
## A Button that opens the [SM_UpdateDialog] when pressed.

const SM_UpdateDialog := preload(SceneMapConstants.UPDATE_DIALOG)

var update_dialog : SM_UpdateDialog


func _ready() -> void:
	toggle_visibility(false)
	update_dialog = SceneMapConstants.PANEL_REFERENCE.update_dialog
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	update_dialog.toggle_visiblity(true)


func toggle_visibility(toggle : bool) -> void:
	visible = toggle