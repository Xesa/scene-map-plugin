@tool
extends Button
## SM_AboutButton
##
## A Button that opens the [SM_AboutDialog] when pressed.

const SM_AboutDialog := preload(SceneMapConstants.ABOUT_DIALOG)

var about_dialog : SM_AboutDialog


func _ready() -> void:
	about_dialog = SceneMapConstants.PANEL_REFERENCE.about_dialog
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	about_dialog.toggle_visiblity(true)