extends LineEdit

const SM_SlotControl := preload(SceneMapConstants.SLOT_CONTROL)
const SceneMapSlot := preload(SceneMapConstants.SCENE_MAP_SLOT)

var control : SM_SlotControl
var slot : SceneMapSlot

var is_active := false


func _init(_control : SM_SlotControl, _slot : SceneMapSlot) -> void:
	control = _control
	slot = _slot

	placeholder_text = "Enter custom name..."
	max_length = 64
	add_theme_font_size_override("font_size", 11)
	clear_button_enabled = true
	drag_and_drop_selection_enabled = false
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	flat = true
	editable = false
	visible = false


func _ready() -> void:
	text_submitted.connect(_on_text_submitted)
	focus_exited.connect(_on_focus_exited)


func activate() -> void:
	if slot.component_name_is_custom:
		text = slot.component_name
	else:
		text = ""

	custom_minimum_size.x = control.subcontrol.size.x
	custom_minimum_size.y = 5
	size.y = 1
	visible = true
	editable = true
	is_active = true
	control.edit_menu_open = true
	control._toggle_subcontrol_visibility(false)
	control.label.visible = false


func deactivate() -> void:
	visible = false
	editable = false
	is_active = false
	control.edit_menu_open = false
	control._toggle_subcontrol_visibility(false)


func _on_text_submitted(new_text : String) -> void:
	_change_name()
	deactivate()


func _on_focus_exited() -> void:
	if is_active:
		_change_name()
		deactivate()


func _change_name() -> void:
	if text == "":
		slot.remove_component_name()
	else:
		slot.set_component_name(text)
