extends BaseScreen
## Elternbereich (after PIN): child profile, subjects, difficulty, session
## length, help language, PIN change, progress reset (PIN + confirmation),
## backup (not available – clearly marked) and the real app version.
## Edits go into a draft; "Speichern" persists, "Abbrechen"/Back discard.

var draft := {}
var _saved := {}
var _rows_box: VBoxContainer
var _scroll: ScrollContainer
var _row_controls: Array = []
var _profile_row: SettingsRow
var subject_chips := {}
var controls := {}
var back_button: PillButton
var cancel_button: PillButton
var save_button: PillButton


func _ready() -> void:
	_saved = SettingsRepository.get_parent_settings()
	draft = _saved.duplicate(true)
	add_background("res://assets/backgrounds/progress_background_1080p.png")
	add_title("parents", "res://assets/icons/Settings_Icon_Parents_Lock.png", SAFE_Y - 6)
	var only := Label.new()
	only.theme_type_variation = &"OnDarkCaption"
	only.text = "parents_only"
	only.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	only.position = Vector2(SAFE_X, 142)
	only.size = Vector2(1920 - SAFE_X * 2, 36)
	add_child(only)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel("main", 36))
	panel.position = Vector2(SAFE_X, 190)
	panel.size = Vector2(1920 - SAFE_X * 2, 708)
	add_child(panel)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(_scroll)
	_rows_box = VBoxContainer.new()
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override("separation", 10)
	_scroll.add_child(_rows_box)
	keep_rows_visible(_scroll, _rows_box)

	_build_rows()

	back_button = PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back_button.name = "BackButton"
	back_button.sound = "back"
	back_button.custom_minimum_size.x = 300
	back_button.pressed.connect(_leave)
	cancel_button = PillButton.make("cancel", "light", preload("res://assets/icons/Settings_Icon_Cancel.png"))
	cancel_button.name = "CancelButton"
	cancel_button.sound = "back"
	cancel_button.custom_minimum_size.x = 300
	cancel_button.pressed.connect(_cancel)
	save_button = PillButton.make("save", "green", preload("res://assets/icons/Settings_Icon_Confirm.png"))
	save_button.name = "SaveButton"
	save_button.custom_minimum_size.x = 340
	save_button.pressed.connect(_save)
	add_bottom_bar([back_button], [cancel_button, save_button])
	_link()


func get_default_focus() -> Control:
	return _row_controls[0][0]


func is_dirty() -> bool:
	return JSON.stringify(draft) != JSON.stringify(_saved)


func handle_back() -> bool:
	_leave()
	return true


# ------------------------------------------------------------------- rows ---

func _row(icon: String, title: String, subtitle: String, style: String = "row_blue") -> SettingsRow:
	var r := SettingsRow.make(icon, title, subtitle, style)
	_rows_box.add_child(r)
	return r


