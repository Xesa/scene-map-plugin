extends Button

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_SlotControl := preload("uid://bxwe2c1at0aom")

var control : SM_SlotControl


func _init(_control : SM_SlotControl) -> void:
	control = _control

	mouse_filter = HBoxContainer.MouseFilter.MOUSE_FILTER_PASS
	icon = load(SM_Constants.EDIT_ICON)
	flat = true
	disabled = true
	tooltip_text = "Change slot's name"

	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	control.label_edit.activate()
	control.label_edit.grab_focus()