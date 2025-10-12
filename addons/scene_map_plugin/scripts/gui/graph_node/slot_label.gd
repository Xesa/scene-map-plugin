extends Label

const SM_SlotControl := preload("uid://bxwe2c1at0aom")

var control : SM_SlotControl

func _init(_control : SM_SlotControl, _index : int, _text : String) -> void:
	control = _control
	text = str(_index) + ". " + _text
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func refresh_text(_index : int, _text : String) -> void:
	text = str(_index) + ". " + _text