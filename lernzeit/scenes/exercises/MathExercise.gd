extends BaseScreen
## Math exercise screen for the number range up to 10. params.exercise selects:
##   sub10   – Subtraktion bis 10 (SubtractionGenerator)
##   add10   – Addition bis 10    (AdditionGenerator)
##   count10 – Zählen bis 10      (CountingGenerator)
## 10 generated tasks in six representations each. Built from separate kit
## sprites; every number, prompt and label is rendered live. Remote: arrows
## choose, OK answers, Back = quit (with confirmation, answers so far are saved).

const EXERCISES := {
	"sub10": {"title": "ex_sub10_title", "topic": "subtraktion", "version": "sub10-v1",
		"bg": "res://assets/math/subtraction_10/backgrounds/Lernzeit_Subtraction_10_Background_1080p.png"},
	"add10": {"title": "ex_add10_title", "topic": "addition", "version": "add10-v1",
		"bg": "res://assets/math/addition_10/backgrounds/Lernzeit_Addition_10_Background_1080p.png"},
	"count10": {"title": "ex_count10_title", "topic": "zaehlen", "version": "count10-v1",
		"bg": "res://assets/math/subtraction_10/backgrounds/Lernzeit_Subtraction_10_Background_1080p.png"},
	"sub20": {"title": "ex_sub20_title", "topic": "subtraktion", "version": "sub20-v1", "max": 20,
		"bg": "res://assets/math/subtraction_10/backgrounds/Lernzeit_Subtraction_10_Background_1080p.png"},
	"add20": {"title": "ex_add20_title", "topic": "addition", "version": "add20-v1", "max": 20,
		"bg": "res://assets/math/addition_10/backgrounds/Lernzeit_Addition_10_Background_1080p.png"},
	"count20": {"title": "ex_count20_title", "topic": "zaehlen", "version": "count20-v1", "max": 20,
		"bg": "res://assets/math/subtraction_10/backgrounds/Lernzeit_Subtraction_10_Background_1080p.png"},
}
const PLUS := preload("res://assets/math/addition_10/ui/Addition_Plus_Blue.png")

const OBJECT_TEX := {
	"apple": preload("res://assets/math/shared_ui/Object_Apple_Red.png"),
	"balloon": preload("res://assets/math/shared_ui/Balloon_Red.png"),
	"star": preload("res://assets/math/shared_ui/Object_Star_Yellow.png"),
	"butterfly": preload("res://assets/math/shared_ui/Butterfly_Blue.png"),
	"car": preload("res://assets/math/shared_ui/Car_Blue.png"),
	"counter": preload("res://assets/math/shared_ui/Object_Counter_Blue.png"),
}
const CROSS := preload("res://assets/math/subtraction_10/icons/Subtraction_Cross_Red.png")
const MINUS := preload("res://assets/math/subtraction_10/icons/Subtraction_Minus_Red.png")
const EQUALS := preload("res://assets/math/subtraction_10/icons/Subtraction_Equals_Blue.png")
const DOT_FILLED := preload("res://assets/math/shared_ui/Progress_Dot_Filled.png")
const DOT_EMPTY := preload("res://assets/math/shared_ui/Progress_Dot_Empty.png")
const COLORS := ["yellow", "blue", "green", "purple"]

var exercise_id := "sub10"
var config: Dictionary
var session: ExerciseSession
var generator: MathGenerator
var answer_buttons: Array[AnswerButton] = []
var picture_buttons: Array[AnswerButton] = []
var back_button: PillButton
var finished := false

var _prompt: Label
var _counter: Label
var _repeat_badge: Label
var _stage: Control
var _answers_row: HBoxContainer
var _picture_grid: GridContainer
var _dots: HBoxContainer
var _feedback: TextureRect
var _feedback_label: Label
var _result_label: Label
var _number_line: NumberLineView
var _busy := false
var _results: Control


func _ready() -> void:
	exercise_id = params.get("exercise", "sub10")
	config = EXERCISES[exercise_id]
	add_background(config["bg"])
	var seed_value := int(params.get("seed", -1))
	match exercise_id.trim_suffix("10").trim_suffix("20"):
		"add": generator = AdditionGenerator.new(seed_value)
		"count": generator = CountingGenerator.new(seed_value)
		_: generator = SubtractionGenerator.new(seed_value)
	generator.max_value = config.get("max", 10)
	generator.difficulty = SettingsRepository.get_parent_settings()["difficulty"]
	session = ExerciseSession.new("mathematik", config["topic"], config["version"],
		generator.make_session(10), bool(SettingsRepository.get_value("repeat_mistakes")))
	_ach_before = Achievements.unlocked_ids()
	_build_header()
	_build_body()
	_show_task()


