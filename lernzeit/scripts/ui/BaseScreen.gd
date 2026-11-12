class_name BaseScreen
extends Control
## Base class for all screens managed by Main (navigation stack).

const SAFE_X := 96    # ~5 % safe area for TV overscan
const SAFE_Y := 54

var main: Node          ## Main router
var params := {}


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Control focused when the screen is opened (or when focus would be lost).
func get_default_focus() -> Control:
	return null


## Return true when the screen handled Back itself (e.g. closes an inner column).
func handle_back() -> bool:
	return false


## Called when the screen becomes visible again after a pop.
func on_shown() -> void:
	pass


func add_background(path: String) -> TextureRect:
	var bg := TextureRect.new()
	bg.texture = load(path)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	return bg


## Screen title with optional icon, centered at the top of the safe area.
func add_title(key: String, icon_path: String = "", y: float = SAFE_Y + 6) -> Label:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 22)
	h.position = Vector2(SAFE_X, y)
	h.size = Vector2(1920 - SAFE_X * 2, 100)
	add_child(h)
	if icon_path != "":
		var ic := TextureRect.new()
		ic.texture = load(icon_path)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(92, 92)
		h.add_child(ic)
	var l := Label.new()
	l.theme_type_variation = &"TitleLabel"
	l.text = key
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	return l


## Bottom button bar inside the safe area: left group, spacer, right group.
func add_bottom_bar(left: Array, right: Array) -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 30)
	bar.position = Vector2(SAFE_X, 1080 - SAFE_Y - 104)
	bar.size = Vector2(1920 - SAFE_X * 2, 100)
	add_child(bar)
	for c in left:
		bar.add_child(c)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(spacer)
	for c in right:
		bar.add_child(c)
	return bar


## Scrolls so that the complete row (not only the focused button inside it)
## is visible; the first/last row scroll fully to the top/bottom.
func keep_rows_visible(scroll: ScrollContainer, rows_box: Container) -> void:
	scroll.follow_focus = false
	get_viewport().gui_focus_changed.connect(func(c: Control):
		if c == null or not is_instance_valid(scroll) or not rows_box.is_ancestor_of(c):
			return
		var row: Control = c
		while row.get_parent() != rows_box:
			row = row.get_parent()
		_scroll_to_row.call_deferred(scroll, rows_box, row))


func _scroll_to_row(scroll: ScrollContainer, rows_box: Container, row: Control) -> void:
	if not is_instance_valid(row):
		return
	var rows := rows_box.get_children()
	var bar := scroll.get_v_scroll_bar()
	if row == rows.front():
		scroll.scroll_vertical = 0
	elif row == rows.back():
		scroll.scroll_vertical = int(bar.max_value)
	else:
		var top := row.position.y
		var bottom := top + row.size.y
		var view := scroll.size.y
		if top < scroll.scroll_vertical:
			scroll.scroll_vertical = int(top)
		elif bottom > scroll.scroll_vertical + view:
			scroll.scroll_vertical = int(bottom - view)


func toast(text: String) -> void:
	if main:
		main.toast(text)
