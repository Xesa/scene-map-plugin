extends Node

## Returns the connection type depending on the [type] and [side] properties from each component.
## [br] [1] means the connection goes from left to right.
## [br] [-1] means the connection goes from right to left.
## [br] [2] means it is a double sided connections.
## [br] [0] means it is a non-valid connection.
static func get_connection_type(from_slot : SceneMapSlot, to_slot : SceneMapSlot, connect : bool = true) -> int:

	var from_already_connected := from_slot.connected_to.size() > 0
	var to_already_connected := to_slot.connected_to.size() > 0

	if from_slot.scene_uid == to_slot.scene_uid:
		return 0

	if from_slot.type == SceneMapComponent.Type.EXIT and to_slot.type == SceneMapComponent.Type.ENTRY:
		if connect and from_already_connected:
			print("Invalid connection: exit node already connected.")
			return 0
		return 1

	if from_slot.type == SceneMapComponent.Type.ENTRY and to_slot.type == SceneMapComponent.Type.EXIT:
		if connect and to_already_connected:
			print("Invalid connection: exit node already connected.")
		return -1

	if from_slot.type == SceneMapComponent.Type.TWO_WAY and to_slot.type == SceneMapComponent.Type.TWO_WAY:
		if connect and (from_already_connected or to_already_connected):
			print("Invalid connection: one of the nodes is already connected.")
			return 0
		return 2

	if from_slot.type == SceneMapComponent.Type.FUNNEL:

		if to_slot.type == SceneMapComponent.Type.ENTRY and from_slot.side == SceneMapComponent.Side.LEFT:
			return 1

		if to_slot.type == SceneMapComponent.Type.EXIT and from_slot.side == SceneMapComponent.Side.RIGHT:
			return -1

		if to_slot.type == SceneMapComponent.Type.FUNNEL \
		and from_slot.side == SceneMapComponent.Side.LEFT and to_slot.side == SceneMapComponent.Side.LEFT:
			return 1

	if to_slot.type == SceneMapComponent.Type.FUNNEL:

		if from_slot.type == SceneMapComponent.Type.EXIT and to_slot.side == SceneMapComponent.Side.LEFT:
			return 1

		if from_slot.type == SceneMapComponent.Type.ENTRY and to_slot.side == SceneMapComponent.Side.RIGHT:
			return -1

		if from_slot.type == SceneMapComponent.Type.FUNNEL \
		and to_slot.side == SceneMapComponent.Side.RIGHT and from_slot.side == SceneMapComponent.Side.RIGHT:
			return -1

	return 0
