@tool
class_name ExampleSceneMapArea2D extends SceneMapComponent
## This is an example class that extends the SceneMapComponent for being used with an Area2D.
## In this case, this class will load the target scene when a body enters the area.

@onready var area : Area2D = $Area2D


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(_body : Node2D) -> void:
	go_to_next_scene()


## The developer is in charge of defining the logic for this method.
## In this case we will instantiate the next scene and tell it from which node has to spawn the player.
func go_to_next_scene() -> void:

	var next_scene = load(next_scene_path).instantiate() # Instantiate the target scene

	if next_scene is SceneControllerWithCustomPositions:
		next_scene.where_to_spawn = next_entrance_node # Set the entrance node to the instance

	get_tree().root.add_child.call_deferred(next_scene)
	get_tree().current_scene.queue_free()
	get_tree().set_deferred("current_scene", next_scene)