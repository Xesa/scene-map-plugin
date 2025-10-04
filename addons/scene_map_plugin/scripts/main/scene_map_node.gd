@tool
class_name SceneMapNode extends GraphNode

const SM_ResourceTools := preload("uid://cwik34k5w34y1")
const SM_NodePreviewer := preload("uid://brgihuj5exdgu")
const SM_SlotRegistrator := preload("uid://bj10g5ips4ubj")
const SM_SceneSaver := preload("uid://7svcgc01kw2b")
const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")

var scene_path : String
var scene_uid : String

var set_to_create : bool
var set_to_delete := false

var preview : TextureRect
var component_slots : Array[SceneMapSlot]

signal node_deleted()
signal node_ready()


func _init(_scene_uid : String, _scene_path : String = "",  _set_to_create : bool = true) -> void:
	scene_path = _scene_path
	scene_uid = _scene_uid
	title = scene_path
	name = scene_uid
	set_to_create = _set_to_create


func _ready() -> void:

	# Initiates the scene saver and opens the scene
	await SM_SceneSaver.start()
	var scene_values := SM_SceneSaver.open_scene(scene_uid)

	# Gets the scene preview
	await SM_NodePreviewer.create_preview(self)

	# Registers the slots if needed
	if set_to_create:
		await SM_SlotRegistrator.new(self).register_slots()
		await SM_SceneSaver.save()
		SceneMapIO.save(get_parent())

	node_ready.emit()


func _process(delta : float) -> void:
	if Input.is_key_pressed(KEY_DELETE) and selected and not set_to_delete:
		_delete()
	if Input.is_key_pressed(KEY_CTRL) and selected and not set_to_delete:
		pass


func _delete() -> void:
	set_to_delete = true

	# Initiates the scene saver and opens the scene
	await SM_SceneSaver.start()
	var scene_values := SM_SceneSaver.open_scene(scene_uid)
	
	# Iterates each slot and removes their connections
	for slot in component_slots:
		await slot.delete()

	# Saves all the changes made to the scenes
	await SM_SceneSaver.save()
	#SceneMapIO.save(graph)

	queue_free()


func get_component_slot(index : int) -> SceneMapSlot:
	return component_slots.get(index)