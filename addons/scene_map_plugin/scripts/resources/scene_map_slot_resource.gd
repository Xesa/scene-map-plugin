extends Resource

@export var slot_id : String
@export var index : int
@export var specific_index : int

@export var left : bool
@export var right : bool
@export var left_icon : String
@export var right_icon : String

@export var scene_uid : String
@export var component_uid : String

@export var type : SceneMapComponent.Type
@export var side : SceneMapComponent.Side
@export var type_string : String

@export var connected_to_ids : Array[String]
@export var connected_from_ids : Array[String]