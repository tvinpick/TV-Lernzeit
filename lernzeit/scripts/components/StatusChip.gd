class_name StatusChip
extends PanelContainer
## Status badge (gray "Noch nicht geübt" etc.). Text is localized by key.

var key := "status_not_started"
var icon_path := "res://assets/icons/Lernzeit_Icon_Clock.png"


static func make(p_key: String) -> StatusChip:
	var c := StatusChip.new()
	c.key = p_key
	return c


func _ready() -> void:
	var sb: StyleBoxTexture = UiSkin.pill("gray").duplicate()
	sb.content_margin_left = 22
	sb.content_margin_right = 28
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	add_theme_stylebox_override("panel", sb)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	add_child(h)
	var ic := TextureRect.new()
	ic.texture = load(icon_path)
	ic.modulate = Color(1, 1, 1, 0.95)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(38, 38)
	h.add_child(ic)
	var l := Label.new()
	l.theme_type_variation = &"OnDarkCaption"
	l.text = key
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
