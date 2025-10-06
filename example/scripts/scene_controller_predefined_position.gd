class_name SceneControllerWithPredefinedPosition extends Node2D
## This is an example of a scene controller that will have a predefined position for spawning the player.
## The goal is to teleport the player always to the same position.
##
## A typical use case would be when the player enters a door that goes to a scene with only one entrance
## so the script doesn't needs define the target position on run time.

@export var spawn_position : Vector2

@onready var player : Player = $Player


func _ready() -> void:
	player.global_position = spawn_position