extends Node
## End-to-end UI test driven by simulated remote keys (D-pad, OK, Back, digits).
## Run (needs a display, e.g. xvfb-run):
##   godot --path . res://tests/UiTest.tscn -- --lz-data-dir=/tmp/lz --shots=/tmp/shots [--phase=main|restart]
## Exit code 0 = all checks passed.

var main: Control
var shots_dir := ""
var phase := "main"
var failures := 0
var checks := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): shots_dir = a.trim_prefix("--shots=")
		if a.begins_with("--phase="): phase = a.trim_prefix("--phase=")
	if shots_dir != "":
		DirAccess.make_dir_recursive_absolute(shots_dir)
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await wait(0.6)
	if phase == "restart":
		await run_restart_checks()
	elif phase == "shots4k":
		await run_4k_shots()
	else:
		await run_main()
	print("UI TEST: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)


# ----------------------------------------------------------------- helpers ---

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func key(k: Key, sec: float = 0.22) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	var r := e.duplicate()
	r.pressed = false
	Input.parse_input_event(r)
	await wait(sec)


func keys(seq: Array) -> void:
	for k in seq:
		await key(k)


func android_back() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait(0.3)


func focus_name() -> String:
	var f := get_viewport().gui_get_focus_owner()
	return str(f.name) if f else "<none>"


func focus_text() -> String:
	var f := get_viewport().gui_get_focus_owner()
	if f is Button:
		return tr(f.text) if f.auto_translate_mode != Node.AUTO_TRANSLATE_MODE_DISABLED else f.text
	return ""


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  ok   ", what)
	else:
		failures += 1
		print("  FAIL ", what, "   [screen=", main.current_id(), " focus=", focus_name(), "]")


func shot(name: String) -> void:
	if shots_dir == "":
		return
	await wait(0.35)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots_dir.path_join(name + ".png"))


func goto_home() -> void:
	var guard := 0
	while main.current_id() != "home" and guard < 8:
		if main.has_dialog():
			await key(KEY_ESCAPE)
		await key(KEY_ESCAPE, 0.3)
		guard += 1


# --------------------------------------------------------------- scenarios ---

