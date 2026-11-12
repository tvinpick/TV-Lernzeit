extends BaseScreen
## "Deutsch · Buchstaben" exercises (params.exercise):
##   de_letters – all five modes mixed      de_anlaute – first letter of a picture
##   de_woerter – missing letter + build    de_case    – uppercase / lowercase
## Built from the Deutsch kit sprites; letters, words and prompts are live text.
## No audio in this version. Remote: arrows choose, OK answers / places a tile,
## Back = quit (with confirmation; answers so far are saved).

const EXERCISES := {
	"de_letters": {"title": "ex_de_letters_title", "topic": "buchstaben", "modes": LetterGenerator.ALL_MODES},
	"de_anlaute": {"title": "ex_de_anlaute_title", "topic": "anlaute", "modes": ["de_first"]},
	"de_woerter": {"title": "ex_de_woerter_title", "topic": "woerter", "modes": ["de_missing", "de_build"]},
	"de_case": {"title": "ex_de_case_title", "topic": "gross_klein", "modes": ["de_case"]},
}
const BG := "res://assets/deutsch/backgrounds/Deutsch_Buchstaben_Background_1080p.png"
const INK := Color("2c1a6e")
const DOT := {
	"done": preload("res://assets/deutsch/ui/progress/Deutsch_Progress_Dot_Done.png"),
	"current": preload("res://assets/deutsch/ui/progress/Deutsch_Progress_Dot_Current.png"),
	"pending": preload("res://assets/deutsch/ui/progress/Deutsch_Progress_Dot_Pending.png"),
}
const SLOT := {
	"blank": preload("res://assets/deutsch/ui/word_tiles/Deutsch_Word_Slot_Blank.png"),
	"filled": preload("res://assets/deutsch/ui/word_tiles/Deutsch_Word_Slot_Filled.png"),
	"selected": preload("res://assets/deutsch/ui/word_tiles/Deutsch_Word_Slot_Selected.png"),
}

var exercise_id := "de_letters"
var config: Dictionary
var generator: LetterGenerator
var session: ExerciseSession
var letter_buttons: Array[LetterButton] = []
var tile_buttons: Array[LetterButton] = []
var back_button: PillButton
var finished := false

var _prompt: FitLabel
var _counter: Label
var _repeat_badge: Label
var _stage: Control
var _letters_row: HBoxContainer
var _tiles_row: HBoxContainer
var _dots: HBoxContainer
var _feedback: TextureRect
var _feedback_icon: TextureRect
var _feedback_label: Label
var _busy := false
var _results: Control
var _hole_label: Label
var _slots: Array = []          ## [{rect, label}] while building a word
var _placed := 0


func _ready() -> void:
	exercise_id = params.get("exercise", "de_letters")
	config = EXERCISES[exercise_id]
	add_background(BG)
	generator = LetterGenerator.new(int(params.get("seed", -1)))
	generator.allowed_modes = config["modes"]
	generator.difficulty = SettingsRepository.get_parent_settings()["difficulty"]
	session = ExerciseSession.new("deutsch", config["topic"], "de-letters-v1",
		generator.make_session(10), bool(SettingsRepository.get_value("repeat_mistakes")))
	_build_layout()
	_show_task()


# ------------------------------------------------------------------ layout ---

