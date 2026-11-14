class_name LernTest
extends RefCounted
## "Lernkontrolle": started by the parents (parents area), 12 mixed tasks from all
## topics of one subject. One answer per task, no tips, no "So geht's", no repetition,
## no timer; the question is still read aloud. Result per topic: sicher / fast / noch üben.
## Saved in progress.json ("tests"); wrong tasks also go into the task history,
## so they come back in the normal exercises.

## subject -> [[exercise id, topic, mode, count], …]  (12 tasks)
const PLAN := {
	"mathematik": [["count20", "zaehlen", "", 1], ["add10", "addition", "", 2], ["add20", "addition", "", 1],
		["sub10", "subtraktion", "", 2], ["sub20", "subtraktion", "", 1], ["cmp10", "vergleichen", "", 1],
		["zr20", "zahlenreihen", "zr_step", 2], ["ta10", "textaufgaben", "ta_task", 2]],
	"deutsch": [["de_letters", "buchstaben", "de_find", 3], ["de_case", "gross_klein", "de_case", 3],
		["de_anlaute", "anlaute", "de_first", 3], ["de_woerter", "woerter", "de_missing", 2], ["de_woerter", "woerter", "de_build", 1]],
	"lesen": [["le_silben", "silben", "le_syllables", 3], ["le_woerter", "woerter", "le_word_pic", 2],
		["le_woerter", "woerter", "le_pic_word", 2], ["le_saetze", "saetze", "le_satz", 3], ["le_texte", "texte", "le_text", 2]],
	"logik": [["lg_muster", "muster", "lg_muster", 4], ["lg_formen", "formen", "lg_formen", 4],
		["lg_reihenfolge", "reihenfolge", "lg_reihenfolge", 4]],
}


static func screen_for(subject: String) -> String:
	return "exercise" if subject == "mathematik" else "exercise_de"


## Exercise id whose look (background, colours) the test screen uses.
static func look_exercise(subject: String) -> String:
	return PLAN[subject][0][0]


static func _generator(ex: String, mode: String, seed_value: int) -> MathGenerator:
	var g: MathGenerator
	if ex.begins_with("le_"):
		g = ReadingGenerator.new(seed_value)
	elif ex.begins_with("lg_"):
		g = LogikGenerator.new(seed_value)
	elif ex.begins_with("de_"):
		g = LetterGenerator.new(seed_value)
	else:
		match ex.trim_suffix("10").trim_suffix("20"):
			"add": g = AdditionGenerator.new(seed_value)
			"count": g = CountingGenerator.new(seed_value)
			"cmp": g = CompareGenerator.new(seed_value)
			"zr": g = ZahlenreihenGenerator.new(seed_value)
			"ta": g = TextaufgabenGenerator.new(seed_value)
			_: g = SubtractionGenerator.new(seed_value)
		g.max_value = 20 if ex.ends_with("20") else 10
	if mode != "" and "allowed_modes" in g:
		g.allowed_modes = [mode]
	return g