func run_main() -> void:
	print("T05 first start language / T02 home")
	check(Localization.current == "de", "German is the default language")
	check(main.current_id() == "home", "app starts on Home")
	check(focus_name() == "Card_mathematik", "initial focus on Mathematik")
	check(tr("home_prompt") == "Was möchtest du heute üben?", "home prompt in German")
	await shot("01_home_de")

	print("T03 D-pad on Home")
	await key(KEY_RIGHT); check(focus_name() == "Card_deutsch", "Right → Deutsch")
	await key(KEY_UP); check(focus_name() == "SettingsButton", "Up → gear")
	await key(KEY_UP); check(focus_name() == "SettingsButton", "Up at edge keeps focus")
	await key(KEY_DOWN); check(focus_name() == "Card_deutsch", "Down → Deutsch")
	await key(KEY_DOWN); check(focus_name() == "Card_logik", "Down → Logik")
	await key(KEY_RIGHT); check(focus_name() == "Card_logik", "Right at edge keeps focus")
	await key(KEY_DOWN); check(focus_name() == "ProgressButton", "Down → Mein Fortschritt")
	await key(KEY_RIGHT); check(focus_name() == "ProgressButton", "disabled 'Weiter üben' is skipped")
	await key(KEY_UP); check(focus_name() == "Card_lesen", "Up → Lesen")
	await key(KEY_LEFT); check(focus_name() == "Card_lesen", "Left at edge keeps focus")
	var cont: Button = main.current_screen().continue_button
	check(cont.disabled and cont.focus_mode == Control.FOCUS_NONE, "T10 'Weiter üben' disabled")

	print("Subject → topic → not available → back (focus restore)")
	await key(KEY_ENTER, 0.4)
	check(main.current_id() == "subject", "OK on Lesen opens subject menu")
	check(focus_name() == "Topic_silben", "first topic focused")
	await shot("02_subject_lesen_de")
	await key(KEY_DOWN); check(focus_name() == "Topic_woerter", "Down → next topic")
	await key(KEY_ENTER, 0.4)
	check(main.current_id() == "unavailable", "topic without levels → not-available screen")
	await shot("03_unavailable_de")
	await key(KEY_ESCAPE, 0.4)
	check(main.current_id() == "subject" and focus_name() == "Topic_woerter", "Back → subject, focus restored")
	await android_back()
	check(main.current_id() == "home" and focus_name() == "Card_lesen", "Android Back → Home, focus on Lesen")

	print("Mathematik levels")
	await key(KEY_UP); await key(KEY_ENTER, 0.4)
	check(main.current_id() == "subject" and focus_name() == "Topic_zaehlen", "Mathematik → Zählen")
	await key(KEY_ENTER); check(focus_name() == "Level_10", "OK on Zählen → level 'bis 10'")
	await key(KEY_RIGHT); check(focus_name() == "Level_20", "Right → 'bis 20'")
	await shot("04_subject_math_levels_de")
	await key(KEY_ENTER, 0.4)
	check(main.current_id() == "unavailable", "level → not-available screen")
	var crumb: Label = main.current_screen()._crumb
	check(crumb.text == "Mathematik › Zählen › bis 20", "breadcrumb: " + crumb.text)
	await key(KEY_ESCAPE, 0.4); check(focus_name() == "Level_20", "Back → level focus restored")
	await key(KEY_ESCAPE); check(focus_name() == "Topic_zaehlen", "Back in levels → topic list")
	await key(KEY_DOWN); await key(KEY_DOWN); await key(KEY_DOWN)
	check(focus_name() == "Topic_vergleichen", "Down ×3 → Vergleichen")
	await key(KEY_RIGHT); check(focus_name() == "Topic_vergleichen", "no levels → Right stays")
	await key(KEY_ESCAPE, 0.4); check(main.current_id() == "home" and focus_name() == "Card_mathematik", "Back → Home")

	print("T07 progress")
	await keys([KEY_DOWN, KEY_DOWN])
	check(focus_name() == "ProgressButton", "reach Mein Fortschritt")
	await key(KEY_ENTER, 0.4)
	check(main.current_id() == "progress", "progress overview opens")
	var po = main.current_screen()
	check(po.stat_tasks.value_label.text == "0", "tasks solved = 0")
	check(po.stat_correct.value_label.text == "—", "no percentage for 0/0")
	check(po.stat_topics.value_label.text == "0", "topics practiced = 0")
	check(po.achievements_button.disabled, "achievements disabled")
	await shot("05_progress_de")
	await key(KEY_DOWN); check(focus_name() == "Row_deutsch", "Down → Deutsch row")
	await key(KEY_ENTER, 0.4)
	check(main.current_id() == "progress_detail", "detail opens")
	await shot("06_progress_detail_de")
	await key(KEY_ESCAPE, 0.4)
	check(main.current_id() == "progress" and focus_name() == "Row_deutsch", "Back → overview, focus restored")
	await key(KEY_ESCAPE, 0.4)
	check(main.current_id() == "home" and focus_name() == "ProgressButton", "Back → Home")

	print("Settings / T05 Russian / T06 values")
	await keys([KEY_UP, KEY_RIGHT, KEY_UP, KEY_UP])
	check(focus_name() == "SettingsButton", "reach gear")
	await key(KEY_ENTER, 0.4)
	check(main.current_id() == "settings" and focus_name() == "Nav_general", "settings open on Allgemein")
	await shot("07_settings_de")
	await key(KEY_RIGHT); check(focus_text() == "Deutsch", "Right → language Deutsch")
	await key(KEY_RIGHT); check(focus_text() == "Русский", "Right → Русский")
	await key(KEY_ENTER, 0.4)
	check(Localization.current == "ru" and SettingsRepository.get_value("language") == "ru", "language switched to ru")
	check(tr("settings") == "Настройки", "UI strings now Russian")
	await key(KEY_DOWN)
	var st = main.current_screen()
	check(get_viewport().gui_get_focus_owner() == st.controls["sound"], "Down → sound switch")
	await key(KEY_ENTER); check(SettingsRepository.get_value("sound") == false, "sound off")
	await key(KEY_ENTER); check(SettingsRepository.get_value("sound") == true, "sound on again")
	await key(KEY_DOWN); check(get_viewport().gui_get_focus_owner() == st.controls["volume"], "Down → volume")
	await key(KEY_RIGHT); await key(KEY_RIGHT); await key(KEY_LEFT)
	check(SettingsRepository.get_value("volume") == 70, "volume 65 → 75 → 70 (5 % steps)")
	check(get_viewport().gui_get_focus_owner() == st.controls["volume"], "focus stays on slider while adjusting")
	var bus := AudioServer.get_bus_index("UI")
	check(absf(AudioServer.get_bus_volume_db(bus) - linear_to_db(0.7)) < 0.01, "UI bus volume follows slider")
	await key(KEY_DOWN); await key(KEY_ENTER)
	check(SettingsRepository.get_value("animations") == false, "animations off")
	await key(KEY_DOWN); await key(KEY_RIGHT); await key(KEY_ENTER, 0.4)
	check(SettingsRepository.get_value("text_size") == "large", "text size large")
	await key(KEY_DOWN)
	check(main.current_screen().controls["text_size"].buttons.has(get_viewport().gui_get_focus_owner()), "Down at last row stays inside the section")
	await key(KEY_LEFT); await key(KEY_LEFT)
	check(main.current_screen().controls["text_size"].buttons[0] == get_viewport().gui_get_focus_owner(), "Left at first control stays inside the section")
	check(AppState.theme.get_font_size("font_size", "BodyLabel") > 30, "theme font size increased")
	await shot("08_settings_ru_large")
	await key(KEY_ESCAPE); check(focus_name() == "Nav_general", "Back in content → nav column")
	await key(KEY_DOWN); await key(KEY_ENTER)
	await shot("09_settings_learning_ru_large")
	var ra: ToggleSwitch = main.current_screen().controls["read_aloud"]
	check(focus_name() != "" and ra.locked and not ra.button_pressed, "read aloud shown as unavailable")
	await key(KEY_ENTER); check(not ra.button_pressed, "read aloud cannot be switched on")
	await key(KEY_ESCAPE)
	await keys([KEY_DOWN, KEY_DOWN]); await shot("10_settings_data_ru_large")
	await key(KEY_DOWN); await shot("11_settings_about_ru_large")
	await key(KEY_RIGHT)
	var st2 = main.current_screen()
	var about_rows: Array = st2._rows_box.get_children()
	check(get_viewport().gui_get_focus_owner() == about_rows[0], "Über die App: rows reachable with Right")
	for i in about_rows.size() + 1:
		await key(KEY_DOWN, 0.15)
	check(get_viewport().gui_get_focus_owner() == about_rows.back(), "Down reaches the last info row")
	await wait(0.2)
	var sb: VScrollBar = st2._scroll.get_v_scroll_bar()
	check(st2._scroll.scroll_vertical >= int(sb.max_value - sb.page) - 1, "last row scrolled fully into view")
	await shot("11b_settings_about_last_row_ru_large")
	for i in about_rows.size():
		await key(KEY_UP, 0.15)
	check(st2._scroll.scroll_vertical == 0, "first row: list scrolled to the very top")
	await key(KEY_ESCAPE, 0.35)
	check(focus_name() == "Nav_about", "Back → section menu")
	await key(KEY_ESCAPE, 0.4)
	check(main.current_id() == "home", "Back → Home")
	await shot("12_home_ru_large")
	var card: FocusableCard = main.current_screen().cards["mathematik"]
	check(tr(card._title.text) == "Математика", "card title translated")

	print("T08 PIN create / verify")
	await keys([KEY_UP, KEY_RIGHT, KEY_UP, KEY_ENTER])
	await wait(0.3)
	check(main.current_id() == "settings", "settings again")
	await keys([KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN])
	check(focus_name() == "BackButton", "Down from nav → Zurück")
	await key(KEY_RIGHT); check(focus_name() == "ParentsButton", "Right → Elternbereich")
	await key(KEY_ENTER, 0.4)
	check(main.current_id() == "pin", "PIN screen")
	check(not SettingsRepository.has_pin(), "no PIN yet → create mode")
	await shot("13_pin_create_ru")
	await key(KEY_ESCAPE, 0.4)
	check(main.current_id() == "settings", "Back closes PIN without access")
	await key(KEY_ENTER, 0.4)
	# enter 2580 with the D-pad keypad (focus starts on 5)
	await keys([KEY_UP, KEY_ENTER, KEY_DOWN, KEY_ENTER, KEY_DOWN, KEY_ENTER, KEY_DOWN, KEY_ENTER])
	check(main.current_id() == "pin", "after 4 digits → confirmation step")
	await keys([KEY_2, KEY_5, KEY_8, KEY_1], )
	await wait(0.6)
	check(main.current_id() == "pin" and not SettingsRepository.has_pin(), "mismatching confirmation rejected")
	await shot("14_pin_mismatch_ru")
	await keys([KEY_2, KEY_5, KEY_8, KEY_0, KEY_2, KEY_5, KEY_8, KEY_0])
	await wait(0.8)
	check(SettingsRepository.has_pin(), "PIN stored")
	check(main.current_id() == "parents", "PIN created → Elternbereich")
	var cfg := FileAccess.get_file_as_string(SettingsRepository.path("parents.cfg"))
	check(not cfg.contains("2580"), "PIN not stored in plain text")
	await shot("15_parents_ru_large")
	await key(KEY_ESCAPE, 0.4)
	check(main.current_id() == "settings", "Back from parents (no changes) → settings")
	await key(KEY_ENTER, 0.4)
	await keys([KEY_0, KEY_0, KEY_0, KEY_0])
	await wait(0.6)
	check(main.current_id() == "pin", "wrong PIN refused")
	check(main.current_screen()._msg_l.text.contains("4"), "remaining attempts shown")
	await shot("16_pin_wrong_ru")
	await android_back()
	check(main.current_id() == "settings", "Back from PIN → settings, no bypass")

	print("Language back to German for the remaining screenshots")
	SettingsRepository.set_value("language", "de")
	SettingsRepository.set_value("text_size", "normal")
	SettingsRepository.set_value("animations", true)
	await wait(0.4)
	await key(KEY_ENTER, 0.4)
	await keys([KEY_2, KEY_5, KEY_8, KEY_0]); await wait(0.8)
	check(main.current_id() == "parents", "correct PIN → parents")
	await shot("17_parents_de")
	var pd = main.current_screen()
	await key(KEY_DOWN); check(focus_name() == "Subject_mathematik", "Down → subject chips")
	await keys([KEY_RIGHT, KEY_RIGHT, KEY_RIGHT]); check(focus_name() == "Subject_logik", "Right ×3 → Logik chip")
	await key(KEY_ENTER); check(pd.draft["subjects"]["logik"] == false, "Logik disabled in draft")
	check(SettingsRepository.is_subject_enabled("logik"), "not saved yet")
	await key(KEY_ESCAPE, 0.4)
	check(main.has_dialog(), "Back with unsaved changes asks for confirmation")
	await shot("18_parents_discard_dialog_de")
	await key(KEY_ESCAPE, 0.3)
	check(not main.has_dialog() and main.current_id() == "parents", "Back closes dialog, stays")
	# save via the Speichern button: go down to the bottom
	for i in 14:
		await key(KEY_DOWN, 0.12)
	check(focus_name() == "SaveButton", "reach Speichern (via backup + version rows)")
	await key(KEY_ENTER, 0.4)
	check(not SettingsRepository.is_subject_enabled("logik"), "saved: Logik disabled")
	print("T09 reset progress (PIN + confirmation)")
	ProgressRepository.add_record(ProgressRecord.create("mathematik", "addition", 4, 5, 120, "test"))
	check(ProgressRepository.record_count() == 1, "test record present")
	for i in 12:
		await key(KEY_UP, 0.12)
	await keys([KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN])
	check(focus_name() == "ResetProgress", "reach reset button: " + focus_name())
	await key(KEY_ENTER, 0.4)
	check(main.current_id() == "pin", "reset requires PIN")
	await keys([KEY_1, KEY_1, KEY_1, KEY_1]); await wait(0.6)
	check(main.current_id() == "pin" and ProgressRepository.record_count() == 1, "wrong PIN → nothing deleted")
	await keys([KEY_2, KEY_5, KEY_8, KEY_0]); await wait(0.8)
	check(main.current_id() == "parents" and main.has_dialog(), "PIN ok → confirmation dialog")
	check(focus_name() == "" or focus_text() == tr("cancel"), "default focus on Abbrechen")
	await shot("19_reset_confirm_de")
	await key(KEY_ENTER, 0.4)
	check(ProgressRepository.record_count() == 1, "Abbrechen keeps data")
	check(focus_name() == "ResetProgress", "focus back on reset button")
	await key(KEY_ENTER, 0.4)
	check(main.current_id() == "pin", "reset again → PIN")
	await keys([KEY_2, KEY_5, KEY_8, KEY_0]); await wait(0.8)
	check(main.has_dialog(), "confirmation dialog again")
	await key(KEY_RIGHT); check(focus_text() == tr("p_reset_button"), "Right → Zurücksetzen")
	await key(KEY_ENTER, 0.4)
	check(ProgressRepository.record_count() == 0, "confirmed reset deletes records")
	await goto_home()
	check(main.current_id() == "home", "back at Home")
	check(main.current_screen().cards["logik"].dimmed, "Logik card dimmed on Home")
	await shot("20_home_logik_hidden_de")
	await keys([KEY_DOWN, KEY_DOWN])
	check(focus_name() == "Card_logik", "focus on dimmed Logik card")
	await key(KEY_ENTER, 0.4)
	check(main.current_id() == "home", "disabled subject does not open")

	print("T04 exit confirmation")
	await key(KEY_ESCAPE, 0.4)
	check(main.has_dialog(), "Back on Home → exit dialog")
	await shot("21_exit_dialog_de")
	await key(KEY_ESCAPE, 0.4)
	check(not main.has_dialog() and main.current_id() == "home", "Back closes exit dialog, app stays")

	print("lockout after 5 wrong PINs")
	await keys([KEY_UP, KEY_RIGHT, KEY_UP, KEY_ENTER]); await wait(0.3)
	await keys([KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_RIGHT, KEY_ENTER]); await wait(0.4)
	for i in 5:
		await keys([KEY_9, KEY_9, KEY_9, KEY_9]); await wait(0.5)
	check(SettingsRepository.pin_lock_remaining() > 0, "PIN pad locked after 5 wrong attempts")
	await keys([KEY_2, KEY_5, KEY_8, KEY_0]); await wait(0.6)
	check(main.current_id() == "pin", "even the right PIN is refused while locked")
	await shot("22_pin_locked_de")
	# leave settings in a known state for the restart phase
	SettingsRepository.set_value("language", "ru")
	SettingsRepository.set_value("volume", 40)
	SettingsRepository.set_value("text_size", "large")
	SettingsRepository.set_value("sound", false)


func run_restart_checks() -> void:
	print("T06 values after restart")
	check(Localization.current == "ru", "language persisted (ru)")
	check(SettingsRepository.get_value("volume") == 40, "volume persisted")
	check(SettingsRepository.get_value("text_size") == "large", "text size persisted")
	check(SettingsRepository.get_value("sound") == false, "sound switch persisted")
	check(SettingsRepository.has_pin(), "PIN persisted")
	check(not SettingsRepository.is_subject_enabled("logik"), "subject selection persisted")
	check(main.current_screen().cards["logik"].dimmed, "Logik still dimmed")
	await shot("23_home_after_restart_ru")


func run_4k_shots() -> void:
	print("T12 4K window")
	check(get_viewport().get_visible_rect().size == Vector2(1920, 1080), "logical canvas stays 1920×1080")
	await shot("4k_01_home")
	await keys([KEY_RIGHT, KEY_UP, KEY_ENTER]); await wait(0.4)
	await shot("4k_02_settings")
	await key(KEY_ESCAPE, 0.4)
	await keys([KEY_DOWN, KEY_DOWN, KEY_ENTER]); await wait(0.4)
	await shot("4k_03_progress")
