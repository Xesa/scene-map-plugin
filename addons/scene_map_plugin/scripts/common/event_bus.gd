extends Node
## SM_EventBus
##
## Event bus for tracking scene changes. Marks when components in the edited scene
## have been modified, allows querying if there are pending changes, and can clear the flag.

const SM_ComponentFinder := preload(SceneMapConstants.COMPONENT_FINDER)

static var pending_changes := false


## Marks that changes have occurred in the given node's scene.
## If the node belongs to the currently edited scene, sets the pending_changes flag to true.
static func notify_changes(node : Node) -> void:

	if node == null:
		return

	var current_root := SM_ComponentFinder.get_root_node(node)
	var edited_root := EditorInterface.get_edited_scene_root()

	if (current_root == edited_root):
		pending_changes = true


## Clears the pending changes flag.
static func clear_changes() -> void:
	pending_changes = false


## Returns true if there are pending changes in the edited scene, false otherwise.
static func has_changes() -> bool:
	return pending_changes