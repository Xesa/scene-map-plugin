extends Node
## SM_Enums
##
## Defines all the enums for the Scene Map.

## Defines which actions will the player be able to perform.
enum Type {
	ENTRY,		## This node will only work as an entrance. It will allow the player to come to this scene from another one, but it won't be able to go back to the previous scene.
	EXIT,		## This node will only work as an exit. It will allow the player to go the next scene, but once there, it won't be able to come back to this one.
	TWO_WAY,	## This node will work both ways. It will allow the player to go back and forth between two scenes.
	FUNNEL		## This node will accept the entrance of one scene and it will exit to another scene. The player won't be able to go back to the previous scene or get back from the next scene to this one. Ideal for level progressions where the player can only advance but never go back.
	}


## Defines in which side of the Scene Map will this node appear.
## In the case of choosing the type [code]FUNNEL[/code] the node will appear
## in both sides but this will define which side is the entrance and which is the exit.
enum Side {
	LEFT,	## The node will appear in the left side. In [code]FUNNEL[/code] mode the left side will be the entrance and the right side will be the exit (left-to-right).
	RIGHT,	## The node will appear in the right side. In [code]FUNNEL[/code] mode the left side will be the exit and the right side will be the entrance (right-to-left).
}