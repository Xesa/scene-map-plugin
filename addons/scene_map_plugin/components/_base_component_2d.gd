@tool
class_name SceneMapComponent2D extends Node2D
## Abstract 2D component for being used with the SceneMap plugin.[br]
##
## This class allows the SceneMap plugin to detect where are the entrances and exits of a scene.
## In order to use it, the developer must create a class that extends this class and override the
## [code]go_to_next_scene()[/code] method (there is a simple example in the method's description).[br][br]
## A node that inherits from this class can be populated with different sub-components,
## which will provide the node with new functionalities and properties. See the [code]sub_components[/code]
## property's description for more information.[br]
## If custom logic needs to be added to the [code]_ready()[/code] method, you must call its parent class method
## by using the [code]super[/code] keyword at the beginning of the method.

const SM_ComponentFinder := preload("uid://bm5cgkk8r2tb5")
const SM_ResourceTools := preload("uid://b71h2bnocse6c")
const SM_Enums := preload("uid://cukwm8rnmlicq")

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


func _ready() -> void:
	if Engine.is_editor_hint():
		get_component_type()
		get_component_side()
		_generate_component_uid.call_deferred()


#region SetterMethods

## Generates a unique identifier for this component that will be stored in the [component_uid] metadata value.
## If this component already has an identifier but it is the same one as any other component in the scene, it will generate a new one.[br]
## To get this component's UID use the [get_component_uid()] method or [get_component_uid_or_null()] if no errors should be generated.[br]
## [b]This method is for exclusive use of the SceneMap plugin and shouldn't be used anywhere else.[/b]
func _generate_component_uid() -> void:
	if get_component_uid_or_null() == null:
		_set_component_uid()
		EditorInterface.mark_scene_as_unsaved()
	
	var components := SM_ComponentFinder.find_all_components(SM_ComponentFinder.get_root_node(self))

	for component in components:
		if component == self or component.get_component_uid_or_null() == null:
			continue
		
		if component.get_component_uid() == get_component_uid():
			_set_component_uid()
			EditorInterface.mark_scene_as_unsaved()
			return


## Sets the component's type, which defines what actions can be performed through this component.[br]
## [b]This method is for exclusive use of the SceneMap plugin and shouldn't be used anywhere else.[/b]
func _set_component_type(type : SM_Enums.Type) -> void:
	set_meta(&"_component_type", type)


## Sets the component's side, which defines in which side of the graph node will this component appear.[br]
## [b]This method is for exclusive use of the SceneMap plugin and shouldn't be used anywhere else.[/b]
func _set_component_side(side : SM_Enums.Side) -> void:
	set_meta(&"_component_side", side)


## Sets a custom name that will be shown in the scene map instead of the actual name of the component in the scene.[br]
## [b]This method is for exclusive use of the SceneMap plugin and shouldn't be used anywhere else.[/b]
func _set_custom_name(custom_name : String) -> void:
	set_meta(&"_component_custom_name", custom_name)


## Sets the [component_uid] value in the component's metadata.
## [b]This method is for exclusive use of the SceneMap plugin and shouldn't be used anywhere else.[/b]
func _set_component_uid() -> void:
	var component_uid = str(ResourceUID.create_id())
	set_meta(&"_component_uid", component_uid)


## Sets the [next_scene_uid] and [next_component_uid] references in the component's metadata.[br]
## [b]This method is for exclusive use of the SceneMap plugin and shouldn't be used anywhere else.[/b]
func _set_next_scene(scene_uid : String, component_uid : String) -> void:
	set_meta(&"_next_scene_uid", scene_uid)
	set_meta(&"_next_component_uid", component_uid)

#endregion

#region RemoverMethods

## Removes the [component_uid] value in the component's metadata.
## [b]This method is for exclusive use of the SceneMap plugin and shouldn't be used anywhere else.[/b]
func _remove_component_uid() -> void:
	remove_meta(&"_component_uid")


## Removes the [next_scene_uid] and [next_component_uid] references in the component's metadata.[br]
## [b]This method is for exclusive use of the SceneMap plugin and shouldn't be used anywhere else.[/b]
func _remove_next_scene() -> void:
	remove_meta(&"_next_scene_uid")
	remove_meta(&"_next_component_uid")


## Removes the custom name.[br]
## [b]This method is for exclusive use of the SceneMap plugin and shouldn't be used anywhere else.[/b]
func _remove_custom_name() -> void:
	if has_meta(&"_component_custom_name"):
		remove_meta(&"_component_custom_name")

#endregion

#region GetterMethods

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


## Returns the [component_type] value from this component's metadata. If no value is assigned, it will set the [TWO_WAY] type by default.
func get_component_type() -> SM_Enums.Type:
	if !has_meta(&"_component_type"):
		_set_component_type(SM_Enums.Type.TWO_WAY)
	return get_meta(&"_component_type")


## Returns the [component_side] value from this component's metadata. If no value is assigned, it will set the [LEFT] side by default.
func get_component_side() -> SM_Enums.Side:
	if !has_meta(&"_component_side"):
		_set_component_side(SM_Enums.Side.LEFT)
	return get_meta(&"_component_side")


## Returns the [component_custom_name] value from this component's metadata. If no value is assigned, it will return the component's
## actual name in the scene, converted into a readable string.
func get_custom_name() -> String:
	if !has_meta(&"_component_custom_name") or get_meta(&"_component_custom_name") == "":
		return SM_ResourceTools.convert_string_to_readable_name(name)
	return get_meta(&"_component_custom_name")


## Returns [true] if there is a [component_custom_name] value assigned in this component's metadata.
func has_custom_name() -> bool:
	return has_meta(&"_component_custom_name") and get_meta(&"_component_custom_name") != ""

#endregion

#region EndUserMethods

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

#endregion

