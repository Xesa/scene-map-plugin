@tool
class_name SceneMapComponent extends Node2D
## Base component for being used as an interactable Area2D.

const SceneMapComponentFinder := preload("uid://bm5cgkk8r2tb5")

## Defines which actions will the player be able to perform.
@export var type := Type.TWO_WAY

## Defines in which side of the Scene Map will this node appear.
##In the case of choosing the type [code]FUNNEL[/code] the node will appear in both sides but this will define which side is the entrance and which is the exit.
@export var side := Side.RIGHT

@export_group("Plugin information")

## Unique identifier of this component, so the plugin can find even if it changes its path or name. DO NOT MODIFY IN THE INSPECTOR.
@export var component_uid : String

## Reference to the scene connected in the graph. DO NOT MODIFY IN THE INSPECTOR.
@export var next_scene_uid : String

## Reference to the component connected in the graph. DO NOT MODIFY IN THE INSPECTOR.
@export var next_component_uid : String


enum Type {
	ENTRY,		## This node will only work as an entrance. It will allow the player to come to this scene from another one, but it won't be able to go back to the previous scene.
	EXIT,		## This node will only work as an exit. It will allow the player to go the next scene, but once there, it won't be able to come back to this one.
	TWO_WAY,	## This node will work both ways. It will allow the player to go back and forth between two scenes.
	FUNNEL		## This node will accept the entrance of one scene and it will exit to another scene. The player won't be able to go back to the previous scene or get back from the next scene to this one. Ideal for level progressions where the player can only advance but never go back.
	}


enum Side {
	LEFT,	## The node will appear in the left side. In [code]FUNNEL[/code] mode the left side will be the entrance and the right side will be the exit (left-to-right).
	RIGHT,	## The node will appear in the right side. In [code]FUNNEL[/code] mode the left side will be the exit and the right side will be the entrance (right-to-left).
}
	

## Sets the [next_scene_uid] and [next_component_uid] references. These are the values that will be used when calling the [go_to_next_scene] method.
func set_next_scene(scene_uid : String, component_uid : String) -> void:
	next_scene_uid = scene_uid
	next_component_uid = component_uid


## Gets an instance of the scene referenced in [next_scene_uid]. If [next_scene_uid] is empty or [null], this method returns [null].
func get_next_scene_instance() -> Node:
	if next_scene_uid:
		return load("uid://"+next_scene_uid).instantiate()
	return null


## Gets the node referenced by [next_component_uid] by searching it in the parameter [next_scene_instance].
## The value for that parameter can be obtained using the [get_next_scene_instance()] method.
## The instance of the scene used to perform all actions should be always the same.
## If the [next_scene_instance] parameter is [null] or the [next_component_uid] property is empty or [null], this method returns [null].
func get_next_component_reference(next_scene_instance : Node) -> SceneMapComponent:
	if next_scene_instance and next_component_uid != null and next_component_uid != "":
		return SceneMapComponentFinder.search_component_by_uid(next_scene_instance, next_component_uid)
	return null


## Loads the scene instance from the [next_scene_instance] parameter into the tree and frees the current scene.
## The value for that parameter can be obtained using the [get_next_scene_instance()] method.
## The instance of the scene used to perform all actions should be always the same.
## If the [next_scene_instance] parameter is [null] this method does nothing.
func load_scene_into_tree(next_scene_instance : Node) -> void:
	if next_scene_instance:
		get_tree().root.add_child.call_deferred(next_scene_instance)
		get_tree().current_scene.queue_free()
		get_tree().set_deferred("current_scene", next_scene_instance)
	else:
		printerr("Cannot load next scene. Parameter next_scene_instance is null.")


## Abstract method that must be called to change the scene. This method has no logic and it is the final developer who is in charge
## of adding the needed logic to it. The [next_scene_path] and [next_entrance_node] properties hold the references to the scene and component
## that are connected to this one.
func go_to_next_scene() -> void:
	pass
