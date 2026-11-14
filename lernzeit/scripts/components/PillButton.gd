class_name PillButton
extends Button
## "PrimaryButton": glossy pill button built from the approved button art
## (text-free skin) with a localized Godot label, optional icon and a check
## mark for the selected state. Remote: OK = press; focus = glow + scale.

signal activated

var variant := "light":
	set(v):
		variant = v
		_apply_style()
var selected := false:
	set(v):
		selected = v
		_apply_style()
var selected_variant := "blue"
var show_check := true
var check_icon: Texture2D = preload("res://assets/icons/Settings_Icon_Confirm.png")
var sound := "select"
var _tween: Tween


static func make(key: String, p_variant: String = "light", p_icon: Texture2D = null, small: bool = false) -> PillButton:
	var b := PillButton.new()
	b.text = key
	b.variant = p_variant
	b.icon = p_icon
	b.theme_type_variation = &"SmallPill" if small else &"PillButton"
	b.custom_minimum_size = Vector2(0, 84 if small else 96)
	return b


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	add_theme_constant_override("icon_max_width", 54)
	add_theme_constant_override("h_separation", 14)
	expand_icon = false
	_apply_style()
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	resized.connect(func(): pivot_offset = size / 2.0)
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if sound != "":
		Sfx.play(sound)
	if AppState.animations_enabled():
		_pulse()
	activated.emit()


func _apply_style() -> void:
	var v := selected_variant if selected else variant
	var sb := UiSkin.pill(v)
	var dis := UiSkin.pill("gray")
	add_theme_stylebox_override("disabled", dis)
	add_theme_stylebox_override("focus", UiTheme.focus_ring(int(size.y * 0.5) if size.y > 0 else 44))
	var col := UiSkin.pill_text_color(v)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		add_theme_color_override(c, col)
	add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.9))
	add_theme_color_override("icon_disabled_color", Color(1, 1, 1, 0.6))
	if col == Color.WHITE:
		add_theme_constant_override("outline_size", 6)
		add_theme_color_override("font_outline_color", Color(0.05, 0.15, 0.45, 0.45))
	else:
		add_theme_constant_override("outline_size", 0)
	# room for the check mark
	var extra := 46 if selected and show_check else 0
	var sb2: StyleBoxTexture = sb.duplicate()
	sb2.content_margin_right = sb.content_margin_right + extra
	for s in ["normal", "hover", "pressed"]:
		add_theme_stylebox_override(s, sb2)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		add_theme_stylebox_override("focus", UiTheme.focus_ring(int(size.y * 0.42)))


func _draw() -> void:
	if selected and show_check and check_icon:
		var s := 40.0
		draw_texture_rect(check_icon, Rect2(Vector2(size.x - 34 - s, (size.y - s) / 2.0), Vector2(s, s)), false)


func _on_focus(on: bool) -> void:
	if _tween:
		_tween.kill()
	var target := Vector2.ONE * (1.05 if on else 1.0)
	if AppState.animations_enabled():
		_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "scale", target, 0.14)
	else:
		scale = target


func _pulse() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE * 0.96, 0.06)
	t.tween_property(self, "scale", Vector2.ONE * (1.05 if has_focus() else 1.0), 0.1)