# ------------------------------------------------------------------ layout ---

func _white_box(radius: int, alpha: float = 0.86) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, alpha)
	sb.set_corner_radius_all(radius)
	sb.border_color = Color(1, 1, 1, 0.95)
	sb.set_border_width_all(3)
	sb.shadow_color = Color(0.1, 0.35, 0.7, 0.16)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 4)
	return sb


func _build_header() -> void:
	var bar := PanelContainer.new()
	var sb := _white_box(42, 0.82)
	sb.content_margin_left = 14
	sb.content_margin_right = 26
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", sb)
	bar.position = Vector2(SAFE_X, SAFE_Y - 8)
	bar.size = Vector2(1920 - SAFE_X * 2, 84)
	add_child(bar)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	bar.add_child(h)
	back_button = PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"), true)
	back_button.name = "BackButton"
	back_button.custom_minimum_size = Vector2(220, 72)
	back_button.sound = "back"
	back_button.pressed.connect(_request_quit)
	h.add_child(back_button)
	var ic := TextureRect.new()
	ic.texture = load(Curriculum.SUBJECTS["mathematik"]["icon"])
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(62, 62)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var subj := Label.new()
	subj.theme_type_variation = &"RowTitle"
	subj.text = "subject_mathematik"
	subj.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(subj)
	h.add_child(_spacer())
	var title := Label.new()
	title.text = config["title"]
	title.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color.WHITE)
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color("1f7be8")
	tsb.set_corner_radius_all(30)
	tsb.content_margin_left = 40
	tsb.content_margin_right = 40
	tsb.content_margin_top = 6
	tsb.content_margin_bottom = 6
	title.add_theme_stylebox_override("normal", tsb)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(title)
	h.add_child(_spacer())
	_repeat_badge = Label.new()
	_repeat_badge.theme_type_variation = &"CaptionLabel"
	_repeat_badge.text = "ex_repeat_badge"
	_repeat_badge.add_theme_color_override("font_color", Color("b0480b"))
	_repeat_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_repeat_badge)
	_counter = Label.new()
	_counter.theme_type_variation = &"RowTitle"
	_counter.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(1, 1, 1, 0.95)
	csb.border_color = Color("9fc6ff")
	csb.set_border_width_all(3)
	csb.set_corner_radius_all(28)
	csb.content_margin_left = 26
	csb.content_margin_right = 26
	csb.content_margin_top = 4
	csb.content_margin_bottom = 4
	_counter.add_theme_stylebox_override("normal", csb)
	_counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_counter)


