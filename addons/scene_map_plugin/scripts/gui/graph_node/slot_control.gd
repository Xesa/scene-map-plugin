extends HBoxContainer

const SM_SlotLabel := preload("uid://cpfngl4lqra2j")
const SM_DisconnectButton := preload("uid://0s4l0pgfen4i")
const SM_SidesButton := preload("uid://1wnhcluu7sn4")
const SM_TypeButton := preload("uid://tsvhet57a7bv")
const SM_NameButton := preload("uid://bswvc0ufqie7a")
const SM_LabelEdit := preload("uid://b2tk1xc6p0aa0")

var graph_edit : SceneMapGraph
var graph_node : SceneMapNode
var slot : SceneMapSlot
var index : int

var subcontrol : CenterContainer
var subcontainer : HBoxContainer
var label : SM_SlotLabel
var left_disconnect_button : SM_DisconnectButton
var right_disconnect_button: SM_DisconnectButton
var type_button : SM_TypeButton
var sides_button : SM_SidesButton
var name_button : SM_NameButton
var label_edit : SM_LabelEdit

var type_menu_open := false
var edit_menu_open := false


func _init(_graph_node : SceneMapNode, _slot : SceneMapSlot) -> void:
	name = _slot.component_uid
	graph_edit = _graph_node.get_parent()
	graph_node = _graph_node
	slot = _slot
	index = slot.index

	slot.control = self


func _ready() -> void:

	# Sets the control's properties
	add_theme_constant_override("separation", -5)
	set_anchors_preset(Control.LayoutPreset.PRESET_HCENTER_WIDE)

	# Creates a subcontrol and subcontainer for the center buttons and label
	subcontrol = CenterContainer.new()
	subcontrol.size_flags_horizontal = Control.SizeFlags.SIZE_EXPAND_FILL

	subcontainer = HBoxContainer.new()
	subcontainer.visible = false
	subcontainer.add_theme_constant_override("separation", -5)
	subcontainer.alignment = HBoxContainer.ALIGNMENT_CENTER
	subcontainer.size_flags_horizontal = Control.SizeFlags.SIZE_EXPAND_FILL
	subcontrol.add_child(subcontainer)

	# Creates a label
	label = SM_SlotLabel.new(self, index, slot.component_name)
	label_edit = SM_LabelEdit.new(self, slot)
	subcontrol.add_child(label)
	subcontrol.add_child(label_edit)

	# Creates the center buttons
	sides_button = SM_SidesButton.new(self, slot)
	type_button = SM_TypeButton.new(self, slot)
	name_button = SM_NameButton.new(self)

	subcontainer.add_child(sides_button)
	subcontainer.add_child(type_button)
	subcontainer.add_child(name_button)

	# Creates disconnect buttons
	left_disconnect_button = SM_DisconnectButton.new(self, slot, 0)
	right_disconnect_button = SM_DisconnectButton.new(self, slot, 1)

	# Adds children to the control
	add_child(left_disconnect_button)
	add_child(subcontrol)
	add_child(right_disconnect_button)

	# Connects the signals
	subcontrol.mouse_entered.connect(_on_mouse_entered)
	subcontrol.mouse_exited.connect(_on_mouse_exited)


func refresh_label() -> void:
	label.refresh_text(slot.index, slot.component_name)


func _on_mouse_entered() -> void:
	_toggle_subcontrol_visibility(true)


func _on_mouse_exited() -> void:
	if !type_menu_open and !edit_menu_open:
		_toggle_subcontrol_visibility(false)


func _on_type_menu_toggled(toggle : bool = false) -> void:
	type_menu_open = toggle
	if !toggle:
		_toggle_subcontrol_visibility(false)


func _on_edit_menu_toggled(toggle : bool = false) -> void:
	edit_menu_open = toggle
	if !toggle:
		_toggle_subcontrol_visibility(false)


func _toggle_subcontrol_visibility(toggle : bool) -> void:
	label.visible = !toggle
	subcontainer.visible = toggle
	sides_button.disabled = !toggle
	type_button.disabled = !toggle
	name_button.disabled = !toggle


func force_drag_release():
	graph_node.selected = false
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	ev.position = get_global_mouse_position()
	graph_edit.gui_input.emit(ev)