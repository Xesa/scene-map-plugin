class_name Player extends CharacterBody2D


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _process(_delta : float) -> void:
	
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2(0,0):
		sprite.play("running")
		self.velocity = direction * 300
		
		if direction.x < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
			
	else:
		self.velocity = Vector2(0,0)
		sprite.play("idle")
		
	move_and_slide()