func _spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _build_body() -> void:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", _white_box(56, 0.8))
	panel.position = Vector2(150, 232)
	panel.size = Vector2(1620, 404)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var banner := TextureRect.new()
	banner.texture = preload("res://assets/math/shared_ui/Question_Banner.png")
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_SCALE
	banner.position = Vector2(460, 150)
	banner.size = Vector2(1000, 154)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	_prompt = FitLabel.new()
	_prompt.theme_type_variation = &"HeadingLabel"
	_prompt.add_theme_font_size_override("font_size", 48)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_prompt.position = Vector2(500, 166)
	_prompt.size = Vector2(920, 118)
	add_child(_prompt)
	_stage = Control.new()
	_stage.position = Vector2(190, 318)
	_stage.size = Vector2(1540, 300)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	_answers_row = HBoxContainer.new()
	_answers_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_answers_row.add_theme_constant_override("separation", 34)
	_answers_row.position = Vector2(150, 656)
	_answers_row.size = Vector2(1620, 186)
	add_child(_answers_row)
	for i in 4:
		var b := AnswerButton.new()
		b.name = "Answer_%d" % i
		b.custom_minimum_size = Vector2(360, 180)
		b.color = COLORS[i]
		b.pressed.connect(_on_answer.bind(b))
		_answers_row.add_child(b)
		answer_buttons.append(b)
	_picture_grid = GridContainer.new()
	_picture_grid.columns = 2
	_picture_grid.add_theme_constant_override("h_separation", 34)
	_picture_grid.add_theme_constant_override("v_separation", 14)
	_picture_grid.position = Vector2(270, 648)
	_picture_grid.size = Vector2(1380, 210)
	add_child(_picture_grid)
	for i in 4:
		var b := AnswerButton.new()
		b.name = "Picture_%d" % i
		b.custom_minimum_size = Vector2(673, 92)
		b.pressed.connect(_on_answer.bind(b))
		_picture_grid.add_child(b)
		picture_buttons.append(b)

	var dots_bg := PanelContainer.new()
	var dsb := _white_box(26, 0.7)
	dsb.content_margin_left = 20
	dsb.content_margin_right = 20
	dsb.content_margin_top = 6
	dsb.content_margin_bottom = 6
	dots_bg.add_theme_stylebox_override("panel", dsb)
	var dots_row := CenterContainer.new()
	dots_row.position = Vector2(0, 868)
	dots_row.size = Vector2(1920, 54)
	dots_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dots_row)
	dots_row.add_child(dots_bg)
	_dots = HBoxContainer.new()
	_dots.add_theme_constant_override("separation", 8)
	dots_bg.add_child(_dots)
	for i in 10:
		var d := TextureRect.new()
		d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		d.custom_minimum_size = Vector2(38, 38)
		_dots.add_child(d)

	var hint := Label.new()
	hint.theme_type_variation = &"CaptionLabel"
	hint.text = "ex_hint_controls"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hsb := _white_box(26, 0.75)
	hsb.content_margin_left = 30
	hsb.content_margin_right = 30
	hsb.content_margin_top = 6
	hsb.content_margin_bottom = 6
	hint.add_theme_stylebox_override("normal", hsb)
	var hint_row := CenterContainer.new()      # centred bottom row inside the safe area
	hint_row.position = Vector2(0, 1080 - SAFE_Y - 56)
	hint_row.size = Vector2(1920, 56)
	hint_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint_row)
	hint_row.add_child(hint)

	_feedback = TextureRect.new()
	_feedback.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_feedback.stretch_mode = TextureRect.STRETCH_SCALE
	_feedback.size = Vector2(500, 175)
	_feedback.position = Vector2(960 - 250, 140)
	_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback.visible = false
	add_child(_feedback)
	_feedback_label = Label.new()
	_feedback_label.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
	_feedback_label.add_theme_font_size_override("font_size", 48)
	_feedback_label.add_theme_color_override("font_color", UiTheme.NAVY)
	_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.position = Vector2(150, 15)
	_feedback_label.size = Vector2(330, 140)
	_feedback_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_feedback.add_child(_feedback_label)


# ------------------------------------------------------------------- tasks ---

func current_task() -> Dictionary:
	return session.current()


func _show_task() -> void:
	_busy = false
	_feedback.visible = false
	_prompt.visible = true
	var t := session.current()
	_prompt.text = tr(t["prompt"])
	_counter.text = "%d / %d" % [mini(session.solved + 1, session.main_count), session.main_count]
	_repeat_badge.visible = session.is_repeat()
	for i in 10:
		(_dots.get_child(i) as TextureRect).texture = DOT_FILLED if i < session.solved else DOT_EMPTY
	for c in _stage.get_children():
		c.queue_free()
	_result_label = null
	_number_line = null
	var picture_mode: bool = t["option_style"] == "group"
	_answers_row.visible = not picture_mode
	_picture_grid.visible = picture_mode
	var opts: Array = t["options"]
	var n := opts.size()
	_picture_grid.columns = 2
	var inside: bool = t["mode"] == "cnt_more"
	_picture_grid.position = Vector2(225 if inside else 270, 330 if inside else 648)
	for i in 4:
		var pb := picture_buttons[i]
		var ab := answer_buttons[i]
		pb.visible = picture_mode and i < n
		ab.visible = (not picture_mode) and i < n
		if i >= n:
			continue
		if picture_mode:
			pb.custom_minimum_size = Vector2(700, 92) if n > 2 else Vector2(700, 250)
			pb.setup(opts[i], "blue", OBJECT_TEX[t.get("object", "star")])
		else:
			ab.custom_minimum_size = Vector2(360 if n > 2 else 440, 180)
			ab.setup(opts[i], COLORS[i] if n > 2 else ["purple", "green"][i], null,
				str(opts[i]) if t["option_style"] == "text" else "")
	match t["mode"]:
		"objects": _stage_objects(t)
		"equation": _stage_equation(t, false)
		"missing": _stage_equation(t, true)
		"number_line": _stage_number_line(t)
		"ten_frame": _stage_ten_frame(t)
		"picture": _stage_picture(t)
		"add_groups": _stage_groups(t["a"], t["b"], t["object"], PLUS)
		"add_equation": _stage_formula([t["a"], PLUS, t["b"], EQUALS, "?"])
		"add_missing": _stage_formula([t["a"], PLUS, "?", EQUALS, t["sum"]])
		"add_to_ten": _stage_frame_with_formula(t["a"], [t["a"], PLUS, "?", EQUALS, t["sum"]])
		"add_dice": _stage_dice(t["a"], t["b"], true)
		"add_choose": _stage_groups(t["a"], t["b"], "star", PLUS)
		"cnt_objects": _stage_count(t["n"], t["object"])
		"cnt_bigger": _stage_formula([t["x"], "vs", t["y"]])
		"cnt_more": pass        # the two apple groups are the answers (shown inside the panel)
		"cnt_sequence": _stage_sequence(t)
		"cnt_dice": _stage_dice(t["a"], t["b"], false)
		"cnt_to_ten": _stage_frame_with_formula(t["n"], [])
	_link_focus()
	active_buttons()[0].grab_focus.call_deferred()


