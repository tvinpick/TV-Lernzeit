class_name XpBar
extends PanelContainer
## Experience bar: "Stufe 3" + a bar that fills with XP. animate(from, to) fills it
## step by step and emits level_up(n) whenever a new level is reached.

signal level_up(level: int)

const FILL := Color("ffc928")
const FILL_END := Color("ff9b1a")

var _level_l: Label
var _xp_l: Label
var _bar: Control
var _ratio := 0.0
var _xp := 0


static func make(w: float = 380.0) -> XpBar:
	var b := XpBar.new()
	b.custom_minimum_size = Vector2(w, 0)
	return b


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.16, 0.45, 0.72)
	sb.set_corner_radius_all(30)
	sb.content_margin_left = 16
	sb.content_margin_right = 18
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.border_color = Color(1, 1, 1, 0.55)
	sb.set_border_width_all(2)
	add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h)
	var star := TextureRect.new()
	star.texture = preload("res://assets/math/shared_ui/Object_Star_Yellow.png")
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.custom_minimum_size = Vector2(52, 52)
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(star)
	_level_l = Label.new()
	_level_l.name = "LevelLabel"
	star.add_child(_level_l)
	_level_l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_level_l.offset_top = 4
	_level_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_level_l.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
	_level_l.add_theme_font_size_override("font_size", 24)
	_level_l.add_theme_color_override("font_color", Color("6a3a00"))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	_xp_l = Label.new()
	_xp_l.name = "XpLabel"
	_xp_l.theme_type_variation = &"OnDarkBody"
	_xp_l.add_theme_font_size_override("font_size", 22)
	_xp_l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	v.add_child(_xp_l)
	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(0, 20)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.draw.connect(_draw_bar)
	v.add_child(_bar)


func _draw_bar() -> void:
	var r := Rect2(Vector2.ZERO, _bar.size)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.25)
	bg.set_corner_radius_all(10)
	bg.draw(_bar.get_canvas_item(), r)
	if _ratio > 0.0:
		var f := StyleBoxFlat.new()
		f.bg_color = FILL.lerp(FILL_END, _ratio)
		f.set_corner_radius_all(10)
		f.draw(_bar.get_canvas_item(), Rect2(r.position, Vector2(maxf(20.0, r.size.x * _ratio), r.size.y)))


## Shows the given total XP without animation.
func show_xp(xp: int) -> void:
	_xp = xp
	var info := Progression.level_info(xp)
	_ratio = float(info[1]) / float(info[2])
	_level_l.text = str(info[0])
	_xp_l.text = Localization.t("xp_level", {"n": info[0], "xp": info[1], "need": info[2]})
	_bar.queue_redraw()


func level() -> int:
	return int(_level_l.text)


## Fills the bar from `from` to `to` XP; emits level_up for every new level.
func animate(from: int, to: int, seconds: float = 1.4) -> void:
	show_xp(from)
	if to <= from:
		return
	if not AppState.animations_enabled():
		var l0: int = Progression.level_info(from)[0]
		show_xp(to)
		for n in range(l0 + 1, int(Progression.level_info(to)[0]) + 1):
			level_up.emit(n)
		return
	var tw := create_tween()
	tw.tween_method(func(x: float):
		var before := level()
		show_xp(int(x))
		if level() > before:
			level_up.emit(level()), float(from), float(to), seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