func _build_rows() -> void:
	# Kindprofil
	_profile_row = _row("res://assets/icons/Parents_Icon_Profile.png", "p_profile", "")
	var sub := Label.new()
	sub.theme_type_variation = &"CaptionLabel"
	sub.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	sub.name = "ProfileSub"
	var edit := PillButton.make("p_profile_edit", "light", null, true)
	_profile_row.add_control(edit)
	_profile_row.title_label.get_parent().get_parent().add_child(sub)
	edit.pressed.connect(_edit_name)
	_row_controls.append([edit])
	controls["profile"] = edit
	_update_profile()

	# Fächer
	var r2 := _row("res://assets/icons/Parents_Icon_Subjects.png", "p_subjects", "p_subjects_sub")
	var chips: Array = []
	for sid in Curriculum.SUBJECT_IDS:
		var c := PillButton.make(Curriculum.title_key(sid), "light", load(Curriculum.SUBJECTS[sid]["icon"]), true)
		c.name = "Subject_" + sid
		c.sound = "toggle"
		c.selected = draft["subjects"][sid]
		c.add_theme_constant_override("icon_max_width", 44)
		c.pressed.connect(_toggle_subject.bind(sid))
		r2.add_control(c)
		chips.append(c)
		subject_chips[sid] = c
	FocusManager.link_row(chips)
	_row_controls.append(chips)

	# Gelernte Buchstaben (letter statistics from the German exercises)
	var lr := _row("res://assets/icons/subject_deutsch.png", "p_letters", "", "row_purple")
	var lsub := Label.new()
	lsub.theme_type_variation = &"CaptionLabel"
	lsub.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	lsub.name = "LettersSub"
	lr.title_label.get_parent().get_parent().add_child(lsub)
	var lb := PillButton.make("p_letters_button", "light", null, true)
	lb.name = "LettersButton"
	lr.add_control(lb)
	lb.pressed.connect(func(): main.push("letters"))
	_row_controls.append([lb])
	controls["letters"] = lb
	_update_letters()

	# Diese Woche (short report for parents)
	var wr := _row("res://assets/icons/Lernzeit_Icon_Calendar.png", "p_week", "", "row_blue")
	var wsub := Label.new()
	wsub.theme_type_variation = &"CaptionLabel"
	wsub.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	wsub.name = "WeekSub"
	wsub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wr.title_label.get_parent().get_parent().add_child(wsub)
	wr.name = "WeekRow"
	wr.make_focusable()
	_row_controls.append([wr])
	_update_week()

	# Schwierige Aufgaben (open mistakes from the task history)
	var hr := _row("res://assets/icons/Lernzeit_Icon_Target.png", "p_hard", "", "row_purple")
	var hsub := Label.new()
	hsub.theme_type_variation = &"CaptionLabel"
	hsub.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	hsub.name = "HardSub"
	hsub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hr.title_label.get_parent().get_parent().add_child(hsub)
	hr.name = "HardRow"
	hr.make_focusable()
	_row_controls.append([hr])
	_update_hard()

	# Schwierigkeit
	var diff := OptionGroup.make([
		{"value": "easy", "key": "diff_easy"}, {"value": "auto", "key": "diff_auto"},
		{"value": "hard", "key": "diff_hard"}], draft["difficulty"], 200)
	diff.changed.connect(func(v): draft["difficulty"] = v)
	_row("res://assets/icons/Parents_Icon_Difficulty.png", "p_difficulty", "p_difficulty_sub").add_control(diff)
	_row_controls.append(diff.buttons)
	controls["difficulty"] = diff

	# Sitzungsdauer
	var dur := OptionGroup.make([
		{"value": 15, "key": Localization.t("minutes_short", {"n": 15}), "no_translate": true},
		{"value": 30, "key": Localization.t("minutes_short", {"n": 30}), "no_translate": true},
		{"value": 45, "key": Localization.t("minutes_short", {"n": 45}), "no_translate": true}],
		draft["session_minutes"], 180)
	dur.changed.connect(func(v): draft["session_minutes"] = v)
	_row("res://assets/icons/Parents_Icon_Duration.png", "p_duration", "p_duration_sub").add_control(dur)
	_row_controls.append(dur.buttons)
	controls["duration"] = dur

	# Hilfesprache
	var hl := OptionGroup.make([
		{"value": "de", "key": "lang_de", "icon": UiSkin.flag("de")},
		{"value": "ru", "key": "lang_ru", "icon": UiSkin.flag("ru")}], draft["help_language"], 240)
	hl.changed.connect(func(v): draft["help_language"] = v)
	_row("res://assets/icons/Parents_Icon_Language.png", "p_help_lang", "p_help_lang_sub").add_control(hl)
	_row_controls.append(hl.buttons)
	controls["help_language"] = hl

	# PIN ändern
	var pin_b := PillButton.make("p_pin_button", "light", null, true)
	pin_b.name = "ChangePin"
	_row("res://assets/icons/Parents_Icon_PIN.png", "p_pin", "p_pin_sub", "row_purple").add_control(pin_b)
	pin_b.pressed.connect(func(): main.push("pin", {"mode": "change"}))
	_row_controls.append([pin_b])
	controls["pin"] = pin_b

	# Fortschritt zurücksetzen
	var reset_b := PillButton.make("p_reset_button", "red", null, true)
	reset_b.name = "ResetProgress"
	_row("res://assets/icons/Parents_Icon_Reset.png", "p_reset", "p_reset_sub", "row_gold").add_control(reset_b)
	reset_b.pressed.connect(_request_reset)
	_row_controls.append([reset_b])
	controls["reset"] = reset_b

	# Daten sichern – not available in v0.1 (no fake backup)
	var bk := PillButton.make("later", "gray", null, true)
	bk.disabled = true
	bk.focus_mode = Control.FOCUS_NONE
	var bkr := _row("res://assets/icons/Parents_Icon_Backup.png", "p_backup", "p_backup_sub")
	bkr.add_control(bk)
	bkr.show_later_badge()
	bkr.name = "BackupRow"
	bkr.make_focusable()
	_row_controls.append([bkr])

	# App-Version
	var ver := Label.new()
	ver.theme_type_variation = &"HeadingLabel"
	ver.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	ver.text = AppState.app_version()
	ver.name = "VersionLabel"
	var vr := _row("res://assets/icons/Parents_Icon_Info.png", "p_version", "p_version_sub")
	vr.add_control(ver)
	vr.name = "VersionRow"
	var diag := PillButton.make("diag_button", "light", null, true)
	diag.name = "DiagnoseButton"
	vr.add_control(diag)
	diag.pressed.connect(func(): main.push("diagnostics"))
	_row_controls.append([diag])
	controls["diagnostics"] = diag


