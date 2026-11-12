class_name ConfirmDialog
extends Control
## Modal confirmation. Default focus is always the safe option (cancel).
## Back closes the dialog like "cancel". Focus is trapped inside.

signal confirmed
signal cancelled

var title_text := ""
var message_text := ""
var confirm_key := "yes"
var cancel_key := "cancel"
var confirm_variant := "blue"
var cancel_button: PillButton
var confirm_button: PillButton
var _return_focus: Control


static func make(p_title: String, p_message: String, p_confirm_key: String, p_variant: String = "blue",
		p_cancel_key: String = "cancel") -> ConfirmDialog:
	var d := ConfirmDialog.new()
	d.title_text = p_title
	d.message_text = p_message
	d.confirm_key = p_confirm_key
	d.confirm_variant = p_variant
	d.cancel_key = p_cancel_key
	return d


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
	panel.custom_minimum_size = Vector2(980, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 26)
	panel.add_child(v)
	var t := Label.new()
	t.theme_type_variation = &"HeadingLabel"
	t.text = title_text
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	if message_text != "":
		var m := Label.new()
		m.theme_type_variation = &"BodyLabel"
		m.text = message_text
		m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		m.custom_minimum_size.x = 820
		v.add_child(m)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 40)
	v.add_child(h)
	cancel_button = PillButton.make(cancel_key, "light", preload("res://assets/icons/Settings_Icon_Cancel.png"))
	cancel_button.custom_minimum_size.x = 340
	cancel_button.sound = "back"
	h.add_child(cancel_button)
	confirm_button = PillButton.make(confirm_key, confirm_variant, null)
	confirm_button.custom_minimum_size.x = 340
	h.add_child(confirm_button)
	FocusManager.set_neighbors(cancel_button, null, confirm_button)
	FocusManager.set_neighbors(confirm_button, cancel_button, null)
	cancel_button.pressed.connect(cancel)
	confirm_button.pressed.connect(_on_confirm)
	_return_focus = get_viewport().gui_get_focus_owner()
	cancel_button.grab_focus.call_deferred()
	if AppState.animations_enabled():
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.15)


func cancel() -> void:
	cancelled.emit()
	_close()


func _on_confirm() -> void:
	confirmed.emit()
	_close()


func _close() -> void:
	queue_free()   # mark first, so focus guards ignore this closing dialog
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()


## Keeps focus inside the dialog even if something tries to move it out.
func ensure_focus() -> void:
	if is_queued_for_deletion():
		return
	var f := get_viewport().gui_get_focus_owner()
	if f == null or not is_ancestor_of(f):
		cancel_button.grab_focus()
