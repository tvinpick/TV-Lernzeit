class_name FitLabel
extends Label
## Single-line label that shrinks its font (down to min_ratio of the theme
## size) so a translation never gets clipped. Re-fits on resize, language
## change and text-size change.

@export var min_ratio := 0.6
var _last_sig := ""


func _ready() -> void:
	clip_text = false
	autowrap_mode = TextServer.AUTOWRAP_OFF
	resized.connect(_queue_fit)
	_queue_fit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED or what == NOTIFICATION_THEME_CHANGED:
		_queue_fit()


func set_key(key: String) -> void:
	text = key
	_queue_fit()


func _queue_fit() -> void:
	_fit.call_deferred()


func _base_size() -> int:
	var th: Theme = AppState.theme
	var type := theme_type_variation if theme_type_variation != &"" else &"Label"
	if th and th.has_font_size("font_size", type):
		return th.get_font_size("font_size", type)
	return th.default_font_size if th else 30


func _fit() -> void:
	if not is_inside_tree():
		return
	var base := _base_size()
	var shown := atr(text) if auto_translate_mode != Node.AUTO_TRANSLATE_MODE_DISABLED else text
	var avail := size.x
	var sig := "%s|%d|%d" % [shown, int(avail), base]
	if sig == _last_sig or avail <= 1.0:
		return
	_last_sig = sig
	var f := get_theme_font("font")
	var s := base
	var min_s := int(base * min_ratio)
	while s > min_s and f.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x + 8 > avail:
		s -= 1
	add_theme_font_size_override("font_size", s)