func _link() -> void:
	var n := _row_controls.size()
	for i in n:
		var row: Array = _row_controls[i]
		var up: Control = _row_controls[i - 1][0] if i > 0 else null
		var down: Control = _row_controls[i + 1][0] if i < n - 1 else save_button
		for c in row:
			FocusManager.set_one(c, SIDE_TOP, up if up else c)
			FocusManager.set_one(c, SIDE_BOTTOM, down)
		FocusManager.set_one(row[0], SIDE_LEFT, row[0])
		FocusManager.set_one(row.back(), SIDE_RIGHT, row.back())
	var last: Control = _row_controls[n - 1][0]
	FocusManager.set_neighbors(back_button, null, cancel_button, last, null)
	FocusManager.set_neighbors(cancel_button, back_button, save_button, last, null)
	FocusManager.set_neighbors(save_button, cancel_button, null, last, null)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_profile()
		_update_letters()
		_update_week()
		_update_hard()


func _update_profile() -> void:
	var sub: Label = _profile_row.find_child("ProfileSub", true, false)
	if sub == null:
		return
	var n: String = draft["child_name"]
	sub.text = tr("p_profile_noname") if n == "" else Localization.t("p_profile_named", {"name": n})


func _update_letters() -> void:
	var l: Label = find_child("LettersSub", true, false)
	if l:
		l.text = Localization.t("p_letters_sub", {
			"secure": ProgressRepository.letters_with_status("secure").size(),
			"practice": ProgressRepository.letters_with_status("practice").size()})


func on_shown() -> void:
	_update_letters()
	_update_week()
	_update_hard()


## Up to 3 topics with tasks that went wrong and were not yet practised again,
## e.g. "Subtraktion bis 10: 7 − 3, 9 − 6 · Anlaute: Löwe".
func _update_hard() -> void:
	var l: Label = find_child("HardSub", true, false)
	if l == null:
		return
	var parts: Array = []
	for e in ProgressRepository.mistake_overview().slice(0, 3):
		var ex: String = e["exercise"]
		var examples: Array = []
		for t in e["tasks"]:
			var d := MathExerciseInfo.describe(t)
			if d != "" and not d in examples:
				examples.append(d)
		var what := ", ".join(examples.slice(0, 3)) if not examples.is_empty() \
			else Localization.t("p_hard_count", {"n": (e["tasks"] as Array).size()})
		parts.append("%s: %s" % [tr(MathExerciseInfo.title_key(ex)), what])
	l.text = tr("p_hard_none") if parts.is_empty() else " · ".join(parts)


