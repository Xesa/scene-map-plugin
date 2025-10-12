extends MenuButton

const SM_Constants := preload("uid://cjynbj0oq1sx1")
const SM_SlotControl := preload("uid://bxwe2c1at0aom")

var control : SM_SlotControl
var slot : SceneMapSlot
var popup : PopupMenu


func _init(_control : SM_SlotControl, _slot : SceneMapSlot) -> void:
	control = _control
	slot = _slot

	mouse_filter = HBoxContainer.MouseFilter.MOUSE_FILTER_PASS
	icon = load(SM_Constants.TYPE_ICON)
	flat = true
	disabled = true
	tooltip_text = "Change slot's type"

	popup = get_popup()
	popup.add_item("Entrance", 0)
	popup.add_item("Exit", 1)
	popup.add_item("Two-way", 2)
	popup.add_item("Funnel", 3)


func _ready() -> void:
	pressed.connect(_on_button_pressed)
	popup.id_pressed.connect(_on_item_pressed)
	popup.popup_hide.connect(_on_popup_hidden)


func _on_button_pressed() -> void:
	control._on_type_menu_toggled(true)


func _on_popup_hidden() -> void:
	control._on_type_menu_toggled(false)
	control.force_drag_release()


func _on_item_pressed(id : int) -> void:
	var type : SceneMapComponent2D.Type

	match id:
		0: type = SceneMapComponent2D.Type.ENTRY
		1: type = SceneMapComponent2D.Type.EXIT
		2: type = SceneMapComponent2D.Type.TWO_WAY
		3: type = SceneMapComponent2D.Type.FUNNEL

	slot.change_type(type)