extends Button

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_SlotControl := preload("uid://bxwe2c1at0aom")

var control : SM_SlotControl
var slot : SceneMapSlot


func _init(_control : SM_SlotControl, _slot : SceneMapSlot) -> void:
	control = _control
	slot = _slot

	mouse_filter = HBoxContainer.MouseFilter.MOUSE_FILTER_PASS
	icon = load(SM_Constants.SIDES_ICON)
	flat = true
	disabled = true
	tooltip_text = "Change slot's side"


func _ready() -> void:
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	slot.change_sides()