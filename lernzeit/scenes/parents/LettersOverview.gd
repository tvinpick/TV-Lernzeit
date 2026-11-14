extends BaseScreen
## "Gelernte Buchstaben" (parents area): all letters A–Z + Ä Ö Ü, coloured by
## status from the German exercises: sicher (green), in Übung (orange),
## noch nicht geübt (white). Each tile shows the last answers as dots.

const COLORS := {"secure": Color("49c25a"), "practice": Color("f5a524"), "not_started": Color(1, 1, 1, 0.92)}
var back_button: PillButton
var tiles := {}


func _ready() -> void:
	add_background("res://assets/backgrounds/progress_background_1080p.png")
	add_title("letters_title", "res://assets/icons/subject_deutsch.png")
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel("main", 40))
	panel.position = Vector2(SAFE_X, 170)
	panel.size = Vector2(1920 - SAFE_X * 2, 740)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)
	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	v.add_child(grid)
	for l in LetterGenerator.LETTERS_ALL:
		grid.add_child(_tile(l))
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 36)
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(legend)
	for k in [["secure", "letters_legend_secure"], ["practice", "letters_legend_practice"], ["not_started", "letters_legend_none"]]:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var sw := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = COLORS[k[0]]
		sb.set_corner_radius_all(8)
		sb.border_color = Color("8fb4ff")
		sb.set_border_width_all(2)
		sw.add_theme_stylebox_override("panel", sb)
		sw.custom_minimum_size = Vector2(34, 34)
		sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(sw)
		var lab := Label.new()
		lab.theme_type_variation = &"BodyLabel"
		lab.text = k[1]
		hb.add_child(lab)
		legend.add_child(hb)
	var hint := Label.new()
	hint.theme_type_variation = &"CaptionLabel"
	hint.text = "letters_hint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(hint)
	back_button = PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back_button.name = "BackButton"
	back_button.sound = "back"
	back_button.custom_minimum_size.x = 300
	back_button.pressed.connect(func(): main.pop())
	add_bottom_bar([back_button], [])
	FocusManager.set_neighbors(back_button)


func _tile(letter: String) -> PanelContainer:
	var status := ProgressRepository.letter_status(letter)
	var p := PanelContainer.new()
	p.name = "Letter_" + letter
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLORS[status]
	sb.set_corner_radius_all(22)
	sb.border_color = Color("8fb4ff") if status == "not_started" else COLORS[status].darkened(0.25)
	sb.set_border_width_all(4)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(158, 150)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var l := Label.new()
	l.text = letter + letter.to_lower()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
	l.add_theme_font_size_override("font_size", 58)
	l.add_theme_color_override("font_color", Color.WHITE if status != "not_started" else UiTheme.NAVY)
	v.add_child(l)
	var hist := ProgressRepository.letter_history(letter).right(5)
	var dots := HBoxContainer.new()       # last answers: filled = right, ring = wrong
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 6)
	dots.custom_minimum_size.y = 20
	v.add_child(dots)
	for c in (hist.split("") if hist != "" else PackedStringArray()):
		var d := Panel.new()
		var dsb := StyleBoxFlat.new()
		dsb.set_corner_radius_all(8)
		dsb.bg_color = Color.WHITE if c == "1" else Color(1, 1, 1, 0)
		dsb.border_color = Color.WHITE
		dsb.set_border_width_all(3)
		d.add_theme_stylebox_override("panel", dsb)
		d.custom_minimum_size = Vector2(16, 16)
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dots.add_child(d)
	tiles[letter] = {"panel": p, "status": status}
	return p


func get_default_focus() -> Control:
	return back_button
