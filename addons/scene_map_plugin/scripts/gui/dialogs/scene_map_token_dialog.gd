@tool
extends ConfirmationDialog

const SM_AutoUpdater := preload(SceneMapConstants.AUTO_UPDATER)

@onready var line_edit : LineEdit = $VBoxContainer/LineEdit
@onready var checkbox : CheckBox = $VBoxContainer/CheckBox
@onready var checkbox_message : Label = $VBoxContainer/CheckboxMessage
@onready var token_message : Label = $VBoxContainer/TokenMessage


func _ready() -> void:
	toggle_visiblity(false)
	close_requested.connect(_on_close_request)
	canceled.connect(_on_cancel_pressed)
	confirmed.connect(_on_accept_pressed)
	checkbox.pressed.connect(_on_checkbox_pressed)


func toggle_visiblity(toggle : bool) -> void:
	visible = toggle
	line_edit.text = ""
	checkbox.button_pressed = false
	checkbox_message.visible = false
	token_message.visible = false


func _on_close_request() -> void:
	toggle_visiblity(false)


func _on_cancel_pressed() -> void:
	save_config("ask_for_token", !checkbox.button_pressed)
	toggle_visiblity(false)


func _on_checkbox_pressed() -> void:
	checkbox_message.visible = checkbox.button_pressed
	token_message.visible = false


func _on_token_failed() -> void:
	toggle_visiblity(true)
	token_message.visible = true


func _on_accept_pressed() -> void:
	var updater := SM_AutoUpdater.new(get_tree())
	var is_token_valid := await updater.check_token_validity(line_edit.text)
	await Engine.get_main_loop().process_frame

	if !is_token_valid:
		_on_token_failed()

	else:
		updater.save_token(line_edit.text)
		updater.check_for_updates()


func save_config(key : String, value : Variant) -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(SceneMapConstants.CONFIG_PATH)

	if err == OK:
		cfg.set_value("plugin", key, value)
		cfg.save(SceneMapConstants.CONFIG_PATH)