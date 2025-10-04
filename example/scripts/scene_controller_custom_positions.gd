class_name SceneControllerWithCustomPositions extends Node2D
## This is an example of a scene controller that will accept a target node for the spawning position.
## The goal is to be able to teleport the player to the position of the target node when the scene is loaded.
##
## A typical use case would be when the player enters a door that goes to a scene with several entrances
## and we need to define to which of those entrances has to be teleported.

@export var default_spawn_node : SceneMapComponent

@onready var player : Player = $Player

var where_to_spawn : SceneMapComponent


func _ready() -> void:
	if not where_to_spawn:
		player.global_position = default_spawn_node.global_position
	
	else:
		player.global_position = where_to_spawn.global_position
