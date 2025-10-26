@tool
class_name SceneMapComponentMarker3D extends Marker3D
## A simple Marker3D sub-component that provides the [SceneMapComponent3D] of a visual marker that is only visible in the editor.
##
## The position of this sub-component overrides the value returned by the [method get_component_position] method from the component.
## This is especially useful when you don't want the center of the component to be the expected position.

const SUB_COMPONENT_NAME := &"SceneMapComponentMarker3D"

var parent : SceneMapComponent3D


func connect_to_scene_map_component(component : SceneMapComponent3D) -> void:
	parent = component
