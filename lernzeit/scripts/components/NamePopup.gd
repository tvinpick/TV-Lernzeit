class_name NamePopup
extends Control
## Small modal editor for the optional child name / nickname.
## On Android TV the system on-screen keyboard opens when OK is pressed on the field.

signal submitted(name: String)

var initial := ""
var field: LineEdit
var _buttons: Array[PillButton] = []
var _return_focus: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.06, 0.2, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel("main", 70))
	panel.custom_minimum_size = Vector2(1060, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 24)
	panel.add_child(v)
	var t := Label.new()
	t.theme_type_variation = &"HeadingLabel"
	t.text = "p_name_title"
	v.add_child(t)
	field = LineEdit.new()
	field.text = initial
	field.placeholder_text = "p_name_placeholder"
	field.max_length = SettingsRepository.MAX_NAME_LENGTH
	field.custom_minimum_size = Vector2(0, 92)
	field.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	field.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	field.text_submitted.connect(func(_t): _buttons[2].grab_focus())
	v.add_child(field)
	var hint := Label.new()
	hint.theme_type_variation = &"CaptionLabel"
	hint.text = "p_name_hint"
	v.add_child(hint)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 26)
	v.add_child(h)
	var remove := PillButton.make("p_name_remove", "light", null, true)
	var cancel := PillButton.make("cancel", "light", preload("res://assets/icons/Settings_Icon_Cancel.png"), true)
	var ok := PillButton.make("apply", "blue", null, true)
	for b in [remove, cancel, ok]:
		b.custom_minimum_size.x = 280
		h.add_child(b)
		_buttons.append(b)
	remove.pressed.connect(func(): _finish(""))
	cancel.pressed.connect(close_popup)
	ok.pressed.connect(func(): _finish(field.text))
	FocusManager.set_neighbors(field, null, null, null, ok)
	FocusManager.link_row(_buttons)
	FocusManager.point_all(_buttons, SIDE_TOP, field)
	FocusManager.point_all(_buttons, SIDE_BOTTOM, null)
	for b in _buttons:
		FocusManager.set_one(b, SIDE_BOTTOM, b)
	_return_focus = get_viewport().gui_get_focus_owner()
	field.grab_focus.call_deferred()


func _finish(n: String) -> void:
	submitted.emit(n.strip_edges())
	close_popup()


func close_popup() -> void:
	queue_free()
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()
