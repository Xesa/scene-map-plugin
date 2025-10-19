@tool
extends Button

const SM_UpdateDialog := preload(SceneMapConstants.UPDATE_DIALOG)

var panel : Control
var update_dialog : SM_UpdateDialog


func _ready() -> void:
	toggle_visibility(false)
	panel = owner as Control
	update_dialog = panel.get_node("SceneMapUpdateDialog")
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	update_dialog.toggle_visiblity(true)


func toggle_visibility(toggle : bool) -> void:
	visible = toggle