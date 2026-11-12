class_name EmptyState
extends VBoxContainer
## Friendly empty / "not yet available" state: icon, title, explanation.

var icon_path := ""
var title_key := ""
var text_key := ""
var on_dark := false


static func make(p_icon: String, p_title: String, p_text: String, p_on_dark: bool = false) -> EmptyState:
	var e := EmptyState.new()
	e.icon_path = p_icon
	e.title_key = p_title
	e.text_key = p_text
	e.on_dark = p_on_dark
	return e


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 18)
	if icon_path != "":
		var ic := TextureRect.new()
		ic.texture = load(icon_path)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(150, 150)
		add_child(ic)
	var t := Label.new()
	t.theme_type_variation = &"TitleLabel" if on_dark else &"HeadingLabel"
	t.text = title_key
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(t)
	if text_key != "":
		var m := Label.new()
		m.theme_type_variation = &"OnDarkBody" if on_dark else &"BodyLabel"
		m.text = text_key
		m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(m)
