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
	"le_silben": {"title": "ex_le_silben_title", "topic": "silben", "modes": ["le_syllables"], "subject": "lesen"},
	"le_woerter": {"title": "ex_le_woerter_title", "topic": "woerter", "modes": ["le_word_pic", "le_pic_word", "le_syllables"], "subject": "lesen"},
	"lg_muster": {"title": "ex_lg_muster_title", "topic": "muster", "modes": ["lg_muster"], "subject": "logik"},
	"lg_formen": {"title": "ex_lg_formen_title", "topic": "formen", "modes": ["lg_formen"], "subject": "logik"},
	"lg_reihenfolge": {"title": "ex_lg_reihenfolge_title", "topic": "reihenfolge", "modes": ["lg_reihenfolge"], "subject": "logik"},
}
const BG := "res://assets/deutsch/backgrounds/Deutsch_Buchstaben_Background_1080p.png"
var INK := Color("2c1a6e")        ## text colour (dark brown in Logik)
var DOT := {}
var SLOT := {}

var exercise_id := "de_letters"
var config: Dictionary
var generator: MathGenerator       ## LetterGenerator (Deutsch) or ReadingGenerator (Lesen)
var subject := "deutsch"
var pic_buttons: Array[PictureButton] = []
var _pics_row: HBoxContainer
var session: ExerciseSession
var letter_buttons: Array[LetterButton] = []
var tile_buttons: Array[LetterButton] = []
var back_button: PillButton
var listen_button: PillButton     ## "Anhören": the question once more (only with the voice on)
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
var _word_reveal: Label         ## de_first: the whole word appears under the picture when solved
var _hole_pic: TextureRect      ## Logik: the "?" place that shows the chosen picture when solved
var _pattern_items: Array = []  ## Muster: the pictures of the row (first repetition pulses as help)
var _slots: Array = []          ## [{rect, label}] while building a word
var _placed := 0
var _build_wrong := {}          ## letters that were expected when a wrong tile was chosen
var _streak := 0
var _mistakes := 0
var adaptive: AdaptiveLevel



## Tasks of this session. params.review ("Fehler üben" on Home): the earlier mistakes
## of this exercise (at least 5 tasks, filled up with new ones).
func _make_tasks() -> Array:
	var again := ProgressRepository.mistake_tasks(exercise_id)
	var recent := ProgressRepository.recent_task_keys(exercise_id)
	if params.get("review", false) and not again.is_empty():
		var n := clampi(again.size(), 5, generator.session_size(10))
		return generator.make_session(n, recent, again, n)
	return generator.make_session(generator.session_size(10), recent, again)

func _ready() -> void:
	exercise_id = params.get("exercise", "de_letters")
	config = EXERCISES[exercise_id]
	subject = config.get("subject", "deutsch")
	if subject == "logik":
		INK = Color("5a2a00")
	DOT = {"done": _ui("res://assets/deutsch/ui/progress/Deutsch_Progress_Dot_Done.png"),
		"current": _ui("res://assets/deutsch/ui/progress/Deutsch_Progress_Dot_Current.png"),
		"pending": _ui("res://assets/deutsch/ui/progress/Deutsch_Progress_Dot_Pending.png")}
	SLOT = {"blank": _ui("res://assets/deutsch/ui/word_tiles/Deutsch_Word_Slot_Blank.png"),
		"filled": _ui("res://assets/deutsch/ui/word_tiles/Deutsch_Word_Slot_Filled.png"),
		"selected": _ui("res://assets/deutsch/ui/word_tiles/Deutsch_Word_Slot_Selected.png")}
	add_background(_ui(BG).resource_path)
	if subject == "lesen":
		generator = ReadingGenerator.new(int(params.get("seed", -1)))
	elif subject == "logik":
		generator = LogikGenerator.new(int(params.get("seed", -1)))
	else:
		generator = LetterGenerator.new(int(params.get("seed", -1)))
	generator.allowed_modes = config["modes"]
	generator.difficulty = SettingsRepository.get_parent_settings()["difficulty"]
	adaptive = AdaptiveLevel.new(generator.difficulty)
	session = ExerciseSession.new(subject, config["topic"], {"lesen": "lesen-v1", "logik": "logik-v1"}.get(subject, "de-letters-v1"),
		_make_tasks(), bool(SettingsRepository.get_value("repeat_mistakes")))
	_ach_before = Achievements.unlocked_ids()
	_build_layout()
	_stickers_before = Achievements.stickers_earned()
	_owl = Mascot.make("thinking", 190, Vector2(150, 112))
	_owl.visible = false
	add_child(_owl)
	_show_task()


