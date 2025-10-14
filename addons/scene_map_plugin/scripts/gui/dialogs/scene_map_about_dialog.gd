@tool
extends PopupPanel

const SM_Constants := preload("uid://cjynbj0oq1sx1")

@onready var main_text : RichTextLabel = $'VBoxContainer/MainText'
@onready var bottom_text : RichTextLabel = $'VBoxContainer/BottomText'


func _ready() -> void:
	toggle_visiblity(false)
	var version = SM_Constants.VERSION
	var github = SM_Constants.GITHUB_LINK
	bottom_text.text = "Version " + version + " | Developed by Guillem Chesa | [url=" + github + "]GitHub[/url]"

	close_requested.connect(_on_close_request)
	bottom_text.meta_clicked.connect(_on_url_clicked)


func toggle_visiblity(toggle : bool) -> void:
	visible = toggle


func _on_close_request() -> void:
	toggle_visiblity(false)


func _on_url_clicked(meta : Variant) -> void:
	OS.shell_open(meta)