func active_buttons() -> Array[AnswerButton]:
	var src := picture_buttons if session.current().get("option_style", "") == "group" else answer_buttons
	var out: Array[AnswerButton] = []
	for b in src:
		if b.visible:
			out.append(b)
	return out


func _link_focus() -> void:
	var btns := active_buttons()
	if session.current()["option_style"] == "group" and btns.size() == 4:
		FocusManager.set_neighbors(btns[0], null, btns[1], back_button, btns[2])
		FocusManager.set_neighbors(btns[1], btns[0], null, back_button, btns[3])
		FocusManager.set_neighbors(btns[2], null, btns[3], btns[0], null)
		FocusManager.set_neighbors(btns[3], btns[2], null, btns[1], null)
	else:
		FocusManager.link_row(btns)
		FocusManager.point_all(btns, SIDE_TOP, back_button)
		for b in btns:
			FocusManager.set_one(b, SIDE_BOTTOM, b)
	FocusManager.set_neighbors(back_button, null, null, null, btns[0])


func _digit(text: String, size: int = 150) -> Label:
	var l := Label.new()
	l.text = text
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UiTheme.NAVY)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _symbol(tex: Texture2D, w: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(w, w * 0.75)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r


func _centered_row(sep: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", sep)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(h)
	return h


func _stage_objects(t: Dictionary) -> void:
	var a: int = t["a"]
	var b: int = t["b"]
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(center)
	var row := GridContainer.new()          # one row up to 10 objects, two balanced rows above
	var cols := a if a <= 10 else int(ceil(a / 2.0))
	row.columns = cols
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 8)
	center.add_child(row)
	var s := minf(160.0 if a <= 10 else 128.0, (1500.0 - 10 * (cols - 1)) / cols)
	for i in a:
		var o := TextureRect.new()
		o.texture = OBJECT_TEX[t["object"]]
		o.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		o.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		o.custom_minimum_size = Vector2(s, s)
		o.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(o)
		if i >= a - b:                       # the last b objects are taken away
			o.modulate = Color(1, 1, 1, 0.75)
			var x := TextureRect.new()
			x.texture = CROSS
			x.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			x.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			x.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			o.add_child(x)


func _result_box(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("e3f1ff")
	sb.border_color = Color("8cc1ff")
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(34)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(190, 200)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_result_label = _digit(text, 140)
	p.add_child(_result_label)
	return p


func _stage_equation(t: Dictionary, missing: bool) -> void:
	var row := _centered_row(26)
	row.add_child(_digit(str(t["a"])))
	row.add_child(_symbol(MINUS, 160))
	if missing:
		row.add_child(_result_box("?"))
	else:
		row.add_child(_digit(str(t["b"])))
	row.add_child(_symbol(EQUALS, 160))
	if missing:
		row.add_child(_digit(str(t["result"])))
	else:
		row.add_child(_result_box("?"))


func _stage_number_line(t: Dictionary) -> void:
	_number_line = NumberLineView.new()
	_number_line.start = t["a"]
	_number_line.jumps = t["b"]
	_number_line.max_n = t.get("max", 10)
	_number_line.position = Vector2(20, 0)
	_number_line.size = Vector2(1500, 290)
	_number_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_number_line)


func _stage_ten_frame(t: Dictionary) -> void:
	var row := _centered_row(30)
	for f in _ten_frames(t["a"], t["b"], 122, int(t.get("max", 10)) / 10):
		row.add_child(f)


func _stage_picture(t: Dictionary) -> void:
	var row := _centered_row(26)
	row.add_child(_digit(str(t["a"]), 130))
	row.add_child(_symbol(MINUS, 140))
	row.add_child(_digit(str(t["b"]), 130))
	row.add_child(_symbol(EQUALS, 140))
	row.add_child(_result_box("?"))


func _object(tex_key: String, s: float) -> TextureRect:
	var o := TextureRect.new()
	o.texture = OBJECT_TEX[tex_key]
	o.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	o.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	o.custom_minimum_size = Vector2(s, s)
	o.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return o


func _group_card(n: int, tex_key: String, s: float) -> PanelContainer:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("eef6ff")
	sb.border_color = Color("8cc1ff")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(30)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", sb)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var g := GridContainer.new()
	g.columns = mini(n, 5)
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	card.add_child(g)
	for i in n:
		g.add_child(_object(tex_key, s))
	return card


## Two groups with a symbol in between (addition: count together / choose equation).
func _stage_groups(a: int, b: int, tex_key: String, symbol: Texture2D) -> void:
	var row := _centered_row(30)
	var s := 92.0 if maxi(a, b) <= 5 else 74.0
	row.add_child(_group_card(a, tex_key, s))
	row.add_child(_symbol(symbol, 130))
	row.add_child(_group_card(b, tex_key, s))


## Formula row: ints → digits, "?" → result box (revealed when solved), textures → symbols.
func _stage_formula(parts: Array) -> void:
	var row := _centered_row(26)
	for p in parts:
		if p is Texture2D:
			row.add_child(_symbol(p, 150))
		elif p is String and p == "?":
			row.add_child(_result_box("?"))
		elif p is String and p == "vs":          # comparison: neutral question mark, not an answer box
			var q := _digit("?", 120)
			q.add_theme_color_override("font_color", Color("8cb6f0"))
			q.custom_minimum_size.x = 160
			row.add_child(q)
		else:
			row.add_child(_digit(str(p)))


## Ten-frame with n counters (no crossing) and an optional small formula.
func _stage_frame_with_formula(n: int, parts: Array) -> void:
	var row := _centered_row(40)
	var t := session.current()
	var frames := int(t.get("max", 10)) / 10
	var cell := (98 if not parts.is_empty() else 122) if frames == 1 else (64 if not parts.is_empty() else 110)
	var frames_box := HBoxContainer.new()
	frames_box.add_theme_constant_override("separation", 16)
	frames_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(frames_box)
	for f in _ten_frames(n, 0, cell, frames):
		frames_box.add_child(f)
	if not parts.is_empty():
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 12)
		f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(f)
		for p in parts:
			if p is Texture2D:
				f.add_child(_symbol(p, 90))
			elif p is String and p == "?":
				var box := _result_box("?")
				box.custom_minimum_size = Vector2(130, 140)
				_result_label.add_theme_font_size_override("font_size", 96)
				f.add_child(box)
			else:
				f.add_child(_digit(str(p), 100))
	else:
		_result_label = null


