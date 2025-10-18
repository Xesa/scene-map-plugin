extends FileDialog

signal scene_selected(scene : Resource)


func _init() -> void:
	title = "Select a scene to add"
	ok_button_text = "Add scene"
	
	access = FileDialog.ACCESS_RESOURCES
	file_mode = FileDialog.FILE_MODE_OPEN_FILE
	filters = PackedStringArray(["*.tscn"])

	visible = true
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS


func _ready() -> void:
	file_selected.connect(_on_file_selected)


func _on_file_selected(path : String) -> void:
	if path == "" or not FileAccess.file_exists(path):
		return

	scene_selected.emit(path)