# ------------------------------------------------------------------ layout ---

## Logik uses the same layout in orange (assets/logik/ui, tools/make_logik_ui.py).
func _ui(path: String) -> Texture2D:
	if subject == "logik":
		var lp := "res://assets/logik/ui/" + path.get_file().replace("Deutsch_Buchstaben_", "Logik_").replace("Deutsch_", "Logik_")
		if ResourceLoader.exists(lp):
			return load(lp)
	return load(path)


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
	bar.add_theme_stylebox_override("panel", _tex_box(_ui("res://assets/deutsch/ui/panels/Deutsch_Header_Panel.png"), 50, 22))
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
	listen_button = PillButton.make("ex_listen", "purple", preload("res://assets/icons/Settings_Icon_Voice.png"), true)
	listen_button.name = "ListenButton"
	listen_button.custom_minimum_size = Vector2(0, 72)
	listen_button.sound = ""
	listen_button.pressed.connect(func(): if not finished: _speak_task(session.current(), true))
	h.add_child(listen_button)
	var ic := TextureRect.new()
	ic.texture = load(Curriculum.SUBJECTS[subject]["icon"])
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
	var csb := _tex_box(_ui("res://assets/deutsch/ui/controls/Deutsch_Progress_Counter_Blank.png"), 30, 26)
	_counter.add_theme_stylebox_override("normal", csb)
	_counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_counter)

	# content + question panel
	var content := Panel.new()
	content.add_theme_stylebox_override("panel", _tex_box(_ui("res://assets/deutsch/ui/panels/Deutsch_Content_Panel.png"), 70))
	content.position = Vector2(170, 228)
	content.size = Vector2(1580, 660)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	var q := Panel.new()
	q.add_theme_stylebox_override("panel", _tex_box(_ui("res://assets/deutsch/ui/panels/Deutsch_Question_Panel.png"), 60))
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
	_pics_row = HBoxContainer.new()
	_pics_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_pics_row.add_theme_constant_override("separation", 44)
	_pics_row.position = Vector2(170, 620)
	_pics_row.size = Vector2(1580, 250)
	add_child(_pics_row)
	for i in 4:
		var pb := PictureButton.new()
		pb.name = "Pic_%d" % i
		pb.custom_minimum_size = Vector2(240, 240)
		pb.frame = _ui("res://assets/deutsch/ui/panels/Deutsch_Picture_Frame.png")
		pb.pressed.connect(_on_letter.bind(pb))
		_pics_row.add_child(pb)
		pic_buttons.append(pb)
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
	track.add_theme_stylebox_override("panel", _tex_box(_ui("res://assets/deutsch/ui/progress/Deutsch_Progress_Track.png"), 40, 36))
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
	_prompt.set_wrapped(false)
	_owl.visible = false
	var t := session.current()
	_prompt.text = Localization.t(t["prompt"], t.get("args", {}))
	listen_button.visible = Voice.enabled() and Voice.has(t["prompt"])
	_speak_task(t)
	_counter.text = "%d / %d" % [mini(session.solved + 1, session.main_count), session.main_count]
	_repeat_badge.visible = session.is_repeat()
	_update_dots()
	for c in _stage.get_children():
		_stage.remove_child(c)
		c.queue_free()
	_hole_label = null
	_word_reveal = null
	_hole_pic = null
	_slots = []
	_placed = 0
	_build_wrong = {}
	_mistakes = 0
	_prompt.remove_theme_color_override("font_color")
	_prompt.add_theme_color_override("font_color", INK)
	var build := _is_build(t)
	var pics := _is_pics(t)
	_letters_row.visible = not build and not pics
	_tiles_row.visible = build
	_pics_row.visible = pics
	if build:
		var tiles: Array = t["tiles"]
		var syl: bool = t["mode"] == "le_syllables"
		for i in tile_buttons.size():
			tile_buttons[i].visible = i < tiles.size()
			tile_buttons[i].custom_minimum_size = Vector2(230 if syl else 160, 160)
			if i < tiles.size():
				tile_buttons[i].setup(tiles[i], "tile")
	elif pics:
		for i in 4:
			pic_buttons[i].setup(t["options"][i], t["pictures"][i])
	else:
		for i in 4:
			letter_buttons[i].word_mode = t["mode"] == "le_pic_word"
			letter_buttons[i].setup(t["options"][i], "button")
	match t["mode"]:
		"de_find": _stage_big_letter(t["letter"])
		"de_case": _stage_big_letter(t["shown"])
		"de_first": _stage_first_letter(t)
		"de_missing": _stage_word(t, false)
		"de_build", "le_syllables": _stage_word(t, true)
		"le_word_pic": _stage_big_letter(t["word"], 200)
		"le_pic_word": _stage_picture(t["picture"], 300)
		"lg_formen": _stage_picture(t["show"], 250)
		"lg_muster": _stage_pattern(t)
		"lg_reihenfolge": _stage_story(t)
	_link_focus()
	active_buttons()[0].grab_focus.call_deferred()


