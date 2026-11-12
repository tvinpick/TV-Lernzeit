extends BaseScreen
## Sticker album: 20 stickers (5 × 4); earned ones in colour, the rest as dark
## silhouettes with a question mark. One sticker per finished exercise.

var back_button: PillButton
var slots: Array = []


func _ready() -> void:
	add_background("res://assets/backgrounds/progress_background_1080p.png")
	add_title("stickers_title", "res://assets/mascot/stickers/Sticker_14.png")
	var earned := Achievements.stickers_earned()
	var count := Label.new()
	count.theme_type_variation = &"OnDarkBody"
	count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	count.text = Localization.t("stickers_count", {"n": earned, "total": Achievements.STICKER_COUNT})
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.position = Vector2(SAFE_X, 150)
	count.size = Vector2(1920 - SAFE_X * 2, 44)
	add_child(count)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel("main", 40))
	panel.position = Vector2(300, 200)
	panel.size = Vector2(1320, 710)
	add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 14)
	panel.add_child(grid)
	for i in range(1, Achievements.STICKER_COUNT + 1):
		var slot := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.75) if i <= earned else Color(0.85, 0.88, 0.97, 0.55)
		sb.set_corner_radius_all(26)
		sb.border_color = Color("ffd21f") if i <= earned else Color("b8c4ea")
		sb.set_border_width_all(4)
		slot.add_theme_stylebox_override("panel", sb)
		slot.custom_minimum_size = Vector2(220, 142)
		grid.add_child(slot)
		var t := TextureRect.new()
		t.texture = load(Achievements.sticker_path(i))
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(t)
		if i > earned:
			t.modulate = Color(0.25, 0.28, 0.42, 0.35)
			var q := Label.new()
			q.text = "?"
			q.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			q.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
			q.add_theme_font_size_override("font_size", 64)
			q.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
			q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.add_child(q)
		slots.append({"slot": slot, "earned": i <= earned})
	back_button = PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back_button.name = "BackButton"
	back_button.sound = "back"
	back_button.custom_minimum_size.x = 300
	back_button.pressed.connect(func(): main.pop())
	add_bottom_bar([back_button], [])
	FocusManager.set_neighbors(back_button)
	var owl := Mascot.make("happy", 260, Vector2(1640, 640))
	add_child(owl)
	Mascot.bob(owl)


func get_default_focus() -> Control:
	return back_button
