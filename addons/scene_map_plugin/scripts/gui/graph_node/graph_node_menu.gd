extends PopupMenu

const SceneMapGraph := preload(SceneMapConstants.SCENE_MAP_GRAPH)
const SceneMapNode := preload(SceneMapConstants.SCENE_MAP_NODE)

var graph_edit : SceneMapGraph
var graph_node : SceneMapNode


func _init(_graph_node : SceneMapNode) -> void:
	graph_edit = _graph_node.graph_edit
	graph_node = _graph_node

	visible = true

	add_item("Open scene (double-click)")
	add_item("Delete node (DEL)")
	reset_size()

func _ready() -> void:
	index_pressed.connect(_on_item_pressed)
	focus_exited.connect(_on_focus_lost)
	popup_hide.connect(_on_popup_hidden)


func _on_item_pressed(index : int):
	match index:
		0: graph_node.open_scene_in_editor()
		1: graph_node._delete()


func _on_popup_hidden() -> void:
	graph_edit.remove_child(self)
	graph_edit.force_drag_release(graph_node)


func _on_focus_lost() -> void:
	popup_hide.emit()


func make_visible(mouse_position : Vector2) -> void:
	visible = true
	position = mouse_position