func _update_dots() -> void:
	for i in 10:
		_dots.get_child(i).visible = i < session.main_count      # shorter sessions in small topics
		var tex: Texture2D = DOT["done"] if i < session.solved else (DOT["current"] if i == session.solved and not finished else DOT["pending"])
		(_dots.get_child(i) as TextureRect).texture = tex


func active_buttons() -> Array:
	var out: Array = []
	var t := session.current()
	var src: Array = tile_buttons if _is_build(t) else (pic_buttons if _is_pics(t) else letter_buttons)
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
	_link_header(btns[0] if not btns.is_empty() else null)


## Header: Back ↔ "Anhören"; Down goes to the first answer.
func _link_header(first: Control) -> void:
	var listen: Control = listen_button if listen_button.visible else null
	FocusManager.set_neighbors(back_button, null, listen, null, first)
	if listen:
		FocusManager.set_neighbors(listen_button, back_button, null, null, first)


## Tasks answered with the 4 picture buttons.
func _is_pics(t: Dictionary) -> bool:
	return t.get("mode", "") == "le_word_pic" or (t.get("mode", "") as String).begins_with("lg_")


func _is_build(t: Dictionary) -> bool:
	return t.get("mode", "") in ["de_build", "le_syllables"]


## Pieces of the word to place in order: letters (de_build) or syllables (le_syllables).
func _parts(t: Dictionary) -> Array:
	if t.has("parts"):
		return t["parts"]
	var w: String = t["word"]
	var out: Array = []
	for i in w.length():
		out.append(w.substr(i, 1))
	return out


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


func _stage_big_letter(text: String, size: int = 250) -> void:
	var l := _letter_label(text, size)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(l)


func _picture_frame(path: String, s: int) -> PanelContainer:
	var f := PanelContainer.new()
	f.add_theme_stylebox_override("panel", _tex_box(_ui("res://assets/deutsch/ui/panels/Deutsch_Picture_Frame.png"), 60, 6))
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


