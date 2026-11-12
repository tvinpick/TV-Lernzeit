class_name PictureButton
extends Button
## Picture answer (reading: "choose the picture"). value = German word.

const FRAME := preload("res://assets/deutsch/ui/panels/Deutsch_Picture_Frame.png")

var value := ""
var state := "normal":
	set(v):
		state = v
		_update()
var _pic: TextureRect
var _mark: TextureRect
var _tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	flat = false          # the frame is the button's stylebox
	var sb := StyleBoxTexture.new()
	sb.texture = FRAME
	for m in ["texture_margin_left", "texture_margin_right", "texture_margin_top", "texture_margin_bottom"]:
		sb.set(m, 60)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	for s in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(s, sb)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_pic = TextureRect.new()
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pic.offset_left = 14
	_pic.offset_top = 14
	_pic.offset_right = -14
	_pic.offset_bottom = -14
	_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pic)
	_mark = TextureRect.new()
	_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mark.size = Vector2(64, 64)
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.visible = false
	add_child(_mark)
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	resized.connect(func():
		pivot_offset = size / 2.0
		_mark.position = Vector2(size.x - 54, -10))


func setup(word: String, picture: String) -> void:
	value = word
	_pic.texture = load(picture)
	state = "normal"


func _update() -> void:
	if not is_node_ready():
		return
	disabled = state == "wrong"
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	modulate = Color(0.6, 0.6, 0.7, 0.6) if state == "wrong" else Color.WHITE
	_mark.visible = state != "normal"
	_mark.texture = preload("res://assets/icons/Settings_Icon_Confirm.png") if state == "correct" else preload("res://assets/math/subtraction_10/icons/Subtraction_Cross_Red.png")
	queue_redraw()


func _draw() -> void:
	if has_focus() or state == "correct":
		var ring := UiTheme.focus_ring(int(size.y * 0.2), 10)
		if state == "correct":
			ring.border_color = Color("3ccf4e")
			ring.shadow_color = Color(0.3, 0.9, 0.4, 0.6)
		ring.draw(get_canvas_item(), Rect2(Vector2.ZERO, size).grow(10))


func _on_focus(on: bool) -> void:
	queue_redraw()
	if _tween:
		_tween.kill()
	var target := Vector2.ONE * (1.1 if on else 1.0)
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
	for dx in [14.0, -14.0, 8.0, -8.0, 0.0]:
		t.tween_property(self, "position:x", x + dx, 0.045)
