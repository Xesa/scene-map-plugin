@tool
extends Button

var panel : Control


func _ready() -> void:
	panel = owner as Control
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	var dialog = SceneMapAboutDialog.new()
	panel.add_child(dialog)