func _centered_row(sep: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", sep)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(row)
	return row


## The "?" place of a Logik task; shows the chosen picture once solved.
func _hole(s: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = SLOT["selected"]
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.custom_minimum_size = Vector2(s, s)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := _letter_label("?", int(s * 0.62))
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.add_child(l)
	var p := TextureRect.new()
	p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 10
	p.offset_top = 10
	p.offset_right = -10
	p.offset_bottom = -10
	p.visible = false                    # shows the chosen picture once solved
	r.add_child(p)
	_hole_pic = p
	return r


## Muster: the row of pictures in a panel, then the "?".
func _stage_pattern(t: Dictionary) -> void:
	var row := _centered_row(0)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _tex_box(_ui("res://assets/deutsch/ui/panels/Deutsch_Word_Panel.png"), 50, 30))
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(panel)
	var items := HBoxContainer.new()
	items.add_theme_constant_override("separation", 10)
	panel.add_child(items)
	var seq: Array = t["sequence"]
	var s := 150 if seq.size() >= 7 else 165
	_pattern_items = []
	for pth in seq:
		var r := TextureRect.new()
		r.texture = load(pth)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.custom_minimum_size = Vector2(s, s)
		r.pivot_offset = Vector2(s, s) / 2.0
		items.add_child(r)
		_pattern_items.append(r)
	items.add_child(_hole(s))


## Reihenfolge: three pictures with arrows; one of them is the "?".
func _stage_story(t: Dictionary) -> void:
	var row := _centered_row(22)
	var frames: Array = t["frames"]
	for i in frames.size():
		if i > 0:
			var arrow := _letter_label("→", 90)
			arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(arrow)
		if i == t["hole"]:
			row.add_child(_hole(240))
		else:
			row.add_child(_picture_frame(frames[i], 240))


## Picture with an (initially empty) word label below; the word is revealed after the answer.
func _stage_first_letter(t: Dictionary) -> void:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(v)
	var f := _picture_frame(t["picture"], 262)
	f.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(f)
	_word_reveal = _letter_label("", 60)
	_word_reveal.custom_minimum_size = Vector2(0, 72)
	_word_reveal.set_meta("word", t.get("display", (t["word"] as String).capitalize()))
	v.add_child(_word_reveal)


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
		row.add_child(_picture_frame(t["picture"], 280))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _tex_box(_ui("res://assets/deutsch/ui/panels/Deutsch_Word_Panel.png"), 50, 40))
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(panel)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 18)
	panel.add_child(slots)
	var w: String = t["word"]
	var parts := _parts(t) if build else _parts({"word": w})
	var syl: bool = t["mode"] == "le_syllables"
	for i in parts.size():
		var r := TextureRect.new()
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.custom_minimum_size = Vector2(210 if syl else 142, 150)
		var shown := ""
		if build:
			r.texture = SLOT["selected"] if i == 0 else SLOT["blank"]
		elif i == t["hole"]:
			r.texture = SLOT["selected"]
			shown = "?"
		else:
			r.texture = SLOT["filled"]
			shown = w.substr(i, 1)
		var l := _letter_label(shown, 76 if syl else 96)
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		r.add_child(l)
		slots.add_child(r)
		_slots.append({"rect": r, "label": l})
		if not build and i == t["hole"]:
			_hole_label = l


# ----------------------------------------------------------------- answers ---

## Reads the question aloud. Reading tasks (le_word_pic, le_pic_word, le_syllables)
## never say the word – the child has to read it.
func _speak_task(t: Dictionary, interrupt: bool = false) -> void:
	var clips: Array = [t["prompt"]]
	match t["mode"]:
		"de_find":
			clips.append(Voice.letter(t["letter"]))
		"de_case":
			clips.append(Voice.letter(t["shown"]))
		"de_first", "de_missing", "de_build":
			clips.append(Voice.word_from_picture(t["picture"]))
	if not Voice.say_all(clips, interrupt) and t["mode"] in ["de_first", "de_missing"]:
		Voice.say([t["prompt"]], interrupt)


## Praise after a solved task; word tasks then say the whole word.
func _speak_solved(t: Dictionary) -> void:
	var w := Voice.word_from_picture(str(t.get("picture", "")))
	if t["mode"] == "de_first" and Voice.say_all(["de_word_is", w, Voice.sound(t["answer"])]):
		return      # "Das Wort heißt … Apfel … aaa"
	if t["mode"] == "de_find" and Voice.say_all(["ex_correct", Voice.letter(t["answer"]), Voice.sound(t["answer"])]):
		return      # "Richtig! M … mmm"
	var praise := ["ex_correct", "ex_correct_2", "ex_correct_3", "ex_correct_4"].pick_random() as String
	if t["mode"] == "lg_formen" and Voice.say_all([praise, "shape_" + str(t["shape"])]):
		return      # "Super! … Dreieck"
	if t["mode"] in ["de_missing", "de_build", "le_syllables", "le_word_pic", "le_pic_word"] and Voice.say_all([praise, w]):
		return
	Voice.say_random(["ex_correct", "ex_correct_2", "ex_correct_3", "ex_correct_4"])


func _exit_tree() -> void:
	Voice.stop()


func _on_letter(btn) -> void:
	if _busy or finished:
		return
	if session.submit(btn.value):
		btn.state = "correct"
		if _word_reveal:
			_word_reveal.text = _word_reveal.get_meta("word")
			_word_reveal.add_theme_color_override("font_color", Color("1f9a3a"))
			Juice.pop(_word_reveal, 1.25)
		if _hole_pic:
			_hole_pic.texture = load(btn.value)
			_hole_pic.visible = true
			(_hole_pic.get_parent().get_child(0) as Label).text = ""
			Juice.pop(_hole_pic.get_parent(), 1.2)
		if _hole_label:
			_hole_label.text = btn.value
			_hole_label.add_theme_color_override("font_color", Color("1f9a3a"))
			Juice.pop(_hole_label.get_parent(), 1.2)
		Juice.pop(btn, 1.15)
		await _solved(btn.get_global_rect().get_center())
	else:
		Sfx.play("error")
		btn.state = "wrong"
		btn.shake()
		_show_feedback(false)
		Voice.say_random(["ex_wrong", "ex_wrong_2"])
		_focus_next_available(btn, pic_buttons if btn is PictureButton else letter_buttons)
		_mistake()