func _tex_box(tex: Texture2D, margin: int, content: int = 0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = content
	sb.content_margin_right = content
	sb.content_margin_top = content * 0.4
	sb.content_margin_bottom = content * 0.4
	return sb


func _build_layout() -> void:
	# header
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _tex_box(preload("res://assets/deutsch/ui/panels/Deutsch_Header_Panel.png"), 50, 22))
	bar.position = Vector2(SAFE_X, SAFE_Y - 10)
	bar.size = Vector2(1920 - SAFE_X * 2, 92)
	add_child(bar)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	bar.add_child(h)
	back_button = PillButton.make("back", "purple", preload("res://assets/icons/Settings_Icon_Back.png"), true)
	back_button.name = "BackButton"
	back_button.custom_minimum_size = Vector2(220, 72)
	back_button.sound = "back"
	back_button.pressed.connect(_request_quit)
	h.add_child(back_button)
	var ic := TextureRect.new()
	ic.texture = load(Curriculum.SUBJECTS["deutsch"]["icon"])
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(60, 60)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	h.add_child(_spacer())
	var title := Label.new()
	title.theme_type_variation = &"RowTitle"
	title.text = config["title"]
	title.add_theme_color_override("font_color", INK)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(title)
	h.add_child(_spacer())
	_repeat_badge = Label.new()
	_repeat_badge.theme_type_variation = &"CaptionLabel"
	_repeat_badge.text = "ex_repeat_badge"
	_repeat_badge.add_theme_color_override("font_color", Color("a23cc8"))
	_repeat_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_repeat_badge)
	_counter = Label.new()
	_counter.theme_type_variation = &"RowTitle"
	_counter.add_theme_color_override("font_color", INK)
	_counter.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var csb := _tex_box(preload("res://assets/deutsch/ui/controls/Deutsch_Progress_Counter_Blank.png"), 30, 26)
	_counter.add_theme_stylebox_override("normal", csb)
	_counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_counter)

	# content + question panel
	var content := Panel.new()
	content.add_theme_stylebox_override("panel", _tex_box(preload("res://assets/deutsch/ui/panels/Deutsch_Content_Panel.png"), 70))
	content.position = Vector2(170, 228)
	content.size = Vector2(1580, 660)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	var q := Panel.new()
	q.add_theme_stylebox_override("panel", _tex_box(preload("res://assets/deutsch/ui/panels/Deutsch_Question_Panel.png"), 60))
	q.position = Vector2(330, 160)
	q.size = Vector2(1260, 128)
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(q)
	_prompt = FitLabel.new()
	_prompt.theme_type_variation = &"HeadingLabel"
	_prompt.add_theme_font_size_override("font_size", 46)
	_prompt.add_theme_color_override("font_color", INK)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_prompt.position = Vector2(370, 168)
	_prompt.size = Vector2(1180, 112)
	add_child(_prompt)
	_stage = Control.new()
	_stage.position = Vector2(210, 300)
	_stage.size = Vector2(1500, 340)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	_letters_row = HBoxContainer.new()
	_letters_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_letters_row.add_theme_constant_override("separation", 40)
	_letters_row.position = Vector2(170, 662)
	_letters_row.size = Vector2(1580, 200)
	add_child(_letters_row)
	for i in 4:
		var b := LetterButton.new()
		b.name = "Letter_%d" % i
		b.custom_minimum_size = Vector2(290, 190)
		b.pressed.connect(_on_letter.bind(b))
		_letters_row.add_child(b)
		letter_buttons.append(b)
	_tiles_row = HBoxContainer.new()
	_tiles_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_tiles_row.add_theme_constant_override("separation", 30)
	_tiles_row.position = Vector2(170, 680)
	_tiles_row.size = Vector2(1580, 170)
	add_child(_tiles_row)
	for i in 5:
		var t := LetterButton.new()
		t.name = "Tile_%d" % i
		t.kind = "tile"
		t.custom_minimum_size = Vector2(160, 160)
		t.pressed.connect(_on_tile.bind(t))
		_tiles_row.add_child(t)
		tile_buttons.append(t)

	# progress track with dots
	var track_row := CenterContainer.new()
	track_row.position = Vector2(0, 1080 - SAFE_Y - 80)
	track_row.size = Vector2(1920, 80)
	track_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(track_row)
	var track := PanelContainer.new()
	track.add_theme_stylebox_override("panel", _tex_box(preload("res://assets/deutsch/ui/progress/Deutsch_Progress_Track.png"), 40, 36))
	track_row.add_child(track)
	_dots = HBoxContainer.new()
	_dots.add_theme_constant_override("separation", 10)
	track.add_child(_dots)
	for i in 10:
		var d := TextureRect.new()
		d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		d.custom_minimum_size = Vector2(46, 46)
		_dots.add_child(d)

	# feedback (shown in place of the question)
	_feedback = TextureRect.new()
	_feedback.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_feedback.stretch_mode = TextureRect.STRETCH_SCALE
	_feedback.size = Vector2(560, 120)
	_feedback.position = Vector2(960 - 280, 164)
	_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback.visible = false
	add_child(_feedback)
	_feedback_icon = TextureRect.new()
	_feedback_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_feedback_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_feedback_icon.position = Vector2(30, 18)
	_feedback_icon.size = Vector2(84, 84)
	_feedback.add_child(_feedback_icon)
	_feedback_label = Label.new()
	_feedback_label.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
	_feedback_label.add_theme_font_size_override("font_size", 50)
	_feedback_label.add_theme_color_override("font_color", Color.WHITE)
	_feedback_label.add_theme_constant_override("outline_size", 8)
	_feedback_label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.3, 0.4))
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_feedback_label.position = Vector2(120, 0)
	_feedback_label.size = Vector2(420, 120)
	_feedback_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_feedback.add_child(_feedback_label)


