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
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 20)
	grid.position = Vector2(SAFE_X, 210)
	grid.size = Vector2(1920 - SAFE_X * 2, 680)
	add_child(grid)
	for a in Achievements.LIST:
		var on: bool = a[0] in unlocked
		var card := PanelContainer.new()
		card.name = "Ach_" + a[0]
		card.add_theme_stylebox_override("panel", UiSkin.panel("stat_gold" if on else "stat_blue", 34))
		card.custom_minimum_size = Vector2(416, 212)
		if not on:
			card.modulate = Color(0.75, 0.78, 0.88, 0.75)
		grid.add_child(card)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		card.add_child(h)
		var ic := TextureRect.new()
		ic.texture = load(a[3])
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(84, 84)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if not on:
			ic.modulate = Color(0.35, 0.38, 0.5, 0.55)     # silhouette until earned
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		v.add_theme_constant_override("separation", 2)
		h.add_child(v)
		var t := FitLabel.new()
		t.theme_type_variation = &"RowTitle"
		t.text = a[1]
		v.add_child(t)
		var d := Label.new()
		d.theme_type_variation = &"CaptionLabel"
		d.text = a[2]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