## `count` ten-frames side by side; counters fill frame by frame, the last `crossed` are crossed out.
func _ten_frames(filled: int, crossed: int, cell: int, count: int) -> Array:
	var out: Array = []
	for k in count:
		out.append(_ten_frame(filled, crossed, cell, k * 10))
	return out


func _ten_frame(filled: int, crossed: int, cell: int, offset: int = 0) -> PanelContainer:
	var frame := PanelContainer.new()
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color("dbeeff")
	fsb.border_color = Color("3d8be6")
	fsb.set_border_width_all(6)
	fsb.set_corner_radius_all(22)
	fsb.content_margin_left = 10
	fsb.content_margin_right = 10
	fsb.content_margin_top = 10
	fsb.content_margin_bottom = 10
	frame.add_theme_stylebox_override("panel", fsb)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	frame.add_child(grid)
	for i in 10:
		var c := PanelContainer.new()
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color(1, 1, 1, 0.95)
		csb.border_color = Color("8cc1ff")
		csb.set_border_width_all(3)
		csb.set_corner_radius_all(14)
		c.add_theme_stylebox_override("panel", csb)
		c.custom_minimum_size = Vector2(cell, cell * 0.95)
		grid.add_child(c)
		var gi := i + offset
		if gi < filled:
			var t := TextureRect.new()
			t.texture = OBJECT_TEX["counter"]
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			c.add_child(t)
			if gi >= filled - crossed:
				t.modulate = Color(1, 1, 1, 0.7)
				var x := TextureRect.new()
				x.texture = CROSS
				x.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				x.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				c.add_child(x)
	return frame


