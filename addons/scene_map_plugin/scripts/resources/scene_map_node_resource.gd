extends Resource

const SM_SlotResource := preload(SceneMapConstants.SLOT_RESOURCE)
@export var offset : Vector2
@export var scene_name : String
@export var scene_uid : String
@export var component_slots : Array[SM_SlotResource]