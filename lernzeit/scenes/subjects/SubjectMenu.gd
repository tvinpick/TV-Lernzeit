extends BaseScreen
## Subject menu: topic list (left) and levels (right). Navigation skeleton only –
## every topic/level leads to the localized "not available yet" screen.

var subject_id := ""
var topic_buttons: Array[PillButton] = []
var level_buttons: Array[PillButton] = []
var back_button: PillButton
var _current_topic := 0
var _levels_box: GridContainer
var _levels_info: Label
var _levels_title: Label


func _ready() -> void:
	subject_id = params.get("subject_id", "mathematik")
	add_background("res://assets/backgrounds/progress_background_1080p.png")
	add_title(Curriculum.title_key(subject_id), Curriculum.SUBJECTS[subject_id]["icon"])

	# --- topics panel ---
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UiSkin.panel("main", 48))
	left.position = Vector2(SAFE_X, 184)
	left.size = Vector2(800, 712)
	add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 10)
	left.add_child(lv)
	var lt := Label.new()
	lt.theme_type_variation = &"HeadingLabel"
	lt.text = "topics_title"
	lv.add_child(lt)
	var i := 0
	for t in Curriculum.topics(subject_id):
		var b := PillButton.make(t["key"], "light", null, true)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.theme_type_variation = &"PillButton"
		b.name = "Topic_" + t["id"]
		b.custom_minimum_size.y = 78
		b.selected_variant = "cyan"
		b.show_check = false
		lv.add_child(b)
		b.focus_entered.connect(_on_topic_focus.bind(i))
		b.pressed.connect(_on_topic_pressed.bind(i))
		topic_buttons.append(b)
		i += 1

	# --- levels panel ---
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", UiSkin.panel("main", 48))
	right.position = Vector2(940, 184)
	right.size = Vector2(1920 - SAFE_X - 940, 712)
	add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 20)
	right.add_child(rv)
	_levels_title = Label.new()
	_levels_title.theme_type_variation = &"HeadingLabel"
	_levels_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	rv.add_child(_levels_title)
	_levels_info = Label.new()
	_levels_info.theme_type_variation = &"BodyLabel"
	_levels_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(_levels_info)
	_levels_box = GridContainer.new()
	_levels_box.columns = 2
	_levels_box.add_theme_constant_override("h_separation", 28)
	_levels_box.add_theme_constant_override("v_separation", 28)
	rv.add_child(_levels_box)
	for n in Curriculum.MATH_LEVELS:
		var lb := PillButton.make("", "blue")
		lb.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		lb.custom_minimum_size = Vector2(340, 104)
		lb.name = "Level_%d" % n
		lb.set_meta("level", n)
		_levels_box.add_child(lb)
		lb.pressed.connect(_on_level_pressed.bind(n))
		level_buttons.append(lb)

	back_button = PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back_button.name = "BackButton"
	back_button.sound = "back"
	back_button.position = Vector2(SAFE_X, 922)
	back_button.custom_minimum_size.x = 300
	add_child(back_button)
	back_button.pressed.connect(func(): main.pop())

	FocusManager.link_column(topic_buttons)
	FocusManager.set_one(topic_buttons.back(), SIDE_BOTTOM, back_button)
	FocusManager.set_neighbors(back_button, null, null, topic_buttons.back(), null)
	# levels grid 2×2
	var lb0 := level_buttons
	FocusManager.set_neighbors(lb0[0], null, lb0[1], null, lb0[2])
	FocusManager.set_neighbors(lb0[1], lb0[0], null, null, lb0[3])
	FocusManager.set_neighbors(lb0[2], null, lb0[3], lb0[0], null)
	FocusManager.set_neighbors(lb0[3], lb0[2], null, lb0[1], null)
	_show_topic(0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_show_topic(_current_topic)


func get_default_focus() -> Control:
	return topic_buttons[_current_topic]


func _topic(i: int) -> Dictionary:
	return Curriculum.topics(subject_id)[i]


func _on_topic_focus(i: int) -> void:
	_show_topic(i)


func _show_topic(i: int) -> void:
	_current_topic = i
	var t := _topic(i)
	var has_levels: bool = not (t["levels"] as Array).is_empty()
	_levels_title.text = tr(t["key"])
	_levels_box.visible = has_levels
	_levels_info.text = tr("levels_hint") if has_levels else tr("levels_none")
	for lb in level_buttons:
		lb.text = Localization.t("level_bis", {"n": lb.get_meta("level")})
	# Right / Left links between topic list and levels
	for b in topic_buttons:
		FocusManager.set_one(b, SIDE_RIGHT, level_buttons[0] if has_levels and b == topic_buttons[i] else b)
	for lb in [level_buttons[0], level_buttons[2]]:
		FocusManager.set_one(lb, SIDE_LEFT, topic_buttons[i])
	for b in topic_buttons:
		b.selected = b == topic_buttons[i]


func _on_topic_pressed(i: int) -> void:
	var t := _topic(i)
	if (t["levels"] as Array).is_empty():
		main.push("unavailable", {"subject_id": subject_id, "topic_id": t["id"]})
	else:
		level_buttons[0].grab_focus()


func _on_level_pressed(n: int) -> void:
	var tid: String = _topic(_current_topic)["id"]
	var ex := Curriculum.exercise_for(subject_id, tid, n)
	if ex != "":
		main.push(ex)
	else:
		main.push("unavailable", {"subject_id": subject_id, "topic_id": tid, "level": n})


func handle_back() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	if f in level_buttons:
		Sfx.play("back")
		topic_buttons[_current_topic].grab_focus()
		return true
	return false
