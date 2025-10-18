extends Button

const SM_Enums := preload(SceneMapConstants.ENUMS)
const SM_SlotControl := preload(SceneMapConstants.SLOT_CONTROL)
const SceneMapSlot := preload(SceneMapConstants.SCENE_MAP_SLOT)



var control : SM_SlotControl
var slot : SceneMapSlot
var is_connected := false
var button_side : int
var force_disabled := false

func _init(_control : SM_SlotControl, _slot : SceneMapSlot, _button_side : int) -> void:
	control = _control
	slot = _slot
	button_side = _button_side
	icon = load(SceneMapConstants.DISCONNECT_ICON)
	flat = true
	disabled = true
	tooltip_text = "Remove connections"
	_toggle_visibility()


func _ready() -> void:
	pressed.connect(_on_button_pressed)
	slot.connection_added.connect(_on_connection_added)
	slot.connection_removed.connect(_on_connection_removed)
	slot.side_changed.connect(_toggle_visibility)
	slot.type_changed.connect(_toggle_visibility)

	if _has_connections():
		_enable()


func _on_button_pressed() -> void:
	if is_connected:
		_remove_connections()
		_disable()


func _on_connection_added(_connection : SceneMapSlot, direction : int) -> void:
	if slot.type != SM_Enums.Type.FUNNEL:
		_enable()

	elif button_side == 0 and slot.side == SM_Enums.Side.LEFT and direction == 0:
		_enable()

	elif button_side == 0 and slot.side == SM_Enums.Side.RIGHT and direction == 1:
		_enable()

	elif button_side == 1 and slot.side == SM_Enums.Side.LEFT and direction == 1:
		_enable()

	elif button_side == 1 and slot.side == SM_Enums.Side.RIGHT and direction == 0:
		_enable()


func _on_connection_removed(_connection : SceneMapSlot, _direction : int) -> void:
	if not _has_connections():
		_disable()


func _enable() -> void:
	if !force_disabled:
		is_connected = true
		disabled = false


func _disable() -> void:
	is_connected = false
	disabled = true


func _has_connections() -> bool:

	var incoming = slot.has_incoming_connections()
	var outgoing = slot.has_outgoing_connections()

	match slot.type:
		SM_Enums.Type.FUNNEL:
			return (slot.side == SM_Enums.Side.LEFT and ((button_side == 0 and incoming) or (button_side == 1 and outgoing))) \
				or (slot.side == SM_Enums.Side.RIGHT and ((button_side == 0 and outgoing) or (button_side == 1 and incoming)))
		SM_Enums.Type.TWO_WAY:
			return incoming or outgoing
		SM_Enums.Type.EXIT:
			return outgoing
		SM_Enums.Type.ENTRY:
			return incoming
		_:
			return false


func _get_connections() -> Array[SceneMapSlot]:
	match slot.type:
		SM_Enums.Type.FUNNEL:
			if button_side == 0 and slot.side == SM_Enums.Side.LEFT:
				return slot.get_connections(0)
			if button_side == 0 and slot.side == SM_Enums.Side.RIGHT:
				return slot.get_connections(1)
			if button_side == 1 and slot.side == SM_Enums.Side.LEFT:
				return slot.get_connections(1)
			if button_side == 1 and slot.side == SM_Enums.Side.RIGHT:
				return slot.get_connections(0)
			else:
				return []

		SM_Enums.Type.TWO_WAY:
			return slot.get_connections(button_side)
		SM_Enums.Type.EXIT:
			return slot.get_connections(1)
		SM_Enums.Type.ENTRY:
			return slot.get_connections(0)
		_:
			return []


func _remove_connections() -> void:

	var connections := _get_connections()

	var conn : SceneMapSlot = connections[0]

	if button_side == 0:
		for connection in connections:
			control.graph_edit.disconnection_request.emit(
				connection.scene_uid,
				connection.index,
				slot.scene_uid,
				slot.index
			)

	else:
		for connection in connections:
			control.graph_edit.disconnection_request.emit(
				slot.scene_uid,
				slot.index,
				connection.scene_uid,
				connection.index
			)


func _toggle_visibility(_variant : Variant = null) -> void:
	if slot.type == SM_Enums.Type.FUNNEL or \
		(button_side == 0 and slot.side == SM_Enums.Side.LEFT) or \
		(button_side == 1 and slot.side == SM_Enums.Side.RIGHT):
		force_disabled = false
		modulate.a = 1

	else:
		force_disabled = true
		disabled = true
		modulate.a = 0

