extends BaseScreen
## "Erfolge": 12 achievements (4 × 3), unlocked ones in gold, locked ones faded
## with a lock. Computed live from the progress (see Achievements.gd).

var back_button: PillButton
var cards := {}


func _ready() -> void:
	add_background("res://assets/backgrounds/progress_background_1080p.png")
	add_title("achievements", "res://assets/icons/Settings_Icon_Achievements.png")
	var unlocked := Achievements.unlocked_ids()
	var count := Label.new()
	count.theme_type_variation = &"OnDarkBody"
	count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	count.text = Localization.t("ach_count", {"n": unlocked.size(), "total": Achievements.LIST.size()})
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.position = Vector2(SAFE_X, 150)
	count.size = Vector2(1920 - SAFE_X * 2, 44)
	add_child(count)
	var grid := GridContainer.new()
	grid.columns = 3                       # 3 × 4: enough room for long (Russian / large) texts
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	grid.position = Vector2(SAFE_X, 200)
	grid.size = Vector2(1920 - SAFE_X * 2, 690)
	add_child(grid)
	for a in Achievements.LIST:
		var on: bool = a[0] in unlocked
		var card := PanelContainer.new()
		card.name = "Ach_" + a[0]
		card.add_theme_stylebox_override("panel", UiSkin.panel("stat_gold" if on else "stat_blue", 26))
		card.custom_minimum_size = Vector2(560, 160)
		if not on:
			card.self_modulate = Color(0.8, 0.83, 0.92, 0.8)      # only the panel is dimmed, text stays readable
		grid.add_child(card)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)
		var ic := TextureRect.new()
		ic.texture = load(a[3])
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(112, 112)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if not on:
			ic.modulate = Color(0.3, 0.33, 0.45, 0.5)      # dark silhouette until earned
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		v.add_theme_constant_override("separation", 2)
		h.add_child(v)
		var t := Label.new()
		t.theme_type_variation = &"RowTitle"
		t.text = a[1]
		t.autowrap_mode = TextServer.AUTOWRAP_WORD     # never split inside a word
		if not on:
			t.add_theme_color_override("font_color", Color("4a5578"))
		v.add_child(t)
		var d := Label.new()
		d.theme_type_variation = &"CaptionLabel"
		d.text = a[2]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", int(24 * AppState.text_scale()))
		if not on:
			d.add_theme_color_override("font_color", Color("4a5578"))
		v.add_child(d)
		cards[a[0]] = card
	back_button = PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back_button.name = "BackButton"
	back_button.sound = "back"
	back_button.custom_minimum_size.x = 300
	back_button.pressed.connect(func(): main.pop())
	add_bottom_bar([back_button], [])
	FocusManager.set_neighbors(back_button)


func get_default_focus() -> Control:
	return back_button