func _spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


# ------------------------------------------------------------------- tasks ---

func current_task() -> Dictionary:
	return session.current()


func _show_task() -> void:
	_busy = false
	_feedback.visible = false
	_prompt.visible = true
	var t := session.current()
	_prompt.text = Localization.t(t["prompt"], t.get("args", {}))
	_counter.text = "%d / %d" % [mini(session.solved + 1, session.main_count), session.main_count]
	_repeat_badge.visible = session.is_repeat()
	_update_dots()
	for c in _stage.get_children():
		c.queue_free()
	_hole_label = null
	_slots = []
	_placed = 0
	var build: bool = t["mode"] == "de_build"
	_letters_row.visible = not build
	_tiles_row.visible = build
	if build:
		var tiles: Array = t["tiles"]
		for i in tile_buttons.size():
			tile_buttons[i].visible = i < tiles.size()
			if i < tiles.size():
				tile_buttons[i].setup(tiles[i], "tile")
	else:
		for i in 4:
			letter_buttons[i].setup(t["options"][i], "button")
	match t["mode"]:
		"de_find": _stage_big_letter(t["letter"])
		"de_case": _stage_big_letter(t["shown"])
		"de_first": _stage_picture(t["picture"], 300)
		"de_missing": _stage_word(t, false)
		"de_build": _stage_word(t, true)
	_link_focus()
	active_buttons()[0].grab_focus.call_deferred()


func _update_dots() -> void:
	for i in 10:
		var tex: Texture2D = DOT["done"] if i < session.solved else (DOT["current"] if i == session.solved and not finished else DOT["pending"])
		(_dots.get_child(i) as TextureRect).texture = tex


func active_buttons() -> Array[LetterButton]:
	var out: Array[LetterButton] = []
	var src := tile_buttons if session.current().get("mode", "") == "de_build" else letter_buttons
	for b in src:
		if b.visible and b.state != "used" and b.state != "wrong":
			out.append(b)
	return out


func _link_focus() -> void:
	var btns := active_buttons()
	FocusManager.link_row(btns)
	FocusManager.point_all(btns, SIDE_TOP, back_button)
	for b in btns:
		FocusManager.set_one(b, SIDE_BOTTOM, b)
	FocusManager.set_neighbors(back_button, null, null, null, btns[0] if not btns.is_empty() else null)


func _letter_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _stage_big_letter(text: String) -> void:
	var l := _letter_label(text, 250)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(l)


func _picture_frame(path: String, s: int) -> PanelContainer:
	var f := PanelContainer.new()
	f.add_theme_stylebox_override("panel", _tex_box(preload("res://assets/deutsch/ui/panels/Deutsch_Picture_Frame.png"), 60, 22))
	f.custom_minimum_size = Vector2(s, s)
	f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var p := TextureRect.new()
	p.texture = load(path)
	p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	f.add_child(p)
	return f