## The 12 tasks, each tagged with "topic" and "ex" (shuffled, no duplicates).
static func build(subject: String, difficulty: String, seed_value: int = -1) -> Array:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var tasks: Array = []
	var seen := {}
	for p in PLAN[subject]:
		var g := _generator(p[0], p[2], rng.randi())
		g.difficulty = difficulty
		var modes: Array = g.modes()
		for i in int(p[3]):
			var t := {}
			for attempt in 40:
				t = g.make_task(modes[(i + attempt) % modes.size()] if p[2] == "" else p[2])
				if not seen.has(t["key"]):
					break
			seen[t["key"]] = true
			t["topic"] = p[1]
			t["ex"] = p[0]
			tasks.append(t)
	for i in range(tasks.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = tasks[i]
		tasks[i] = tasks[j]
		tasks[j] = tmp
	return tasks


## "secure" (≥ 80 %), "almost" (≥ 50 %) or "practice".
static func status(right: int, total: int) -> String:
	if total <= 0:
		return "practice"
	var r := float(right) / total
	return "secure" if r >= 0.8 else ("almost" if r >= 0.5 else "practice")


const STATUS_COLOR := {"secure": Color("2fae3a"), "almost": Color("e0a400"), "practice": Color("f07a1a")}


## results: [{task, ok}] in the order answered. Saves the test and the task history.
static func save(subject: String, results: Array, seconds: int) -> Dictionary:
	var topics := {}
	var by_ex := {}
	var right := 0
	for r in results:
		var t: Dictionary = r["task"]
		var v: Array = topics.get(t["topic"], [0, 0])
		topics[t["topic"]] = [v[0] + (1 if r["ok"] else 0), v[1] + 1]
		right += 1 if r["ok"] else 0
		var list: Array = by_ex.get(t["ex"], [])
		list.append(r)
		by_ex[t["ex"]] = list
	var rec := {"ts": int(Time.get_unix_time_from_system()), "subject": subject, "correct": right,
		"total": results.size(), "secs": seconds, "topics": topics}
	ProgressRepository.add_test(rec)
	for ex in by_ex:
		ProgressRepository.remember_session(ex, by_ex[ex])
	return rec


## Results panel for the overlay: title, one row per topic, back button. Returns the button.
static func build_results(root: Control, rec: Dictionary, ink: Color) -> PillButton:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.97)
	sb.set_corner_radius_all(48)
	sb.content_margin_left = 70
	sb.content_margin_right = 70
	sb.content_margin_top = 40
	sb.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(1000, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)
	var title := Label.new()
	title.theme_type_variation = &"HeadingLabel"
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", ink)
	title.text = "test_done"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sum := Label.new()
	sum.theme_type_variation = &"BodyLabel"
	sum.add_theme_color_override("font_color", ink)
	sum.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	sum.text = Localization.t("test_summary", {"n": rec["correct"], "total": rec["total"]})
	sum.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sum)
	var grid := GridContainer.new()
	grid.name = "TopicRows"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(grid)
	for topic in rec["topics"]:
		var tv: Array = rec["topics"][topic]
		var st := status(tv[0], tv[1])
		var n := Label.new()
		n.theme_type_variation = &"RowTitle"
		n.add_theme_color_override("font_color", ink)
		n.text = Curriculum.topic_key(rec["subject"], topic)
		grid.add_child(n)
		var c := Label.new()
		c.theme_type_variation = &"BodyLabel"
		c.add_theme_color_override("font_color", ink)
		c.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		c.text = "%d / %d" % [tv[0], tv[1]]
		grid.add_child(c)
		var chip := Label.new()
		chip.name = "Status_" + topic
		chip.theme_type_variation = &"RowTitle"
		chip.text = "test_status_" + st
		chip.set_meta("status", st)
		var cs := StyleBoxFlat.new()
		cs.bg_color = STATUS_COLOR[st]
		cs.set_corner_radius_all(20)
		cs.content_margin_left = 18
		cs.content_margin_right = 18
		chip.add_theme_stylebox_override("normal", cs)
		chip.add_theme_color_override("font_color", Color.WHITE)
		grid.add_child(chip)
	var praise := Label.new()
	praise.theme_type_variation = &"CaptionLabel"
	praise.add_theme_color_override("font_color", ink)
	praise.text = "test_praise"
	praise.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	praise.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(praise)
	var back := PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back.name = "ResultsBack"
	back.custom_minimum_size.x = 340
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.sound = "back"
	v.add_child(back)
	FocusManager.set_neighbors(back)
	return back


## Short text for the parents' area: "13.11. Mathematik 10/12 · 10.11. Deutsch 9/12".
static func history_text(max_items: int = 3) -> String:
	var tests := ProgressRepository.get_tests()
	if tests.is_empty():
		return Localization.t("test_none")
	var parts: Array = []
	for t in tests.slice(maxi(0, tests.size() - max_items)):
		var d := Time.get_datetime_dict_from_unix_time(int(t["ts"]))
		parts.push_front("%02d.%02d. %s %d/%d" % [d.day, d.month, Localization.t(Curriculum.title_key(t["subject"])), t["correct"], t["total"]])
	return " · ".join(parts)
