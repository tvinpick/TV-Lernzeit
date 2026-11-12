class_name ArtButton
extends Button
## Button that uses an approved button artwork (label removed) as background
## and renders the localized title (and optional second line) with Godot.

var art: Texture2D
var title_key := ""
var subtitle_key := ""
var text_from := 0.3          ## label area starts at this fraction of the width
var light_art := true         ## dark text on light art, white text on dark art
var _title: FitLabel
var _sub: FitLabel
var _tween: Tween


static func make(p_art: Texture2D, p_title: String, p_text_from: float, p_light: bool, p_sub: String = "") -> ArtButton:
	var b := ArtButton.new()
	b.art = p_art
	b.title_key = p_title
	b.text_from = p_text_from
	b.light_art = p_light
	b.subtitle_key = p_sub
	return b


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	flat = true
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(s, empty)
	var tr := TextureRect.new()
	tr.texture = art
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	var variation := &"RowTitle" if light_art else &"OnDarkBody"
	_title = _label(variation, title_key, 0.18 if subtitle_key == "" else 0.14, 0.82 if subtitle_key == "" else 0.56)
	if not light_art:
		_title.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
		_title.add_theme_font_size_override("font_size", 34)
	if subtitle_key != "":
		_sub = _label(&"CaptionLabel" if light_art else &"OnDarkCaption", subtitle_key, 0.54, 0.86)
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	resized.connect(func(): pivot_offset = size / 2.0)


func _label(variation: StringName, key: String, y0: float, y1: float) -> FitLabel:
	var l := FitLabel.new()
	l.theme_type_variation = variation
	l.text = key
	l.anchor_left = text_from
	l.anchor_right = 0.93
	l.anchor_top = y0
	l.anchor_bottom = y1
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _draw() -> void:
	if has_focus():
		var inset := Vector2(size.x * 0.02, size.y * 0.08)
		UiTheme.focus_ring(int(size.y * 0.4)).draw(get_canvas_item(), Rect2(inset, size - inset * 2.0))


func _on_focus(on: bool) -> void:
	queue_redraw()
	if _tween:
		_tween.kill()
	var target := Vector2.ONE * (1.05 if on else 1.0)
	if AppState.animations_enabled():
		_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "scale", target, 0.14)
	else:
		scale = target
