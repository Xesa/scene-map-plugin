@tool
extends Button

const SM_AboutDialog := preload("uid://dk3jlts3isimm")

var panel : Control
var about_dialog : SM_AboutDialog


func _ready() -> void:
	panel = owner as Control
	about_dialog = panel.get_node("SceneMapAboutDialog")
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	about_dialog.toggle_visiblity(true)