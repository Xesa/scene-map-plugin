@tool
class_name SceneMapComponent2D extends Node2D
## Abstract 2D component for being used with the SceneMap plugin.[br]
##
## This class allows the SceneMap plugin to detect where are the entrances and exits of a scene.
## Set the [code]type[/code] and [code]side[/code] properties in the inspector and when the scene
## is added to the SceneMap graph, this will appear as a slot that can connect to other components.[br][br]
## In order to use it, the developer must create a class that extends this class and override the
## [code]go_to_next_scene()[/code] method (there is a simple example in the method's description).[br][br]
## A node that inherits from this class can be populated with different sub-components,
## which will provide the node with new functionalities and properties. See the [code]sub_components[/code]
## property's description for more information.[br]
## If custom logic needs to be added to the [code]_ready()[/code] method, you must call its parent class method
## by using the [code]super[/code] keyword at the beginning of the method.

const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")
const SM_ResourceTools := preload("uid://b71h2bnocse6c")

## Defines a custom name for this component in the Scene Map. If this property is left empty the name of the node will appear instead.
@export var custom_name : String

## Defines which actions will the player be able to perform.
@export var type := Type.TWO_WAY

## Defines in which side of the Scene Map will this node appear.
## In the case of choosing the type [code]FUNNEL[/code] the node will appear
## in both sides but this will define which side is the entrance and which is the exit.
@export var side := Side.RIGHT

## Holds the resource for the next scene. This will normally be loaded when the component is ready
## but it can be forced to load again with the [get_next_scene_resource()] method.
## To instantiate the scene see the [get_next_scene_instance()] method.
@onready var next_scene_resource : PackedScene = get_next_scene_resource()

## Dictionary with references to the sub-components that this component has. Sub-components provide a [SceneMapComponent2D]
## of different functionalities such as having a position or detecting other areas and bodies.[br]
## There are several pre-made sub-components ready to use for the most common use cases, but the developer is able to extend them or create new ones.[br]
## The keys of the dictionary are the class name of the sub-components. Here's a list of the sub-component types ready to use:[br]
## - [SceneMapComponentNode2D]: Provides of a position in a 2D space. Ideal to set a spawn position when loading the next scene.[br]
## - [SceneMapComponentArea2D]: Triggers the [go_to_next_scene()] method when a body enters[br]
@onready var sub_components : Dictionary = connect_sub_components()

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

func _ready() -> void:
	if Engine.is_editor_hint():
		_generate_component_uid.call_deferred()


func set_component_type(_type : Type) -> void:
	type = _type


func set_component_side(_side : SceneMapComponent2D.Side) -> void:
	side = _side


func set_custom_name(_custom_name : String) -> void:
	custom_name = _custom_name


func remove_custom_name() -> void:
	custom_name = ""


## Sets the [component_uid] value in the component's metadata.
## [b]This method is reserved for the plugin and shouldn't be called anywhere else.[/b]
func _set_component_uid() -> void:
	var component_uid = str(ResourceUID.create_id())
	set_meta(&"_component_uid", component_uid)


## Sets the [next_scene_uid] and [next_component_uid] references in the component's metadata.[br]
## [b]This method is reserved for the plugin and shouldn't be called anywhere else.[/b]
func _set_next_scene(scene_uid : String, component_uid : String) -> void:
	set_meta(&"_next_scene_uid", scene_uid)
	set_meta(&"_next_component_uid", component_uid)


## Removes the [component_uid] value in the component's metadata.
## [b]This method is reserved for the plugin and shouldn't be called anywhere else.[/b]
func _remove_component_uid() -> void:
	remove_meta(&"_component_uid")


## Removes the [next_scene_uid] and [next_component_uid] references in the component's metadata.[br]
## [b]This method is reserved for the plugin and shouldn't be called anywhere else.[/b]
func _remove_next_scene() -> void:
	remove_meta(&"_next_scene_uid")
	remove_meta(&"_next_component_uid")


## Returns the [component_uid] value from this component's metadata. If the value is [null] an error is generated.
func get_component_uid() -> Variant:
	return get_meta(&"_component_uid")


## Returns the [component_uid] value from this component's metadata. If the value is [null] no errors will be generated.
func get_component_uid_or_null() -> Variant:
	if has_meta(&"_component_uid"):
		return get_meta(&"_component_uid")
	return null


## Returns the [next_scene_uid] value from this component's metadata. If the value is [null] an error is generated.
func get_next_scene_uid() -> Variant:
	return get_meta(&"_next_scene_uid")


## Returns the [next_component_uid] value from this component's metadata. If the value is [null] an error is generated.
func get_next_component_uid() -> Variant:
	return get_meta(&"_next_component_uid")


func get_component_type() -> Type:
	return type


