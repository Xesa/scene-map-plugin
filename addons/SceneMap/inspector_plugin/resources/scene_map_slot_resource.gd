class_name SceneMapSlotResource extends Resource

@export var slot_id : String
@export var index : int
@export var specific_index : int

@export var left : bool
@export var right : bool

@export var scene_path : String
@export var component_path : NodePath

@export var type : SceneMapComponent.Type
@export var side : SceneMapComponent.Side
@export var type_string : String

@export var connected_to_ids : Array[String]
@export var connected_from_ids : Array[String]