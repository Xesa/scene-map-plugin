@tool
class_name SceneMapNode extends GraphNode

@export var scene_path : String
@export var component_slots : Array[SceneMapSlot]

var scene : PackedScene
var scene_uid : String
var preview : TextureRect
var should_register_slots : bool
var set_to_delete := false

const VIEWPORT_SIZE := Vector2i(256,256)

signal node_deleted()


func _init(_scene_uid : String, _scene_path : String = "",  _register_slots : bool = true) -> void:
	scene_path = _scene_path
	scene_uid = _scene_uid
	title = scene_path
	name = scene_uid
	should_register_slots = _register_slots
	scene = load("uid://"+scene_uid)


func _ready() -> void:
	NodePreviewer.create_preview(self)
	if should_register_slots:
		SlotRegistrator.new(self).register_slots()


func _process(delta : float) -> void:
	if Input.is_key_pressed(KEY_DELETE) and selected and not set_to_delete:
		_delete()
	if Input.is_key_pressed(KEY_CTRL) and selected and not set_to_delete:
		pass


func _delete() -> void:
	set_to_delete = true
	EditorInterface.save_all_scenes()
	for slot in component_slots:
		slot.remove_all_connections()
	queue_free()


func get_component_slot(index : int) -> SceneMapSlot:
	return component_slots.get(index)