## Word building: the tile must be the next letter of the word.
func _on_tile(tile: LetterButton) -> void:
	if _busy or finished:
		return
	var w: String = session.current()["word"]
	var parts := _parts(session.current())
	if tile.value == parts[_placed]:
		Sfx.play("toggle")
		var slot: Dictionary = _slots[_placed]
		(slot["rect"] as TextureRect).texture = SLOT["filled"]
		(slot["label"] as Label).text = tile.value
		Juice.pop(slot["rect"], 1.18)
		_placed += 1
		if _placed < _slots.size():
			(_slots[_placed]["rect"] as TextureRect).texture = SLOT["selected"]
		tile.state = "used"
		if _placed == parts.size():
			session.submit(w)
			await _solved(tile.get_global_rect().get_center())
		else:
			_focus_next_available(tile, tile_buttons)
	else:
		Sfx.play("error")
		session.mark_wrong()
		_build_wrong[parts[_placed]] = true
		tile.shake()
		_show_feedback(false)
		Voice.say_random(["ex_wrong", "ex_wrong_2"])
		_mistake()


func _focus_next_available(from, src: Array) -> void:
	_link_focus()
	var idx := src.find(from)
	for d in [1, -1, 2, -2, 3, -3, 4, -4]:
		var j: int = idx + d
		if j >= 0 and j < src.size() and src[j].visible and src[j].state == "normal":
			src[j].grab_focus()
			return


## "Gelernte Buchstaben": which letters this task practised and whether they were
## right on the first try (repetitions at the end are not counted twice).
func _record_letters() -> void:
	var t := session.current()
	if session.is_repeat() or subject != "deutsch":
		return
	var ok := not session.was_wrong_this_task()
	var res := {}
	if t["mode"] == "de_build":
		var w: String = t["word"]
		for i in w.length():
			var l := w.substr(i, 1)
			res[l] = not _build_wrong.has(l)
	else:
		res[(t["answer"] as String).to_upper()] = ok
	ProgressRepository.add_letter_results(res)


func _solved(from: Vector2 = Vector2(960, 540)) -> void:
	var first_try := not session.was_wrong_this_task()
	_record_letters()
	_busy = true
	Sfx.play("select")
	_show_feedback(true)
	_speak_solved(session.current())
	Juice.burst(self, from)
	_reward_progress(from, first_try)
	await get_tree().create_timer(1.4 if AppState.animations_enabled() else 0.9).timeout
	if not is_inside_tree() or finished:
		return
	if not session.is_repeat() and adaptive.record(first_try):
		generator.difficulty = adaptive.level()
		AdaptiveLevel.regenerate(session, generator)
	if session.advance():
		_show_task()
	else:
		_finish()


func _reward_progress(from: Vector2, first_try: bool) -> void:
	var idx := session.solved - 1
	if idx >= 0 and idx < 10 and not session.is_repeat():
		for i in 10:
			(_dots.get_child(i) as TextureRect).texture = DOT["done"] if i < idx else DOT["pending"]
		var dot := _dots.get_child(idx) as TextureRect
		Juice.fly_star(self, from, dot.get_global_rect().get_center(), func():
			if is_instance_valid(dot):
				dot.texture = DOT["done"]
				Juice.pop(dot, 1.6)
				Sfx.play("pop"))
	else:
		_update_dots()
	if first_try and not session.is_repeat():
		_streak += 1
		if _streak in [3, 5, 7, 10]:
			Sfx.play("streak")
			Juice.banner(self, Localization.t("ex_streak", {"n": _streak}), Color("a23cc8"), 560)
			Voice.say(["ex_streak"], false)
	else:
		_streak = 0


