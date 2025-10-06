class_name SceneMapComponentArea2D extends Area2D
## A simple Area2D sub-component that triggers the [method go_to_next_scene] method from a [SceneMapComponent2D].
##
## When this sub-component is ready it connects automatically to its parent [SceneMapComponent2D] and
## whenever a body enters the area, it triggers the [go_to_next_scene()] method.

const SUB_COMPONENT_NAME := &"SceneMapComponentArea2D"

var parent : SceneMapComponent2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var monitoring_value = monitoring
	var monitorable_value = monitorable
	monitoring = false
	monitorable = false
	set_deferred("monitoring", monitoring_value)
	set_deferred("monitorable", monitorable_value)


func connect_to_scene_map_component(component : SceneMapComponent2D) -> void:
	parent = component


func _on_body_entered(body : Node2D) -> void:
	parent.go_to_next_scene()