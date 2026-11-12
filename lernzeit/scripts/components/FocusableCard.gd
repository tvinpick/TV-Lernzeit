class_name FocusableCard
extends Button
## Big subject card on the home screen: card art (text removed) + localized
## title/subtitle rendered by Godot. Focus = blue glow frame + scale 1.05.

var subject_id := ""
var dimmed := false:
	set(v):
		dimmed = v
		_update_dim()

var _art: TextureRect
var _title: FitLabel
var _subtitle: FitLabel
var _badge: Label
var _tween: Tween


static func make(p_subject: String) -> FocusableCard:
	var c := FocusableCard.new()
	c.subject_id = p_subject
	return c


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	flat = true
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(s, empty)
	_art = TextureRect.new()
	_art.texture = load(Curriculum.SUBJECTS[subject_id]["card"])
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	var divider_x := 0.53 if subject_id == "lesen" else 0.465
	_title = _make_label("CardTitle", Curriculum.title_key(subject_id), divider_x, 0.25, 0.53)
	_subtitle = _make_label("CardSubtitle", Curriculum.subtitle_key(subject_id), divider_x, 0.55, 0.72)
	_badge = Label.new()
	_badge.theme_type_variation = &"OnDarkCaption"
	_badge.text = "subject_hidden_badge"
	_badge.anchor_left = divider_x
	_badge.anchor_right = 0.93
	_badge.anchor_top = 0.74
	_badge.anchor_bottom = 0.86
	_badge.visible = false
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_badge)
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	resized.connect(func(): pivot_offset = size / 2.0)
	_update_dim()


func _make_label(variation: String, key: String, x0: float, y0: float, y1: float) -> FitLabel:
	var l := FitLabel.new()
	l.theme_type_variation = variation
	l.text = key
	l.anchor_left = x0
	l.anchor_right = 0.94
	l.anchor_top = y0
	l.anchor_bottom = y1
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _update_dim() -> void:
	if not is_inside_tree():
		return
	_art.modulate = Color(0.55, 0.58, 0.68, 0.85) if dimmed else Color.WHITE
	_title.modulate = Color(1, 1, 1, 0.75) if dimmed else Color.WHITE
	_subtitle.visible = not dimmed
	_badge.visible = dimmed


func _draw() -> void:
	if has_focus():
		var inset := Vector2(size.x * 0.012, size.y * 0.035)
		var r := Rect2(inset, size - inset * 2.0)
		UiTheme.focus_ring(int(size.y * 0.17), 7).draw(get_canvas_item(), r)


func _on_focus(on: bool) -> void:
	queue_redraw()
	if _tween:
		_tween.kill()
	var target := Vector2.ONE * (1.05 if on else 1.0)
	if AppState.animations_enabled():
		_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "scale", target, 0.16)
	else:
		scale = target


func press_feedback() -> void:
	Sfx.play("select" if not dimmed else "error")
	if AppState.animations_enabled():
		var t := create_tween()
		t.tween_property(self, "scale", Vector2.ONE * 0.97, 0.06)
		t.tween_property(self, "scale", Vector2.ONE * 1.05, 0.12)
