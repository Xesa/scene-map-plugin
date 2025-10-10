extends Button

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_SlotControl := preload("uid://bxwe2c1at0aom")

var control : SM_SlotControl
var slot : SceneMapSlot
var is_connected := false
var button_side : int

func _init(_control : SM_SlotControl, _slot : SceneMapSlot, _button_side : int) -> void:
	control = _control
	slot = _slot
	button_side = _button_side
	icon = load(SM_Constants.DISCONNECT_ICON)
	flat = true
	disabled = true
	tooltip_text = "Remove connections"


func _ready() -> void:
	pressed.connect(_on_button_pressed)
	slot.connection_added.connect(_on_connection_added)
	slot.connection_removed.connect(_on_connection_removed)

	if _has_connections():
		_enable()


func _on_button_pressed() -> void:
	if is_connected:
		_remove_connections()
		_disable()


func _on_connection_added(_connection : SceneMapSlot, direction : int) -> void:
	if slot.type != SceneMapComponent2D.Type.FUNNEL:
		_enable()

	elif button_side == 0 and slot.side == SceneMapComponent2D.Side.LEFT and direction == 0:
		_enable()

	elif button_side == 0 and slot.side == SceneMapComponent2D.Side.RIGHT and direction == 1:
		_enable()

	elif button_side == 1 and slot.side == SceneMapComponent2D.Side.LEFT and direction == 1:
		_enable()

	elif button_side == 1 and slot.side == SceneMapComponent2D.Side.RIGHT and direction == 0:
		_enable()


func _on_connection_removed(_connection : SceneMapSlot, _direction : int) -> void:
	if not _has_connections():
		_disable()


func _enable() -> void:
	is_connected = true
	disabled = false


func _disable() -> void:
	is_connected = false
	disabled = true


func _has_connections() -> bool:

	var incoming = slot.has_incoming_connections()
	var outgoing = slot.has_outgoing_connections()

	match slot.type:
		SceneMapComponent2D.Type.FUNNEL:
			return (slot.side == SceneMapComponent2D.Side.LEFT and ((button_side == 0 and incoming) or (button_side == 1 and outgoing))) \
				or (slot.side == SceneMapComponent2D.Side.RIGHT and ((button_side == 0 and outgoing) or (button_side == 1 and incoming)))
		SceneMapComponent2D.Type.TWO_WAY:
			return incoming or outgoing
		SceneMapComponent2D.Type.EXIT:
			return outgoing
		SceneMapComponent2D.Type.ENTRY:
			return incoming
		_:
			return false


func _get_connections() -> Array[SceneMapSlot]:
	match slot.type:
		SceneMapComponent2D.Type.FUNNEL:
			if button_side == 0 and slot.side == SceneMapComponent2D.Side.LEFT:
				return slot.get_connections(0)
			if button_side == 0 and slot.side == SceneMapComponent2D.Side.RIGHT:
				return slot.get_connections(1)
			if button_side == 1 and slot.side == SceneMapComponent2D.Side.LEFT:
				return slot.get_connections(1)
			if button_side == 1 and slot.side == SceneMapComponent2D.Side.RIGHT:
				return slot.get_connections(0)
			else:
				return []

		SceneMapComponent2D.Type.TWO_WAY:
			return slot.get_connections(button_side)
		SceneMapComponent2D.Type.EXIT:
			return slot.get_connections(1)
		SceneMapComponent2D.Type.ENTRY:
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