@tool
class_name SceneMapComponentMarker2D extends Marker2D
## A simple Marker2D sub-component that provides the [SceneMapComponent2D] of a visual marker that is only visible in the editor.
##
## The position of this sub-component overrides the value returned by the [method get_component_position] method from the component.
## This is especially useful when you don't want the center of the component to be the expected position.

const SUB_COMPONENT_NAME := &"SceneMapComponentMarker2D"

var parent : SceneMapComponent2D


func connect_to_scene_map_component(component : SceneMapComponent2D) -> void:
	parent = component
