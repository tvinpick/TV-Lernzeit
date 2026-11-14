class_name OptionGroup
extends HBoxContainer
## Segmented choice (e.g. Deutsch | Русский, Normal | Groß, 15/30/45 Min).
## Selected option = blue pill with check mark; OK selects the focused option.

signal changed(value: Variant)

var options: Array = []      ## [{value, key, icon}]
var value: Variant
var buttons: Array[PillButton] = []
var min_button_width := 0


static func make(p_options: Array, p_value: Variant, p_min_width: int = 0) -> OptionGroup:
	var g := OptionGroup.new()
	g.options = p_options
	g.value = p_value
	g.min_button_width = p_min_width
	return g


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	for o in options:
		var b := PillButton.make(o["key"], "light", o.get("icon"), true)
		b.custom_minimum_size.x = min_button_width
		b.sound = "toggle"
		if o.get("no_translate", false):
			b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.pressed.connect(_on_pressed.bind(o["value"]))
		add_child(b)
		buttons.append(b)
	FocusManager.link_row(buttons)
	_refresh()


func set_value(v: Variant) -> void:
	value = v
	_refresh()


func _on_pressed(v: Variant) -> void:
	if v == value:
		return
	value = v
	_refresh()
	changed.emit(v)


func _refresh() -> void:
	for i in buttons.size():
		buttons[i].selected = options[i]["value"] == value


func first() -> Control:
	return buttons[0]


func last() -> Control:
	return buttons[buttons.size() - 1]


func selected_button() -> Control:
	for i in buttons.size():
		if options[i]["value"] == value:
			return buttons[i]
	return buttons[0]
