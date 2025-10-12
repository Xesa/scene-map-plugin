extends Node

const SM_Enums := preload("uid://cukwm8rnmlicq")

## Returns the connection type depending on the [type] and [side] properties from each component.
## [br] [1] means the connection goes from left to right.
## [br] [-1] means the connection goes from right to left.
## [br] [2] means it is a double sided connections.
## [br] [0] means it is a non-valid connection.
static func get_connection_type(from_slot : SceneMapSlot, to_slot : SceneMapSlot, connect : bool = true) -> int:

	if from_slot == null or to_slot == null:
		return 0

	if from_slot.scene_uid == to_slot.scene_uid:
		return 0

	var from_already_connected := from_slot.has_outgoing_connections()
	var to_already_connected := to_slot.has_outgoing_connections()

	if from_slot.type == SM_Enums.Type.EXIT and to_slot.type == SM_Enums.Type.ENTRY:
		if connect and from_already_connected:
			return 0
		return 1

	if from_slot.type == SM_Enums.Type.ENTRY and to_slot.type == SM_Enums.Type.EXIT:
		if connect and to_already_connected:
			return 0
		return -1

	if from_slot.type == SM_Enums.Type.TWO_WAY and to_slot.type == SM_Enums.Type.TWO_WAY:
		if connect and (from_already_connected or to_already_connected):
			return 0
		return 2

	if from_slot.type == SM_Enums.Type.FUNNEL:

		if to_slot.type == SM_Enums.Type.ENTRY and from_slot.side == SM_Enums.Side.LEFT:
			if connect and from_already_connected:
				return 0
			return 1

		if to_slot.type == SM_Enums.Type.EXIT and from_slot.side == SM_Enums.Side.RIGHT:
			if connect and to_already_connected:
				return 0
			return -1

		if to_slot.type == SM_Enums.Type.FUNNEL \
		and from_slot.side == SM_Enums.Side.LEFT and to_slot.side == SM_Enums.Side.LEFT:
			if connect and from_already_connected:
				return 0
			return 1

	if to_slot.type == SM_Enums.Type.FUNNEL:

		if from_slot.type == SM_Enums.Type.EXIT and to_slot.side == SM_Enums.Side.LEFT:
			if connect and from_already_connected:
				return 0
			return 1

		if from_slot.type == SM_Enums.Type.ENTRY and to_slot.side == SM_Enums.Side.RIGHT:
			if connect and to_already_connected:
				return 0
			return -1

		if from_slot.type == SM_Enums.Type.FUNNEL \
		and to_slot.side == SM_Enums.Side.RIGHT and from_slot.side == SM_Enums.Side.RIGHT:
			if connect and to_already_connected:
				return 0
			return -1

	return 0


static func get_connection_direction(from_slot : SceneMapSlot, to_slot : SceneMapSlot) -> int:

	if from_slot.type == SM_Enums.Type.FUNNEL:
		if from_slot.side == SM_Enums.Side.LEFT:
			return 1
		else:
			return -1
	
	elif from_slot.side == SM_Enums.Side.LEFT:
		return -1
	else:
		return 1