func _stage_dice(a: int, b: int, plus: bool) -> void:
	var row := _centered_row(36)
	for i in 2:
		var d := TextureRect.new()
		d.texture = load("res://assets/math/counting_10/dice/Counting_Dice_%d.png" % [a if i == 0 else b])
		d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		d.custom_minimum_size = Vector2(220, 220)
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(d)
		if i == 0:
			row.add_child(_symbol(PLUS, 110) if plus else _spacer_fixed(40))
	if plus:
		row.add_child(_symbol(EQUALS, 110))
		row.add_child(_result_box("?"))


func _spacer_fixed(w: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 10)
	return c


## Objects to count: up to 5 per row, two rows for 6..10.
func _stage_count(n: int, tex_key: String) -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(center)
	var g := GridContainer.new()
	g.columns = n if n <= 5 else int(ceil(n / 2.0))     # balanced rows: 6 → 3+3, 7 → 4+3, 20 → 10+10
	g.add_theme_constant_override("h_separation", 26 if n <= 10 else 12)
	g.add_theme_constant_override("v_separation", 10)
	center.add_child(g)
	var sz := 150.0 if n <= 5 else (128.0 if n <= 10 else minf(128.0, (1500.0 - 12 * (g.columns - 1)) / g.columns))
	for i in n:
		g.add_child(_object(tex_key, sz))


## Number tiles in a row (forwards / backwards), one hidden behind "?".
func _stage_sequence(t: Dictionary) -> void:
	var row := _centered_row(18)
	var seq: Array = t["sequence"]
	for i in seq.size():
		var tile := PanelContainer.new()
		var hole: bool = i == t["hole"]
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("ffd27a") if hole else Color(1, 1, 1, 0.97)
		sb.border_color = Color("f29a12") if hole else Color("8cc1ff")
		sb.set_border_width_all(5)
		sb.set_corner_radius_all(28)
		sb.shadow_color = Color(0.1, 0.3, 0.7, 0.15)
		sb.shadow_size = 6
		tile.add_theme_stylebox_override("panel", sb)
		tile.custom_minimum_size = Vector2(190, 200)
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var l := _digit("?" if hole else str(seq[i]), 120)
		if hole:
			_result_label = l
		tile.add_child(l)
		row.add_child(tile)


# ----------------------------------------------------------------- answers ---

func _on_answer(btn: AnswerButton) -> void:
	if _busy or finished:
		return
	if session.submit(btn.value):
		_busy = true
		Sfx.play("select")
		btn.state = "correct"
		if _result_label:
			_result_label.text = str(btn.value)
			_result_label.add_theme_color_override("font_color", Color("2a9d3a"))
		if _number_line:
			_number_line.solved = true
		_show_feedback(true)
		for i in 10:
			(_dots.get_child(i) as TextureRect).texture = DOT_FILLED if i < session.solved else DOT_EMPTY
		await get_tree().create_timer(1.2 if AppState.animations_enabled() else 0.9).timeout
		if not is_inside_tree() or finished:
			return
		if session.advance():
			_show_task()
		else:
			_finish()
	else:
		Sfx.play("error")
		btn.state = "wrong"
		btn.shake()
		_show_feedback(false)
		# focus the nearest button that is still available
		var btns := active_buttons()
		var idx := btns.find(btn)
		for d in [1, -1, 2, -2, 3, -3]:
			var j: int = idx + d
			if j >= 0 and j < btns.size() and btns[j].state != "wrong":
				btns[j].grab_focus()
				break
		_relink_after_wrong()


