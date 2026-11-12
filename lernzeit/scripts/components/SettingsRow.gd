class_name SettingsRow
extends PanelContainer
## Row = icon + title + subtitle + controls on the right (glass row).
## Uses a flow layout: when a translation or the large text size makes the
## controls too wide, they wrap onto a second line instead of being clipped.
## The row lights up while one of its controls has focus.

var icon_path := ""
var title_key := ""
var subtitle_key := ""
var tint := "blue"
var controls: HBoxContainer
var title_label: Label
var subtitle_label: Label
var header: HBoxContainer
var _badge: Label


static func make(p_icon: String, p_title: String, p_subtitle: String, p_style: String = "row_blue") -> SettingsRow:
	var r := SettingsRow.new()
	r.icon_path = p_icon
	r.title_key = p_title
	r.subtitle_key = p_subtitle
	r.tint = p_style.trim_prefix("row_")
	return r


func _init() -> void:
	controls = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 14)
	controls.alignment = BoxContainer.ALIGNMENT_END
	controls.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	controls.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END


func _ready() -> void:
	add_theme_stylebox_override("panel", UiSkin.row(tint))
	custom_minimum_size.y = 104
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 20)
	flow.add_theme_constant_override("v_separation", 10)
	flow.alignment = FlowContainer.ALIGNMENT_END
	add_child(flow)
	header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_child(header)
	if icon_path != "":
		var ic := TextureRect.new()
		ic.texture = load(icon_path)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(68, 68)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(ic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", 0)
	header.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	v.add_child(top)
	title_label = Label.new()
	title_label.theme_type_variation = &"RowTitle"
	title_label.text = title_key
	top.add_child(title_label)
	_badge = Label.new()
	_badge.theme_type_variation = &"CaptionLabel"
	_badge.text = "later_badge"
	_badge.visible = false
	_badge.add_theme_color_override("font_color", Color("b0480b"))
	top.add_child(_badge)
	if subtitle_key != "":
		subtitle_label = Label.new()
		subtitle_label.theme_type_variation = &"CaptionLabel"
		subtitle_label.text = subtitle_key
		subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subtitle_label.custom_minimum_size.x = 300
		v.add_child(subtitle_label)
	flow.add_child(controls)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


func add_control(c: Control) -> Control:
	controls.add_child(c)
	return c


func show_later_badge(on: bool = true) -> void:
	_badge.visible = on


func _on_focus_changed(c: Control) -> void:
	var inside := c != null and is_ancestor_of(c)
	add_theme_stylebox_override("panel", UiSkin.row(tint, inside))
