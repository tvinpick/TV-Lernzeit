extends BaseScreen
## "Erfolge": achievements on pages of 9 (3 × 3), unlocked ones in gold, locked ones faded
## with a lock. Computed live from the progress (see Achievements.gd).

const PER_PAGE := 9

var back_button: PillButton
var prev_button: PillButton
var next_button: PillButton
var cards := {}                  ## cards of the page on screen
var _grid: GridContainer
var _page_label: Label
var _unlocked: Array = []
var _page := 0


func pages() -> int:
	return ceili(Achievements.LIST.size() / float(PER_PAGE))


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
	_page_label = count
	_grid = GridContainer.new()
	_grid.columns = 3                      # 3 × 3 per page: room for long (Russian / large) texts
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 22)
	_grid.position = Vector2(SAFE_X, 200)
	_grid.size = Vector2(1920 - SAFE_X * 2, 690)
	add_child(_grid)
	_unlocked = unlocked
	back_button = PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back_button.name = "BackButton"
	back_button.sound = "back"
	back_button.custom_minimum_size.x = 300
	back_button.pressed.connect(func(): main.pop())
	prev_button = PillButton.make("page_prev", "light", null)
	prev_button.name = "PrevPage"
	prev_button.custom_minimum_size.x = 300
	prev_button.pressed.connect(func(): _show_page(_page - 1))
	next_button = PillButton.make("page_next", "blue", null)
	next_button.name = "NextPage"
	next_button.custom_minimum_size.x = 300
	next_button.pressed.connect(func(): _show_page(_page + 1))
	add_bottom_bar([back_button], [prev_button, next_button])
	_show_page(0)


func get_default_focus() -> Control:
	return next_button if next_button.visible else back_button


## Shows 9 achievements; "Zurückblättern" / "Weiterblättern" switch pages.
func _show_page(p: int) -> void:
	_page = clampi(p, 0, pages() - 1)
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	cards.clear()
	for a in Achievements.LIST.slice(_page * PER_PAGE, (_page + 1) * PER_PAGE):
		_grid.add_child(_card(a))
	_page_label.text = Localization.t("ach_count", {"n": _unlocked.size(), "total": Achievements.LIST.size()}) \
		+ "  ·  " + Localization.t("ach_page", {"n": _page + 1, "total": pages()})
	prev_button.visible = _page > 0
	next_button.visible = _page < pages() - 1
	var row: Array = [back_button]
	for b in [prev_button, next_button]:
		if b.visible:
			row.append(b)
	FocusManager.link_row(row)
	for b in row:
		FocusManager.set_one(b, SIDE_TOP, b)
		FocusManager.set_one(b, SIDE_BOTTOM, b)
	var f: Control = next_button if next_button.visible else (prev_button if prev_button.visible else back_button)
	if is_inside_tree():
		var fo := get_viewport().gui_get_focus_owner()
		if fo == null or not fo in row or not fo.visible:
			f.grab_focus.call_deferred()


func _card(a: Array) -> PanelContainer:
	var on: bool = a[0] in _unlocked
	var card := PanelContainer.new()
	card.name = "Ach_" + a[0]
	card.add_theme_stylebox_override("panel", UiSkin.panel("stat_gold" if on else "stat_blue", 26))
	card.custom_minimum_size = Vector2(560, 200)
	if not on:
		card.self_modulate = Color(0.8, 0.83, 0.92, 0.8)      # only the panel is dimmed, text stays readable
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
	return card
