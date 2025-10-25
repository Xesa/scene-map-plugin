extends Button
## SM_SlotButtonSide
##
## A Button that toggles the side of a [SceneMapSlot] when pressed.
## This button remains disabled unless the slot configuration allows side changes.

const SM_SlotControl := preload(SceneMapConstants.SLOT_CONTROL)
const SceneMapSlot := preload(SceneMapConstants.SCENE_MAP_SLOT)

var control : SM_SlotControl
var slot : SceneMapSlot


func _init(_control : SM_SlotControl, _slot : SceneMapSlot) -> void:
	control = _control
	slot = _slot

	mouse_filter = HBoxContainer.MouseFilter.MOUSE_FILTER_PASS
	icon = load(SceneMapConstants.SIDES_ICON)
	flat = true
	disabled = true
	tooltip_text = "Change slot's side"


func _ready() -> void:
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	slot.change_sides()