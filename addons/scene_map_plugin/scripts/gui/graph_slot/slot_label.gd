extends Label
## SM_SlotLabel
##
## A Label node representing a [SceneMapSlot] index and its name.
## Displays the index followed by the slot's text, centered both horizontally and vertically.

const SM_SlotControl := preload(SceneMapConstants.SLOT_CONTROL)

var control : SM_SlotControl

func _init(_control : SM_SlotControl, _index : int, _text : String) -> void:
	control = _control
	text = str(_index) + ". " + _text
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func refresh_text(_index : int, _text : String) -> void:
	text = str(_index) + ". " + _text