extends Resource

const SM_Enums := preload("uid://cukwm8rnmlicq")

@export var slot_id : String
@export var index : int

@export var left : bool
@export var right : bool
@export var left_icon : String
@export var right_icon : String

@export var scene_uid : String
@export var component_uid : String
@export var component_name : String
@export var component_name_is_custom : bool

@export var type : SM_Enums.Type
@export var side : SM_Enums.Side

@export var connected_to_ids : Array[String]
@export var connected_from_ids : Array[String]