@tool
class_name SceneMapComponent extends Node2D
## Base component for being used as an interactable Area2D.

## Defines which actions will the player be able to perform.
@export var type := Type.TWO_WAY

## Defines in which side of the Scene Map will this node appear.
##In the case of choosing the type [code]FUNNEL[/code] the node will appear in both sides but this will define which side is the entry and which is the exit.
@export var side := Side.RIGHT

@export_group("Plugin information")

## Unique identifier of this component, so the plugin can find even if it changes its path or name. DO NOT MODIFY IN THE INSPECTOR.
@export var component_uid : String

## Reference to the scene connected in the graph. DO NOT MODIFY IN THE INSPECTOR.
@export var next_scene_path : String

## Reference to the component connected in the graph. DO NOT MODIFY IN THE INSPECTOR.
@export var next_entrance_node : String


enum Type {
	ENTRY,		## This node will only work as an entrance. It will allow the player to come to this scene from another one, but it won't be able to go back to the previous scene.
	EXIT,		## This node will only work as an exit. It will allow the player to go the next scene, but once there, it won't be able to come back to this one.
	TWO_WAY,	## This node will work both ways. It will allow the player to go back and forth between two scenes.
	FUNNEL		## This node will accept the entrance of one scene and it will exit to another scene. The player won't be able to go back to the previous scene or get back from the next scene to this one. Ideal for level progressions where the player can only advance but never go back.
	}


enum Side {
	LEFT,	## The node will appear in the left side.
	RIGHT,	## The node will appear in the right side.
}

signal path_renamed(path : NodePath)
	

## Sets the [next_scene_path] and [next_entrance_node] paths. These are the values that will be used when calling the [go_to_next_scene] method.
func set_next_scene(scene_path : String, entrance_node : String) -> void:
	next_scene_path = scene_path
	next_entrance_node = entrance_node


## Abstract method that must be called to change the scene. This method has no logic and it is the final developer who is in charge
## of adding the needed logic to it. The [next_scene_path] and [next_entrance_node] properties hold the references to the scene and component
## that are connected to this one.
func go_to_next_scene() -> void:
	pass