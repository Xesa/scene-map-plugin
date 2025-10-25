@tool
extends ConfirmationDialog

const SM_AutoUpdater := preload(SceneMapConstants.AUTO_UPDATER)

@onready var label : Label = $Label

var updating := false


func _ready() -> void:
	toggle_visiblity(false)
	close_requested.connect(_on_close_request)
	canceled.connect(_on_cancel_pressed)
	confirmed.connect(_on_update_pressed)


func toggle_visiblity(toggle : bool) -> void:
	visible = toggle


func _on_close_request() -> void:
	toggle_visiblity(false)


func _on_cancel_pressed() -> void:
	toggle_visiblity(false)


func _on_update_pressed() -> void:
	if !updating:
		label.text = "Updating plugin... This may take a few seconds."
		get_ok_button().disabled = true
		updating = true
		
		var updater := SM_AutoUpdater.new(get_tree())
		print("Updating SceneMap Plugin... This may take a few seconds.")
		updater.download_updates()
