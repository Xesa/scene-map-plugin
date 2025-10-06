@tool
class_name ExampleSceneMapComponent2D extends SceneMapComponent2D
## This is an example class that extends the SceneMapComponent2D with minimum implementation.


## The developer is in charge of defining the logic for this method.
## In this case we will instantiate the next scene and tell it from which node has to spawn the player.
func go_to_next_scene() -> void:

	var next_scene := get_next_scene_instance() # Instantiate the target scene
	var next_component := get_next_component_reference(next_scene) # Gets the target component

	if next_scene is SceneControllerWithCustomPositions:
		next_scene.where_to_spawn = next_component # Sets the entrance node to the instance

	load_scene_into_tree(next_scene) # Changes the current scene to the next one