func _stage_picture(path: String, s: int) -> void:
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(c)
	c.add_child(_picture_frame(path, s))


## Word as a row of slots (optional picture on the left).
## missing: one empty slot ("?"); build: all empty, filled while tiles are placed.
func _stage_word(t: Dictionary, build: bool) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(row)
	if t["picture"] != "":
		row.add_child(_picture_frame(t["picture"], 260))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _tex_box(preload("res://assets/deutsch/ui/panels/Deutsch_Word_Panel.png"), 50, 40))
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(panel)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 18)
	panel.add_child(slots)
	var w: String = t["word"]
	for i in w.length():
		var r := TextureRect.new()
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.custom_minimum_size = Vector2(142, 150)
		var shown := ""
		if build:
			r.texture = SLOT["selected"] if i == 0 else SLOT["blank"]
		elif i == t["hole"]:
			r.texture = SLOT["selected"]
			shown = "?"
		else:
			r.texture = SLOT["filled"]
			shown = w.substr(i, 1)
		var l := _letter_label(shown, 96)
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		r.add_child(l)
		slots.add_child(r)
		_slots.append({"rect": r, "label": l})
		if not build and i == t["hole"]:
			_hole_label = l


# ----------------------------------------------------------------- answers ---

func _on_letter(btn: LetterButton) -> void:
	if _busy or finished:
		return
	if session.submit(btn.value):
		btn.state = "correct"
		if _hole_label:
			_hole_label.text = btn.value
			_hole_label.add_theme_color_override("font_color", Color("1f9a3a"))
		await _solved()
	else:
		Sfx.play("error")
		btn.state = "wrong"
		btn.shake()
		_show_feedback(false)
		_focus_next_available(btn, letter_buttons)


## Word building: the tile must be the next letter of the word.
func _on_tile(tile: LetterButton) -> void:
	if _busy or finished:
		return
	var w: String = session.current()["word"]
	if tile.value == w.substr(_placed, 1):
		Sfx.play("toggle")
		var slot: Dictionary = _slots[_placed]
		(slot["rect"] as TextureRect).texture = SLOT["filled"]
		(slot["label"] as Label).text = tile.value
		_placed += 1
		if _placed < _slots.size():
			(_slots[_placed]["rect"] as TextureRect).texture = SLOT["selected"]
		tile.state = "used"
		if _placed == w.length():
			session.submit(w)
			await _solved()
		else:
			_focus_next_available(tile, tile_buttons)
	else:
		Sfx.play("error")
		session.mark_wrong()
		tile.shake()
		_show_feedback(false)


func _focus_next_available(from: LetterButton, src: Array) -> void:
	_link_focus()
	var idx := src.find(from)
	for d in [1, -1, 2, -2, 3, -3, 4, -4]:
		var j: int = idx + d
		if j >= 0 and j < src.size() and src[j].visible and src[j].state == "normal":
			src[j].grab_focus()
			return


func _solved() -> void:
	_busy = true
	Sfx.play("select")
	_show_feedback(true)
	_update_dots()
	await get_tree().create_timer(1.2 if AppState.animations_enabled() else 0.9).timeout
	if not is_inside_tree() or finished:
		return
	if session.advance():
		_show_task()
	else:
		_finish()