## Last 7 days: minutes, number of exercises, strongest / weakest topic (by first-try accuracy).
func _update_week() -> void:
	var l: Label = find_child("WeekSub", true, false)
	if l == null:
		return
	var since := int(Time.get_unix_time_from_system()) - 7 * 86400
	var secs := 0
	var n := 0
	var acc := {}      # topic key -> [correct, total]
	for r in ProgressRepository.get_records():
		if r.timestamp < since:
			continue
		n += 1
		secs += r.duration_seconds
		var k := Curriculum.topic_key(r.subject_id, r.topic_id)
		var v: Array = acc.get(k, [0, 0])
		acc[k] = [v[0] + r.correct_count, v[1] + r.total_count]
	if n == 0:
		l.text = tr("p_week_none")
		return
	var keys := acc.keys().filter(func(k): return acc[k][1] > 0)
	keys.sort_custom(func(x, y): return float(acc[x][0]) / acc[x][1] > float(acc[y][0]) / acc[y][1])
	var mins := maxi(1, int(round(secs / 60.0)))
	if keys.size() >= 2:
		l.text = Localization.t("p_week_sub", {"min": mins, "n": n, "best": tr(keys[0]), "weak": tr(keys[-1])})
	else:
		l.text = Localization.t("p_week_sub_one", {"min": mins, "n": n, "best": tr(keys[0]) if not keys.is_empty() else ""})


func _edit_name() -> void:
	var p := NamePopup.new()
	p.initial = draft["child_name"]
	p.submitted.connect(func(n: String):
		draft["child_name"] = n.substr(0, SettingsRepository.MAX_NAME_LENGTH)
		_update_profile())
	main.overlay().add_child(p)


func _toggle_subject(sid: String) -> void:
	var on: bool = not draft["subjects"][sid]
	if not on:
		var active := 0
		for k in draft["subjects"]:
			if draft["subjects"][k]:
				active += 1
		if active <= 1:
			Sfx.play("error")
			toast(tr("p_subjects_min"))
			return
	draft["subjects"][sid] = on
	subject_chips[sid].selected = on


# --------------------------------------------------------- reset progress ---

func _request_reset() -> void:
	# Step 1: PIN again. Step 2: explicit confirmation (default = cancel).
	main.push("pin", {"mode": "reauth", "on_success": _confirm_reset})


func _confirm_reset() -> void:
	var n := ProgressRepository.record_count()
	var d := ConfirmDialog.make("p_reset_title", Localization.t("p_reset_message", {"n": n}), "p_reset_button", "red")
	d.confirmed.connect(func():
		ProgressRepository.reset_all()
		_update_letters()
		toast(tr("p_reset_done")))
	main.show_dialog(d)


# ------------------------------------------------------ save/cancel/back ---

func _save() -> void:
	if not is_dirty():
		toast(tr("p_no_changes"))
		return
	SettingsRepository.save_parent_settings(draft)
	_saved = SettingsRepository.get_parent_settings()
	draft = _saved.duplicate(true)
	toast(tr("p_saved"))


func _cancel() -> void:
	draft = _saved.duplicate(true)
	main.pop()


func _leave() -> void:
	if not is_dirty():
		Sfx.play("back")
		main.pop()
		return
	var d := ConfirmDialog.make("p_discard_title", "p_discard_message", "p_discard_confirm", "red", "p_keep_editing")
	d.confirmed.connect(func(): main.pop())
	main.show_dialog(d)
