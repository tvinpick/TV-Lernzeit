class_name Toast
extends PanelContainer
## Short notice at the bottom of the screen (e.g. "Einstellungen gespeichert").

var _label: Label
var _timer: SceneTreeTimer


func _ready() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.13, 0.42, 0.92)
	sb.set_corner_radius_all(40)
	sb.border_color = Color(0.5, 0.85, 1, 0.8)
	sb.set_border_width_all(3)
	sb.content_margin_left = 40
	sb.content_margin_right = 40
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	add_theme_stylebox_override("panel", sb)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.theme_type_variation = &"ToastLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	add_child(_label)
	visible = false


func show_text(text: String, seconds: float = 2.6) -> void:
	_label.text = text
	visible = true
	modulate.a = 1.0
	reset_size()
	position = Vector2((1920 - size.x) / 2.0, 1080 - 54 - 110 - size.y)
	var timer := get_tree().create_timer(seconds)
	_timer = timer
	await timer.timeout
	if _timer == timer:
		visible = false