func _show_feedback(ok: bool) -> void:
	_feedback.texture = preload("res://assets/deutsch/ui/feedback/Deutsch_Feedback_Correct_Blank.png") if ok \
		else preload("res://assets/deutsch/ui/feedback/Deutsch_Feedback_Try_Again_Blank.png")
	_feedback_icon.texture = preload("res://assets/deutsch/ui/feedback/Deutsch_Icon_Check.png") if ok \
		else preload("res://assets/deutsch/ui/feedback/Deutsch_Icon_Cross.png")
	_feedback_label.text = tr("ex_correct") if ok else tr("ex_wrong")
	# white on the green "correct" plate, dark brown on the light orange "try again" plate (contrast)
	_feedback_label.add_theme_color_override("font_color", Color.WHITE if ok else Color("7a3300"))
	_feedback_label.add_theme_constant_override("outline_size", 8 if ok else 0)
	_feedback.visible = true
	_prompt.visible = false
	if AppState.animations_enabled():
		_feedback.modulate.a = 0.0
		create_tween().tween_property(_feedback, "modulate:a", 1.0, 0.12)
	if not ok:
		var token := Time.get_ticks_msec()
		_feedback.set_meta("token", token)
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(_feedback) and _feedback.get_meta("token", 0) == token and not _busy:
			_feedback.visible = false
			_prompt.visible = true


# ----------------------------------------------------------------- results ---

func _save() -> void:
	if session.solved > 0 and not has_meta("saved"):
		set_meta("saved", true)
		ProgressRepository.add_record(session.to_record())


func _finish() -> void:
	finished = true
	_save()
	_update_dots()
	_results = Control.new()
	_results.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_results)
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.05, 0.25, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_results.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_results.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _tex_box(preload("res://assets/deutsch/ui/panels/Deutsch_Content_Panel.png"), 70, 70))
	panel.custom_minimum_size = Vector2(1000, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 24)
	panel.add_child(v)
	var t := Label.new()
	t.theme_type_variation = &"HeadingLabel"
	t.add_theme_font_size_override("font_size", 64)
	t.add_theme_color_override("font_color", INK)
	t.text = "ex_done_title"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 6)
	v.add_child(stars)
	for i in session.main_count:
		var s := TextureRect.new()
		s.texture = preload("res://assets/math/shared_ui/Object_Star_Yellow.png")
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		s.custom_minimum_size = Vector2(70, 70)
		if i >= session.first_try_correct:
			s.modulate = Color(0.55, 0.5, 0.7, 0.35)
		stars.add_child(s)
	var msg := Label.new()
	msg.theme_type_variation = &"BodyLabel"
	msg.add_theme_color_override("font_color", INK)
	msg.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	msg.text = Localization.t("ex_done_text", {"n": session.first_try_correct, "total": session.main_count})
	if session.tasks.size() > session.main_count:
		msg.text += "\n" + tr("ex_done_repeat")
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(msg)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 40)
	v.add_child(hb)
	var back := PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back.name = "ResultsBack"
	back.custom_minimum_size.x = 320
	back.sound = "back"
	back.pressed.connect(func(): main.pop())
	hb.add_child(back)
	var again := PillButton.make("ex_again", "purple", preload("res://assets/icons/Settings_Icon_Repeat.png"))
	again.name = "ResultsAgain"
	again.custom_minimum_size.x = 360
	again.pressed.connect(func(): main.replace("exercise_de", {"exercise": exercise_id}))
	hb.add_child(again)
	FocusManager.set_neighbors(back, null, again)
	FocusManager.set_neighbors(again, back, null)
	for b in letter_buttons + tile_buttons:
		b.focus_mode = Control.FOCUS_NONE
	back_button.focus_mode = Control.FOCUS_NONE
	again.grab_focus.call_deferred()


func get_default_focus() -> Control:
	if finished:
		return _results.find_child("ResultsAgain", true, false)
	var btns := active_buttons()
	return btns[0] if not btns.is_empty() else back_button


func handle_back() -> bool:
	if finished or session.attempts == 0:
		return false
	_request_quit()
	return true


func _request_quit() -> void:
	if finished or session.attempts == 0:
		Sfx.play("back")
		main.pop()
		return
	var d := ConfirmDialog.make("ex_quit_title", "ex_quit_message", "ex_quit_confirm", "red", "continue")
	d.confirmed.connect(func():
		_save()
		main.pop())
	main.show_dialog(d)
