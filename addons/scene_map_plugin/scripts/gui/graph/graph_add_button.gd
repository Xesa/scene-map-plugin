@tool
extends Button
## SM_AddButton
##
## A Button that opens the [SM_AddDialog] when pressed.


const SM_AddDialog := preload(SceneMapConstants.ADD_DIALOG)

var dialog : SM_AddDialog


func _ready() -> void:
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	dialog = SM_AddDialog.new()
	dialog.canceled.connect(_on_dialog_closed)
	Engine.get_singleton("SceneMapPlugin").panel.add_child(dialog)


func _on_dialog_closed() -> void:
	dialog.queue_free()
	dialog = null