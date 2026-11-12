class_name StatCard
extends PanelContainer
## Statistic tile: icon, big value, caption. Value "—" when there is no data.

var icon_path := ""
var caption_key := ""
var style := "stat_blue"
var value_label: Label


static func make(p_icon: String, p_caption: String, p_style: String) -> StatCard:
	var s := StatCard.new()
	s.icon_path = p_icon
	s.caption_key = p_caption
	s.style = p_style
	return s


func _ready() -> void:
	add_theme_stylebox_override("panel", UiSkin.panel(style, 44))
	custom_minimum_size = Vector2(0, 190)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	add_child(h)
	var ic := TextureRect.new()
	ic.texture = load(icon_path)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(104, 104)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", -6)
	h.add_child(v)
	value_label = Label.new()
	value_label.theme_type_variation = &"StatValue"
	value_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	v.add_child(value_label)
	var c := Label.new()
	c.theme_type_variation = &"BodyLabel"
	c.text = caption_key
	c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(c)


func set_value(text: String) -> void:
	value_label.text = text
