extends HBoxContainer

const SM_SlotLabel := preload("uid://cpfngl4lqra2j")
const SM_DisconnectButton := preload("uid://0s4l0pgfen4i")
const SM_SidesButton := preload("uid://1wnhcluu7sn4")

var graph_edit : SceneMapGraph
var graph_node : SceneMapNode
var slot : SceneMapSlot
var index : int

var subcontrol : CenterContainer
var subcontainer : HBoxContainer
var label : SM_SlotLabel
var left_disconnect_button : SM_DisconnectButton
var right_disconnect_button: SM_DisconnectButton
var edit_button
var sides_button : SM_SidesButton


func _init(_graph_node : SceneMapNode, _slot : SceneMapSlot) -> void:
	graph_edit = _graph_node.get_parent()
	graph_node = _graph_node
	slot = _slot
	index = slot.index


func _ready() -> void:

	# Sets the control's properties
	add_theme_constant_override("separation", -5)
	set_anchors_preset(Control.LayoutPreset.PRESET_HCENTER_WIDE)

	# Creates a subcontrol and subcontainer for the center buttons and label
	subcontrol = CenterContainer.new()
	subcontrol.size_flags_horizontal = Control.SizeFlags.SIZE_EXPAND_FILL

	subcontainer = HBoxContainer.new()
	subcontainer.visible = false
	subcontainer.add_theme_constant_override("separation", -10)
	subcontainer.alignment = HBoxContainer.ALIGNMENT_CENTER
	subcontainer.size_flags_horizontal = Control.SizeFlags.SIZE_EXPAND_FILL
	subcontrol.add_child(subcontainer)

	# Creates a label
	label = SM_SlotLabel.new(self, index, slot.component_name)
	subcontrol.add_child(label)

	# Creates the center buttons
	sides_button = SM_SidesButton.new(self, slot)
	subcontainer.add_child(sides_button)
	subcontainer.add_child(SM_SidesButton.new(self, slot))

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


func _on_mouse_entered() -> void:
	label.visible = false
	subcontainer.visible = true
	sides_button.disabled = false


func _on_mouse_exited() -> void:
	label.visible = true
	subcontainer.visible = false
	sides_button.disabled = true