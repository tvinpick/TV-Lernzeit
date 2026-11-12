class_name LetterButton
extends Button
## Letter answer button / letter tile from the Deutsch kit with a live letter label.
## kind "button": Deutsch_Letter_Button_* (+ Focus_Overlay when focused)
## kind "tile":   Deutsch_Letter_Tile_Default / _Focused (word building)

const TEX := {
	"normal": preload("res://assets/deutsch/ui/letter_buttons/Deutsch_Letter_Button_Default.png"),
	"correct": preload("res://assets/deutsch/ui/letter_buttons/Deutsch_Letter_Button_Correct.png"),
	"wrong": preload("res://assets/deutsch/ui/letter_buttons/Deutsch_Letter_Button_Incorrect.png"),
	"disabled": preload("res://assets/deutsch/ui/letter_buttons/Deutsch_Letter_Button_Disabled.png"),
	"focus": preload("res://assets/deutsch/ui/letter_buttons/Deutsch_Focus_Overlay.png"),
	"tile": preload("res://assets/deutsch/ui/word_tiles/Deutsch_Letter_Tile_Default.png"),
	"tile_focus": preload("res://assets/deutsch/ui/word_tiles/Deutsch_Letter_Tile_Focused.png"),
}
const INK := Color("2c1a6e")

var value := ""
var kind := "button"
var state := "normal":
	set(v):
		state = v
		_update()

var _art: TextureRect
var _overlay: TextureRect
var _label: Label
var _tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	flat = true
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(s, empty)
	_overlay = TextureRect.new()
	_overlay.texture = TEX["focus"]
	_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	add_child(_overlay)
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
	_label.add_theme_color_override("font_color", INK)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	resized.connect(_layout)
	setup(value, kind)


func setup(p_value: String, p_kind: String = "button") -> void:
	value = p_value
	kind = p_kind
	if not is_node_ready():
		return
	_label.text = value
	visible = true
	state = "normal"
	_layout()


func _layout() -> void:
	pivot_offset = size / 2.0
	_label.add_theme_font_size_override("font_size", int(size.y * 0.58))
	var grow := size * Vector2(18.0 / 330.0, 18.0 / 216.0)
	_overlay.position = -grow
	_overlay.size = size + grow * 2.0


func _update() -> void:
	if not is_node_ready():
		return
	disabled = state in ["wrong", "used"]
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	modulate = Color(1, 1, 1, 0.35) if state == "used" else Color.WHITE
	_refresh_art()


func _refresh_art() -> void:
	if kind == "tile":
		_art.texture = TEX["tile_focus"] if has_focus() else TEX["tile"]
		_overlay.visible = false
	else:
		match state:
			"correct": _art.texture = TEX["correct"]
			"wrong": _art.texture = TEX["wrong"]
			_: _art.texture = TEX["normal"]
		_overlay.visible = false
	queue_redraw()
	_label.modulate = Color(1, 1, 1, 0.55) if state == "wrong" else Color.WHITE


func _draw() -> void:
	if has_focus() and state in ["normal", "correct"]:
		var r := Rect2(Vector2.ZERO, size).grow(12)
		UiTheme.focus_ring(int(size.y * 0.24), 10).draw(get_canvas_item(), r)


func _on_focus(on: bool) -> void:
	_refresh_art()
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
