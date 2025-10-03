class_name SceneMapAboutDialog extends Window


func _init() -> void:
	size = Vector2i(500, 220)
	initial_position = 2
	transient = true
	unresizable = true
	borderless = true
	popup_window = true


func _ready() -> void:
	close_requested.connect(_on_close_request)
	_add_vbox()


func _on_close_request() -> void:
	queue_free()


func _add_vbox() -> void:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(480, 220)
	vbox.anchors_preset = 8
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -230.0
	vbox.offset_top = -110.0
	vbox.offset_right = 230.0
	vbox.offset_bottom = 110.0
	vbox.anchors_preset = 8
	vbox.grow_horizontal = 2
	vbox.grow_vertical = 2
	vbox.z_index = 1

	add_child(vbox)
	_add_main_text(vbox)
	_add_bottom_text(vbox)


func _add_main_text(vbox : VBoxContainer) -> void:
	var mtext = RichTextLabel.new()
	mtext.custom_minimum_size = Vector2(480, 180)
	mtext.layout_mode = 2
	mtext.vertical_alignment = 1
	mtext.bbcode_enabled = true
	mtext.scroll_active = false
	mtext.add_theme_constant_override("outline_size", 0)
	mtext.add_theme_constant_override("line_separation", 8)
	mtext.add_theme_font_size_override("normal_font_size", 15)
	mtext.add_theme_stylebox_override("normal", StyleBoxEmpty.new())

	var add_icon = SceneMapConstants.ADD_ICON
	mtext.text = "- Use the [img=20%]" + add_icon + "[/img] button to add a new scene to the map.
- Drag and drop the nodes to connect one scene to another.
- Drag a connection to an empty space to disconnect the scenes.
- Press DEL while having one or more scenes selected to remove them from the map."

	vbox.add_child(mtext)


func _add_bottom_text(vbox : VBoxContainer) -> void:
	var btext = RichTextLabel.new()
	btext.custom_minimum_size = Vector2(0, 30)
	btext.layout_mode = 2
	btext.horizontal_alignment = 1
	btext.vertical_alignment = 1
	btext.clip_contents = false
	btext.bbcode_enabled = true
	btext.add_theme_font_size_override("normal_font_size", 11)
	
	var version = SceneMapConstants.VERSION
	var github = SceneMapConstants.GITHUB_LINK
	btext.text = "Version " + version + " | Developed by Guillem Chesa | [url=" + github + "]GitHub[/url]"

	vbox.add_child(btext)