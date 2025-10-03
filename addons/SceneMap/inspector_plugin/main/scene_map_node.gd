@tool
class_name SceneMapNode extends GraphNode

var scene_path : String
var scene_uid : String

var should_register_slots : bool
var set_to_delete := false

var preview : TextureRect
var component_slots : Array[SceneMapSlot]

var scene_resource : PackedScene
var scene_instance : Node

signal node_deleted()


func _init(_scene_uid : String, _scene_path : String = "",  _register_slots : bool = true) -> void:
	scene_path = _scene_path
	scene_uid = _scene_uid
	title = scene_path
	name = scene_uid
	should_register_slots = _register_slots

	scene_resource = load("uid://"+scene_uid) as PackedScene
	scene_instance = scene_resource.instantiate()


func _ready() -> void:

	await SceneMapResourceTools.pre_save_scene(scene_path)

	await NodePreviewer.create_preview(self)
	if should_register_slots:
		await SlotRegistrator.new(self).register_slots()

	await SceneMapResourceTools.post_save_scene(scene_resource, scene_instance, scene_path)
	SceneMapIO.save(get_parent())

	scene_resource = null
	scene_instance.queue_free()


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