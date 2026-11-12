extends BaseScreen
## Einstellungen: left navigation (Allgemein / Lernen / Elternbereich / Daten /
## Über die App) and the matching rows on the right. Changes apply and are
## saved immediately.

const NAV := [
	{"id": "general", "key": "nav_general", "icon": "res://assets/icons/Settings_Icon_Gear.png"},
	{"id": "learning", "key": "nav_learning", "icon": "res://assets/icons/Settings_Icon_Tasks.png"},
	{"id": "parents", "key": "nav_parents", "icon": "res://assets/icons/Settings_Icon_Parents_Lock.png"},
	{"id": "data", "key": "nav_data", "icon": "res://assets/icons/Settings_Icon_Data.png"},
	{"id": "about", "key": "nav_about", "icon": "res://assets/icons/Settings_Icon_About.png"},
]

var nav_buttons := {}
var section := "general"
var back_button: PillButton
var parents_button: PillButton
var _scroll: ScrollContainer
var _rows_box: VBoxContainer
var _row_controls: Array = []     ## [[focusable controls of row 0], ...]
var controls := {}                ## setting key -> control (for tests)


func _ready() -> void:
	add_background("res://assets/backgrounds/progress_background_4k.png")
	add_title("settings", "res://assets/icons/Settings_Icon_Gear.png")

	var nav := VBoxContainer.new()
	nav.add_theme_constant_override("separation", 18)
	nav.position = Vector2(SAFE_X, 196)
	nav.size = Vector2(470, 640)
	add_child(nav)
	for n in NAV:
		var b := PillButton.make(n["key"], "blue", load(n["icon"]))
		b.name = "Nav_" + n["id"]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(470, 100)
		b.selected_variant = "cyan"
		b.show_check = false
		b.sound = "move"
		nav.add_child(b)
		b.focus_entered.connect(_show_section.bind(n["id"]))
		b.pressed.connect(_enter_section.bind(n["id"]))
		nav_buttons[n["id"]] = b

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel("main", 40))
	panel.position = Vector2(600, 184)
	panel.size = Vector2(1920 - SAFE_X - 600, 712)
	add_child(panel)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(_scroll)
	_rows_box = VBoxContainer.new()
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override("separation", 12)
	_scroll.add_child(_rows_box)
	keep_rows_visible(_scroll, _rows_box)

	back_button = PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back_button.name = "BackButton"
	back_button.sound = "back"
	back_button.custom_minimum_size.x = 300
	back_button.pressed.connect(func(): main.pop())
	parents_button = PillButton.make("parents", "purple", preload("res://assets/icons/Settings_Icon_Parents_Lock.png"))
	parents_button.name = "ParentsButton"
	parents_button.custom_minimum_size.x = 420
	parents_button.pressed.connect(_open_parents)
	add_bottom_bar([back_button], [parents_button])

	var nb: Array = NAV.map(func(n): return nav_buttons[n["id"]])
	FocusManager.link_column(nb)
	FocusManager.set_one(nb.back(), SIDE_BOTTOM, back_button)
	for b in nb:
		FocusManager.set_one(b, SIDE_LEFT, b)
	FocusManager.set_neighbors(back_button, null, parents_button, nb.back(), null)
	FocusManager.set_neighbors(parents_button, back_button, null, nb.back(), null)
	_build_section("general")


func get_default_focus() -> Control:
	return nav_buttons[section]


func handle_back() -> bool:
	# Back inside the right panel returns to the navigation column first.
	var f := get_viewport().gui_get_focus_owner()
	if f and _rows_box.is_ancestor_of(f):
		Sfx.play("back")
		nav_buttons[section].grab_focus()
		return true
	return false


func _show_section(id: String) -> void:
	if id != section:
		_build_section(id)


func _enter_section(id: String) -> void:
	_show_section(id)
	if not _row_controls.is_empty():
		(_row_controls[0][0] as Control).grab_focus()


func _open_parents() -> void:
	main.push("pin", {"mode": "enter"})


# ---------------------------------------------------------------- content ---

func _build_section(id: String) -> void:
	section = id
	for k in nav_buttons:
		nav_buttons[k].selected = k == id
	for c in _rows_box.get_children():
		_rows_box.remove_child(c)
		c.queue_free()
	_row_controls.clear()
	controls.clear()
	match id:
		"general": _build_general()
		"learning": _build_learning()
		"parents": _build_parents()
		"data": _build_data()
		"about": _build_about()
	# Rows without own controls (Daten, Über die App) are focusable themselves
	if _row_controls.is_empty():
		for r in _rows_box.get_children():
			(r as SettingsRow).make_focusable()
			_row_controls.append([r])
	_link_content()
	_scroll.scroll_vertical = 0


func _row(icon: String, title: String, subtitle: String, style: String = "row_blue") -> SettingsRow:
	var r := SettingsRow.make(icon, title, subtitle, style)
	_rows_box.add_child(r)
	return r