func get_component_side() -> SceneMapComponent2D.Side:
	return side


func get_custom_name() -> String:
	return custom_name


func _generate_component_uid() -> void:
	if get_component_uid_or_null() == null:
		_set_component_uid()
		EditorInterface.mark_scene_as_unsaved()
	
	var components := SM_ComponentFinder.find_all_components(get_root_node())

	for component in components:
		if component == self or component.get_component_uid_or_null() == null:
			continue
		
		if component.get_component_uid_or_null() == get_component_uid_or_null():
			_set_component_uid()
			EditorInterface.mark_scene_as_unsaved()
			return


func get_root_node() -> Node:
	var node = self
	while node.owner != null:
		node = node.owner
	return node

	
## Loads the next scene and sets it to the [next_scene_resource] property.
## If the scene is already loaded it will return the [next_scene_resource] property without loading it again.[br]
## If [next_scene_uid] is empty or the scene doesn't exist returns [null] and generates an error.[br]
## To instantiate the scene see the [get_next_scene_instance()] method.
func get_next_scene_resource() -> PackedScene:
	if next_scene_resource == null and not Engine.is_editor_hint():
		var next_scene_uid = get_next_scene_uid()
		if next_scene_uid:
			next_scene_resource = SM_ResourceTools.load_from_uid(next_scene_uid)
			return next_scene_resource
		return null
	return next_scene_resource


## Gets an instance of the scene referenced in [next_scene_uid].[br]
## If that property is empty or null, this method returns [null] and generates an error.[br]
## To load the scene's resource see the [get_next_scene_resource()] method.
func get_next_scene_instance() -> Node:
	var next_scene_resource = get_next_scene_resource()
	if next_scene_resource != null:
		return next_scene_resource.instantiate()
	return null


## Gets the node referenced by [next_component_uid] by searching it in the scene passed through the parameter [next_scene_instance].
## The value for that parameter can be obtained using the [get_next_scene_instance()] method.[br]
## The instance of the scene used to perform all actions should be always the same.[br]
## If the [next_scene_instance] parameter is null or the [next_component_uid] property is empty or null, this method returns [null].
func get_next_component_reference(next_scene_instance : Node) -> SceneMapComponent2D:
	var next_component_uid = get_next_component_uid()
	if next_scene_instance and next_component_uid != null and next_component_uid != "":
		return SM_ComponentFinder.search_component_by_uid(next_scene_instance, next_component_uid)
	push_error("Cannot get next component's reference. Parameter next_scene_instance is null.")
	return null


## Loads the scene instance from the [next_scene_instance] parameter into the tree and frees the current scene.
## The value for that parameter can be obtained using the [get_next_scene_instance()] method.[br]
## The instance of the scene used to perform all actions should be always the same.[br]
## If the [next_scene_instance] parameter is null this method does nothing.
func load_scene_into_tree(next_scene_instance : Node) -> void:
	if next_scene_instance:
		get_tree().root.add_child.call_deferred(next_scene_instance)
		get_tree().current_scene.queue_free()
		get_tree().set_deferred("current_scene", next_scene_instance)
	else:
		push_error("Cannot load next scene. Parameter next_scene_instance is null.")


## Iterates through each child node and connects it if it's a valid sub-component.
## Valid sub-components must include the [connect_to_scene_map_component()] method and [SUB_COMPONENT_NAME] constant property.[br]
## See the [sub_components] property for more information.
func connect_sub_components() -> Dictionary:
	if not Engine.is_editor_hint():
		var sub_components := {}
		for child in get_children():
			if child.has_method("connect_to_scene_map_component") and child.get("SUB_COMPONENT_NAME"):
				child.connect_to_scene_map_component(self)
				sub_components[child.SUB_COMPONENT_NAME] = child
		return sub_components
	return {}


## Returns the global position of the component. If there is a [SceneMapComponentMarker2D] attached to it,
## this method will return the marker's position instead.
func get_component_position() -> Vector2:
	if sub_components.has(&"SceneMapComponentMarker2D"):
		return sub_components[&"SceneMapComponentMarker2D"].global_position
	return global_position


## Abstract method that must be called to change the scene. This method has no logic and it is the final developer who is in charge
## of adding the needed logic by overriding it. This class provides helper methods to instantiate the next scene, get a reference to the next
## [SceneMapComponent2D] and load the scene into the tree.[br]
## This is an example of the most basic implementation:
## [codeblock]
## func go_to_next_scene() -> void:
##		var next_scene_instance := get_next_scene_instance()
##		var next_component := get_next_component_reference(scene_instance)
##		scene_instance.spawn_node = next_component # Tells the next scene where should spawn the player
##		load_scene_into_tree(scene_instance)
## [/codeblock]
func go_to_next_scene() -> void:
	pass