## 1st mistake → tip in the question panel; 2nd → the right letter / next tile glows.
func _mistake() -> void:
	_mistakes += 1
	_streak = 0
	var t := session.current()
	if _mistakes == 1:
		await get_tree().create_timer(1.05).timeout
		if not is_inside_tree() or _busy or session.current() != t:
			return
		var tip := Localization.help("tip_" + t["mode"], {"l": t.get("letter", t.get("shown", ""))})
		_prompt.set_wrapped(true, 30)
		_prompt.text = Localization.help("ex_tip", {"t": tip})
		if Localization.help_language() == "de":
			if t["mode"] == "de_find":           # "Schau genau auf die Form von … M"
				Voice.say_all(["tip_de_find", Voice.letter(t["letter"])], false)
			else:
				Voice.say(["tip_" + t["mode"]], false)
		_owl.visible = true
		Mascot.appear(_owl)
		_prompt.add_theme_color_override("font_color", Color("c25e00"))
	else:
		_show_solution(t)
		var want: String = _parts(t)[_placed] if _is_build(t) else t["answer"]
		if t["mode"] == "de_first":
			Voice.say([Voice.word_from_picture(t["picture"]), Voice.sound(want)])   # "Apfel … aaa"
		for b in active_buttons():
			if b.value == want:
				Juice.hint_pulse(b)
				break


## 2nd mistake: "So geht's: Löwe → L" in the question panel; Muster: the repeating part pulses.
func _show_solution(t: Dictionary) -> void:
	var text := ""
	match t["mode"]:
		"de_find", "de_case":
			text = str(t["answer"])
		"de_first":
			text = "%s → %s" % [t.get("display", ""), t["answer"]]
		"de_missing":
			text = (t["word"] as String).capitalize()
			for e in LetterGenerator.dictionary():          # "FUSS" → "Fuß"
				if e["upper"] == t["word"]:
					text = e["word"]
		"lg_muster":
			for i in mini(str(t["kind"]).length(), _pattern_items.size()):
				Juice.hint_pulse(_pattern_items[i])
	if text != "":
		_prompt.set_wrapped(true, 30)
		_prompt.text = Localization.help("ex_show", {"t": text})
		_prompt.add_theme_color_override("font_color", Color("1f7a33"))


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

var _ach_before: Array = []
var _stickers_before := 0
var _owl: TextureRect          ## thinking owl next to a tip


func _show_new_achievements() -> void:
	for id in Achievements.unlocked_ids():
		if not id in _ach_before:
			toast(Localization.t("ach_new", {"name": tr(Achievements.title_key(id))}))
			Sfx.play("toggle")
			return


func _save() -> void:
	if session.solved > 0 and not has_meta("saved"):
		set_meta("saved", true)
		ProgressRepository.remember_session(exercise_id, session.task_results())
		ProgressRepository.add_record(session.to_record())


func _finish() -> void:
	finished = true
	_owl.visible = false
	_feedback.visible = false
	_prompt.visible = true
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
	panel.add_theme_stylebox_override("panel", _tex_box(_ui("res://assets/deutsch/ui/panels/Deutsch_Content_Panel.png"), 70, 70))
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
	var star_nodes: Array = []
	for i in session.main_count:
		var s := TextureRect.new()
		star_nodes.append(s)
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
	Voice.say(["ex_done_perfect" if session.first_try_correct >= session.main_count else "ex_done"], false)
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
	Juice.burst(self, Vector2(960, 300), 10, 30)
	Sfx.play("streak")
	if AppState.animations_enabled():
		for i in star_nodes.size():
			var st: Control = star_nodes[i]
			st.scale = Vector2.ZERO
			st.pivot_offset = Vector2(35, 35)
			var tw := create_tween()
			tw.tween_interval(0.25 + 0.12 * i)
			tw.tween_property(st, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ResultsDecor.add(_results, session.first_try_correct, _stickers_before)
	PauseReminder.maybe_show(self, main, 1.9)
	_show_new_achievements()
	hb.add_child(again)
	FocusManager.set_neighbors(back, null, again)
	FocusManager.set_neighbors(again, back, null)
	for b in letter_buttons + tile_buttons:
		b.focus_mode = Control.FOCUS_NONE
	for b in pic_buttons:                # picture answers stay behind the results panel
		b.focus_mode = Control.FOCUS_NONE
	back_button.focus_mode = Control.FOCUS_NONE
	listen_button.focus_mode = Control.FOCUS_NONE
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