func _build_general() -> void:
	var lang := OptionGroup.make([
		{"value": "de", "key": "lang_de", "icon": UiSkin.flag("de")},
		{"value": "ru", "key": "lang_ru", "icon": UiSkin.flag("ru")}], SettingsRepository.get_value("language"), 250)
	lang.changed.connect(func(v): SettingsRepository.set_value("language", v))
	_row("res://assets/icons/Settings_Icon_Language.png", "set_language", "set_language_sub").add_control(lang)
	_row_controls.append(lang.buttons)
	controls["language"] = lang

	var snd := ToggleSwitch.new()
	_row("res://assets/icons/Settings_Icon_Sound.png", "set_sound", "set_sound_sub").add_control(snd)
	snd.set_on(SettingsRepository.get_value("sound"))
	snd.changed.connect(func(on): SettingsRepository.set_value("sound", on))
	_row_controls.append([snd])
	controls["sound"] = snd

	var vol := VolumeSlider.new()
	_row("res://assets/icons/Settings_Icon_Voice.png", "set_volume", "set_volume_sub").add_control(vol)
	vol.set_value(SettingsRepository.get_value("volume"))
	vol.changed.connect(func(v): SettingsRepository.set_value("volume", v))
	_row_controls.append([vol])
	controls["volume"] = vol

	var anim := ToggleSwitch.new()
	_row("res://assets/icons/Settings_Icon_Animation.png", "set_animations", "set_animations_sub").add_control(anim)
	anim.set_on(SettingsRepository.get_value("animations"))
	anim.changed.connect(func(on): SettingsRepository.set_value("animations", on))
	_row_controls.append([anim])
	controls["animations"] = anim

	var ts := OptionGroup.make([
		{"value": "normal", "key": "text_normal"},
		{"value": "large", "key": "text_large"}], SettingsRepository.get_value("text_size"), 210)
	ts.changed.connect(func(v): SettingsRepository.set_value("text_size", v))
	_row("res://assets/icons/Settings_Icon_Text_Size.png", "set_text_size", "set_text_size_sub").add_control(ts)
	_row_controls.append(ts.buttons)
	controls["text_size"] = ts


func _build_learning() -> void:
	var ra := ToggleSwitch.new()
	var r := _row("res://assets/icons/Settings_Icon_Voice.png", "set_read_aloud", "set_read_aloud_sub")
	r.add_control(ra)
	r.show_later_badge()
	ra.set_on(false)          # not available in v0.1 – shown off and locked
	ra.locked = true
	_row_controls.append([ra])
	controls["read_aloud"] = ra

	var rep := ToggleSwitch.new()
	_row("res://assets/icons/Settings_Icon_Repeat.png", "set_repeat", "set_repeat_sub").add_control(rep)
	rep.set_on(SettingsRepository.get_value("repeat_mistakes"))
	rep.changed.connect(func(on): SettingsRepository.set_value("repeat_mistakes", on))
	_row_controls.append([rep])
	controls["repeat_mistakes"] = rep


func _build_parents() -> void:
	var r := _row("res://assets/icons/Parents_Icon_PIN.png", "parents_info_title", "parents_info_text", "row_purple")
	var b := PillButton.make("parents_open", "purple", null, true)
	r.add_control(b)
	b.pressed.connect(_open_parents)
	_row_controls.append([b])
	controls["parents_open"] = b


func _build_data() -> void:
	_row("res://assets/icons/Settings_Icon_Data.png", "data_storage", "data_storage_sub")
	var rec := _row("res://assets/icons/Settings_Icon_Statistics.png", "data_records", "")
	var n := Label.new()
	n.theme_type_variation = &"HeadingLabel"
	n.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	n.text = str(ProgressRepository.record_count())
	rec.add_control(n)
	var bk := _row("res://assets/icons/Parents_Icon_Backup.png", "data_backup", "data_backup_sub")
	bk.show_later_badge()
	_row("res://assets/icons/Parents_Icon_Reset.png", "data_reset_hint", "data_reset_hint_sub")


func _build_about() -> void:
	var r := _row("res://assets/icons/Settings_Icon_About.png", "about_app", "about_app_sub")
	var v := Label.new()
	v.theme_type_variation = &"HeadingLabel"
	v.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	v.text = AppState.app_version()
	r.add_control(v)
	_row("res://assets/icons/Settings_Icon_Tasks.png", "about_content", "about_content_sub")
	_row("res://assets/icons/Settings_Icon_Confirm.png", "about_offline", "about_offline_sub")
	_row("res://assets/icons/Settings_Icon_Text_Size.png", "about_font", "about_font_sub")


func _link_content() -> void:
	var nav_b: Control = nav_buttons[section]
	if _row_controls.is_empty():
		FocusManager.set_one(nav_b, SIDE_RIGHT, nav_b)
		return
	var firsts: Array = _row_controls.map(func(row): return row[0])
	FocusManager.set_one(nav_b, SIDE_RIGHT, firsts[0])
	for b in nav_buttons.values():
		if b != nav_b:
			FocusManager.set_one(b, SIDE_RIGHT, b)
	# Inside a section the focus is locked to that section: no way out to the
	# menu or to the bottom buttons with the arrows – only Back leaves it.
	for i in _row_controls.size():
		var row: Array = _row_controls[i]
		var up: Control = _row_controls[i - 1][0] if i > 0 else null
		var down: Control = _row_controls[i + 1][0] if i < _row_controls.size() - 1 else null
		for c in row:
			FocusManager.set_one(c, SIDE_TOP, up if up else c)
			FocusManager.set_one(c, SIDE_BOTTOM, down if down else c)
		FocusManager.set_one(row[0], SIDE_LEFT, row[0])
		if row.size() == 1:
			if not (row[0] is VolumeSlider):
				FocusManager.set_one(row[0], SIDE_RIGHT, row[0])
		else:
			FocusManager.set_one(row.back(), SIDE_RIGHT, row.back())
