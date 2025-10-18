extends Node

const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")

static var pending_changes := false


static func notify_changes(node : Node) -> void:

	if node == null:
		return

	var current_root := SM_ComponentFinder.get_root_node(node)
	var edited_root := EditorInterface.get_edited_scene_root()

	if (current_root == edited_root):
		pending_changes = true


static func clear_changes() -> void:
	pending_changes = false


static func has_changes() -> bool:
	return pending_changes