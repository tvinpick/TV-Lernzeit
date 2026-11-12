class_name AnswerButton
extends Button
## Big answer button from the math kit (Answer_*.png) with a live number label,
## or a card with a group of N objects (picture mode). States: normal, focused
## (glow + scale), wrong (dimmed + cross, disabled), correct (green check).

const TEXTURES := {
	"yellow": preload("res://assets/math/shared_ui/Answer_Yellow.png"),
	"blue": preload("res://assets/math/shared_ui/Answer_Blue.png"),
	"green": preload("res://assets/math/shared_ui/Answer_Green.png"),
	"purple": preload("res://assets/math/shared_ui/Answer_Purple.png"),
}
## visible part of the artwork inside the texture (measured)
const INSET := Rect2(0.07, 0.123, 0.86, 0.751)

var value: Variant = 0
var label_text := ""                 ## text instead of the value (e.g. "3 + 2")
var color := "blue"
var picture: Texture2D = null        ## when set: show `value` copies of it instead of a digit
var state := "normal":
	set(v):
		state = v
		_update_state()

var _art: TextureRect
var _label: Label
var _group: GridContainer
var _mark: TextureRect
var _tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	flat = true
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(s, empty)
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_label.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_group = GridContainer.new()
	_group.add_theme_constant_override("h_separation", 6)
	_group.add_theme_constant_override("v_separation", 6)
	_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_group)
	_mark = TextureRect.new()
	_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.visible = false
	add_child(_mark)
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	resized.connect(_layout)
	setup(value, color, picture)


func setup(p_value: Variant, p_color: String, p_picture: Texture2D = null, p_text: String = "") -> void:
	value = p_value
	color = p_color
	picture = p_picture
	label_text = p_text
	if not is_node_ready():
		return
	state = "normal"
	flat = picture == null
	if picture:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.92)
		sb.set_corner_radius_all(34)
		sb.set_border_width_all(4)
		sb.border_color = Color("9fc6ff")
		sb.shadow_color = Color(0.1, 0.3, 0.7, 0.18)
		sb.shadow_size = 8
		for s in ["normal", "hover", "pressed", "disabled"]:
			add_theme_stylebox_override(s, sb)
		_art.visible = false
		_label.visible = false
		_group.visible = true
		for c in _group.get_children():
			c.queue_free()
		for i in value:
			var t := TextureRect.new()
			t.texture = picture
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_group.add_child(t)
	else:
		var empty := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "disabled"]:
			add_theme_stylebox_override(s, empty)
		_art.visible = true
		_art.texture = TEXTURES.get(color, TEXTURES["blue"])
		_label.visible = true
		_group.visible = false
		_label.text = label_text if label_text != "" else str(value)
		var light := color in ["yellow", "green"]
		_label.add_theme_color_override("font_color", UiTheme.NAVY if light else Color.WHITE)
		_label.add_theme_constant_override("outline_size", 0 if light else 12)
		_label.add_theme_color_override("font_outline_color", Color(0.05, 0.15, 0.45, 0.6))
	_layout()


func _visible_rect() -> Rect2:
	if picture:
		return Rect2(Vector2.ZERO, size)
	return Rect2(size * INSET.position, size * INSET.size)


func _layout() -> void:
	pivot_offset = size / 2.0
	var r := _visible_rect()
	var long_text := _label.text.length() > 2
	_label.add_theme_font_size_override("font_size", int(r.size.y * (0.46 if long_text else 0.72)))
	# objects in 1 row (flat cards) or 2 balanced rows (tall cards), as large as fits
	var n: int = _group.get_child_count()
	if n > 0:
		var rows := 2 if size.y > 150 and n > 5 else 1
		var cols := int(ceil(float(n) / rows))
		_group.columns = cols
		var s := minf((size.y - 30 - 6 * (rows - 1)) / rows, (size.x - 40 - 6 * (cols - 1)) / cols)
		s = minf(s, 104.0)
		for c in _group.get_children():
			(c as Control).custom_minimum_size = Vector2(s, s)
		var gs := Vector2(cols * s + 6 * (cols - 1), rows * s + 6 * (rows - 1))
		_group.size = gs
		_group.position = (size - gs) / 2.0
	var m := minf(r.size.y * 0.55, 90.0)
	_mark.size = Vector2(m, m)
	_mark.position = Vector2(r.end.x - m * 0.75, r.position.y - m * 0.25)
	queue_redraw()


func _update_state() -> void:
	if not is_node_ready():
		return
	match state:
		"wrong":
			disabled = true
			focus_mode = Control.FOCUS_NONE
			modulate = Color(0.62, 0.64, 0.72, 0.75)
			_mark.texture = preload("res://assets/math/subtraction_10/icons/Subtraction_Cross_Red.png")
			_mark.visible = true
		"correct":
			modulate = Color.WHITE
			_mark.texture = preload("res://assets/icons/Settings_Icon_Confirm.png")
			_mark.visible = true
		_:
			disabled = false
			focus_mode = Control.FOCUS_ALL
			modulate = Color.WHITE
			_mark.visible = false
	queue_redraw()


func _draw() -> void:
	if has_focus() or state == "correct":
		var r := _visible_rect().grow(6)
		var ring := UiTheme.focus_ring(int(r.size.y * 0.32), 7)
		if state == "correct":
			ring.border_color = Color("3ccf4e")
			ring.shadow_color = Color(0.3, 0.9, 0.4, 0.6)
		ring.draw(get_canvas_item(), r)


func _on_focus(on: bool) -> void:
	queue_redraw()
	if _tween:
		_tween.kill()
	var target := Vector2.ONE * (1.06 if on else 1.0)
	if AppState.animations_enabled():
		_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "scale", target, 0.14)
	else:
		scale = target


func shake() -> void:
	if not AppState.animations_enabled():
		return
	var t := create_tween()
	var x := position.x
	for dx in [16.0, -16.0, 10.0, -10.0, 0.0]:
		t.tween_property(self, "position:x", x + dx, 0.045)
