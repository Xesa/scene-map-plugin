extends Button
## SM_SlotButtonName
##
## A Button that enables a [LabelEdit] control to allow renaming a [SceneMapSlot].

const SM_SlotControl := preload(SceneMapConstants.SLOT_CONTROL)

var control : SM_SlotControl


func _init(_control : SM_SlotControl) -> void:
	control = _control

	mouse_filter = HBoxContainer.MouseFilter.MOUSE_FILTER_PASS
	icon = load(SceneMapConstants.EDIT_ICON)
	flat = true
	disabled = true
	tooltip_text = "Change slot's name"

	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	control.label_edit.activate()
	control.label_edit.grab_focus()