## Skip disabled (wrong) buttons when moving left/right.
func _relink_after_wrong() -> void:
	var btns := active_buttons()
	var avail: Array = btns.filter(func(b): return b.state != "wrong")
	if session.current()["option_style"] != "group" or btns.size() < 4:
		FocusManager.link_row(avail)
	else:
		for b in avail:
			FocusManager.set_neighbors(b)
		FocusManager.link_row(avail)
	FocusManager.set_neighbors(back_button, null, null, null, avail[0])


func _show_feedback(ok: bool) -> void:
	_feedback.texture = preload("res://assets/math/shared_ui/Feedback_Correct.png") if ok \
		else preload("res://assets/math/shared_ui/Feedback_Wrong.png")
	_feedback_label.text = tr("ex_correct") if ok else tr("ex_wrong")
	_feedback.visible = true
	_prompt.visible = false
	if AppState.animations_enabled():
		_feedback.modulate.a = 0.0
		_feedback.scale = Vector2.ONE * 0.85
		_feedback.pivot_offset = _feedback.size / 2.0
		var tw := create_tween().set_parallel()
		tw.tween_property(_feedback, "modulate:a", 1.0, 0.12)
		tw.tween_property(_feedback, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	if not ok:
		var token := Time.get_ticks_msec()
		_feedback.set_meta("token", token)
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(_feedback) and _feedback.get_meta("token", 0) == token and not _busy:
			_feedback.visible = false
			_prompt.visible = true


# ----------------------------------------------------------------- results ---

var _ach_before: Array = []


func _show_new_achievements() -> void:
	for id in Achievements.unlocked_ids():
		if not id in _ach_before:
			toast(Localization.t("ach_new", {"name": tr(Achievements.title_key(id))}))
			Sfx.play("toggle")
			return


func _save() -> void:
	if session.solved > 0 and not has_meta("saved"):
		set_meta("saved", true)
		ProgressRepository.add_record(session.to_record())


func _finish() -> void:
	finished = true
	_save()
	_results = Control.new()
	_results.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_results)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.08, 0.25, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_results.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_results.add_child(center)
	var panel := PanelContainer.new()
	var sb := _white_box(56, 0.96)
	sb.content_margin_left = 70
	sb.content_margin_right = 70
	sb.content_margin_top = 44
	sb.content_margin_bottom = 44
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(1000, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 24)
	panel.add_child(v)
	var t := Label.new()
	t.theme_type_variation = &"HeadingLabel"
	t.add_theme_font_size_override("font_size", 64)
	t.text = "ex_done_title"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 6)
	v.add_child(stars)
	for i in session.main_count:     # one star per task solved on the first try, faint for the rest
		var s := TextureRect.new()
		s.texture = OBJECT_TEX["star"]
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		s.custom_minimum_size = Vector2(70, 70)
		if i >= session.first_try_correct:
			s.modulate = Color(0.5, 0.55, 0.7, 0.35)
		stars.add_child(s)
	var msg := Label.new()
	msg.theme_type_variation = &"BodyLabel"
	msg.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	msg.text = Localization.t("ex_done_text", {"n": session.first_try_correct, "total": session.main_count})
	if session.tasks.size() > session.main_count:
		msg.text += "\n" + tr("ex_done_repeat")
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(msg)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 40)
	v.add_child(h)
	var back := PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back.name = "ResultsBack"
	back.custom_minimum_size.x = 320
	back.sound = "back"
	back.pressed.connect(func(): main.pop())
	h.add_child(back)
	var again := PillButton.make("ex_again", "blue", preload("res://assets/icons/Settings_Icon_Repeat.png"))
	again.name = "ResultsAgain"
	again.custom_minimum_size.x = 360
	again.pressed.connect(func(): main.replace("exercise", {"exercise": exercise_id}))
	_show_new_achievements()
	h.add_child(again)
	FocusManager.set_neighbors(back, null, again)
	FocusManager.set_neighbors(again, back, null)
	for b in answer_buttons + picture_buttons + [back_button]:
		b.focus_mode = Control.FOCUS_NONE
	again.grab_focus.call_deferred()


func get_default_focus() -> Control:
	if finished:
		return _results.find_child("ResultsAgain", true, false)
	return active_buttons()[0]


func handle_back() -> bool:
	if finished:
		return false
	if session.attempts == 0:
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
