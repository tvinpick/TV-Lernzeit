class_name VolumeSlider
extends Control
## Focusable volume slider. Left/Right change the value in 5 % steps while
## focused; Up/Down leave the slider. Value is shown as "65 %".

signal changed(value: int)

const STEP := 5
var value := 65
var _speaker := preload("res://assets/icons/Settings_Icon_Sound.png")


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(520, 88)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_value(v: int) -> void:
	value = clampi(v, 0, 100)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var delta := 0
	if event.is_action_pressed("ui_left", true):
		delta = -STEP
	elif event.is_action_pressed("ui_right", true):
		delta = STEP
	if delta != 0:
		accept_event()
		var nv := clampi(value + delta, 0, 100)
		if nv != value:
			value = nv
			queue_redraw()
			changed.emit(value)
			Sfx.play("move")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var r := _track_rect()
		var nv2 := clampi(int(roundf((event.position.x - r.position.x) / r.size.x * 20.0)) * STEP, 0, 100)
		value = nv2
		queue_redraw()
		changed.emit(value)


func _track_rect() -> Rect2:
	var left := 76.0
	var right := 150.0
	return Rect2(Vector2(left, size.y / 2.0 - 20), Vector2(size.x - left - right, 40))


func _draw() -> void:
	var tr := _track_rect()
	draw_texture_rect(_speaker, Rect2(Vector2(6, size.y / 2.0 - 30), Vector2(60, 60)), false)
	UiSkin.track().draw(get_canvas_item(), tr.grow(4))
	var fill := tr.grow(-7)
	fill.size.x = maxf(0.0, fill.size.x * value / 100.0)
	if fill.size.x > 0.0:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("1b7cf2")
		sb.set_corner_radius_all(int(fill.size.y / 2.0))
		sb.border_width_top = 6
		sb.border_color = Color("53b4ff")
		sb.draw(get_canvas_item(), fill)
	var kx := tr.position.x + 7 + (tr.size.x - 14) * value / 100.0
	var kc := Vector2(kx, size.y / 2.0)
	draw_circle(kc, 25, Color(0.1, 0.3, 0.7, 0.35))
	draw_circle(kc, 22, Color.WHITE)
	draw_circle(kc, 22, Color("9cc4ff"), false, 3.0, true)
	var f := get_theme_font("font", "HeadingLabel")
	var fs := get_theme_font_size("font_size", "HeadingLabel")
	var txt := "%d %%" % value
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pill_r := Rect2(Vector2(size.x - 136, size.y / 2.0 - 34), Vector2(132, 68))
	UiSkin.pill("light").draw(get_canvas_item(), pill_r)
	draw_string(f, Vector2(pill_r.get_center().x - w / 2.0, pill_r.get_center().y + fs * 0.36), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.NAVY)
	if has_focus():
		UiTheme.focus_ring(34).draw(get_canvas_item(), Rect2(Vector2(-6, 2), size + Vector2(12, -4)))
