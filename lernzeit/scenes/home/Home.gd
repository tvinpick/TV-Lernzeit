extends BaseScreen
## Home: Lernzeit logo (in the background art), localized prompt, four subject
## cards (2×2), "Mein Fortschritt", disabled "Weiter üben" and the settings gear.

var cards := {}
var progress_button: ArtButton
var continue_button: ArtButton
var gear: TextureButton
var review_button: PillButton     ## "Fehler üben": only when earlier mistakes wait
var goal_box: HBoxContainer       ## daily goal: "Heute ★★☆" (parents choose 2/3/5 or off)


func _ready() -> void:
	add_background("res://assets/backgrounds/main_background_1080p.png")
	var prompt := FitLabel.new()
	prompt.theme_type_variation = &"PromptLabel"
	prompt.text = "home_prompt"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.position = Vector2(360, 166)
	prompt.size = Vector2(1200, 76)
	add_child(prompt)

	var size_card := Vector2(720, 282)
	var pos := {
		"mathematik": Vector2(232, 262), "deutsch": Vector2(968, 262),
		"lesen": Vector2(232, 566), "logik": Vector2(968, 566),
	}
	for sid in Curriculum.SUBJECT_IDS:
		var c := FocusableCard.make(sid)
		c.position = pos[sid]
		c.size = size_card
		c.name = "Card_" + sid
		add_child(c)
		c.pressed.connect(_on_card.bind(sid))
		cards[sid] = c

	progress_button = ArtButton.make(preload("res://assets/buttons/btn_progress_icon.png"), "progress", 0.34, true)
	progress_button.name = "ProgressButton"
	progress_button.position = Vector2(404, 900)
	progress_button.size = Vector2(440, 116)
	add_child(progress_button)
	progress_button.pressed.connect(func():
		Sfx.play("select")
		main.push("progress"))

	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.55)
	sep.position = Vector2(878, 922)
	sep.size = Vector2(3, 72)
	add_child(sep)

	continue_button = ArtButton.make(preload("res://assets/buttons/btn_continue_icon.png"), "continue", 0.3, false, "continue_hint")
	continue_button.name = "ContinueButton"
	continue_button.position = Vector2(914, 900)
	continue_button.size = Vector2(450, 116)
	continue_button.disabled = true
	continue_button.focus_mode = Control.FOCUS_NONE      # enabled by _refresh() once something was practised
	add_child(continue_button)
	continue_button.pressed.connect(func():
		var ex := Curriculum.last_practised_exercise()
		if ex != "":
			Sfx.play("select")
			main.push(Curriculum.screen_for(ex), {"exercise": ex}))

	var hint := TextureRect.new()
	hint.texture = preload("res://assets/buttons/control_hint_icon.png")
	hint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hint.stretch_mode = TextureRect.STRETCH_SCALE
	hint.position = Vector2(1420, 912)
	hint.size = Vector2(380, 96)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	var hint_l := FitLabel.new()
	hint_l.theme_type_variation = &"OnDarkBody"
	hint_l.text = "ok_select"
	hint_l.position = Vector2(1420 + 380 * 0.31, 912)
	hint_l.size = Vector2(380 * 0.64, 96)
	hint_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(hint_l)

	gear = TextureButton.new()
	gear.name = "SettingsButton"
	gear.texture_normal = preload("res://assets/buttons/btn_settings_gear.png")
	gear.ignore_texture_size = true
	gear.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	gear.position = Vector2(1690, 50)
	gear.size = Vector2(124, 124)
	gear.focus_mode = Control.FOCUS_ALL
	gear.pivot_offset = gear.size / 2.0
	add_child(gear)
	gear.draw.connect(func():
		if gear.has_focus():
			UiTheme.focus_ring(52).draw(gear.get_canvas_item(), Rect2(Vector2(10, 12), Vector2(104, 104))))
	gear.focus_entered.connect(func(): gear.queue_redraw(); gear.scale = Vector2.ONE * 1.06)
	gear.focus_exited.connect(func(): gear.queue_redraw(); gear.scale = Vector2.ONE)
	gear.pressed.connect(func():
		Sfx.play("select")
		main.push("settings"))

	review_button = PillButton.make("home_review", "light", preload("res://assets/icons/Settings_Icon_Repeat.png"), true)
	review_button.name = "ReviewButton"
	review_button.position = Vector2(110, 62)
	review_button.custom_minimum_size = Vector2(0, 84)
	add_child(review_button)
	review_button.pressed.connect(func():
		var r := ProgressRepository.review_exercise()
		if r[0] != "":
			main.push(Curriculum.screen_for(r[0]), {"exercise": r[0], "review": true}))

	goal_box = HBoxContainer.new()
	goal_box.name = "GoalBox"
	goal_box.alignment = BoxContainer.ALIGNMENT_END
	goal_box.add_theme_constant_override("separation", 4)
	goal_box.position = Vector2(1300, 88)
	goal_box.size = Vector2(370, 56)
	goal_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(goal_box)

	var m: Control = cards["mathematik"]
	var d: Control = cards["deutsch"]
	var l: Control = cards["lesen"]
	var g: Control = cards["logik"]
	FocusManager.set_neighbors(m, null, d, null, l)
	FocusManager.set_neighbors(review_button, null, null, null, m)
	FocusManager.set_neighbors(d, m, gear, gear, g)
	FocusManager.set_neighbors(l, null, g, m, progress_button)
	FocusManager.set_neighbors(g, l, null, d, progress_button)
	FocusManager.set_neighbors(progress_button, null, null, l, null)
	FocusManager.set_neighbors(continue_button, progress_button, null, g, null)
	FocusManager.set_neighbors(gear, d, null, null, d)
	_refresh()


func get_default_focus() -> Control:
	return cards["mathematik"]


func on_shown() -> void:
	_refresh()


func _refresh() -> void:
	_update_goal()
	var rv := ProgressRepository.review_exercise()
	review_button.visible = rv[0] != ""
	review_button.focus_mode = Control.FOCUS_ALL if review_button.visible else Control.FOCUS_NONE
	review_button.text = Localization.t("home_review", {"n": rv[1]})
	review_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	FocusManager.set_one(cards["mathematik"], SIDE_TOP, review_button if review_button.visible else cards["mathematik"])
	for sid in cards:
		cards[sid].dimmed = not SettingsRepository.is_subject_enabled(sid)
	# "Weiter üben": continue the exercise that was practised before (only real exercises).
	var last_ex := Curriculum.last_practised_exercise()
	var can_continue := last_ex != "" and SettingsRepository.is_subject_enabled(Curriculum.subject_of(last_ex))
	continue_button.disabled = not can_continue
	continue_button.focus_mode = Control.FOCUS_ALL if can_continue else Control.FOCUS_NONE
	continue_button.modulate = Color.WHITE if can_continue else Color(0.78, 0.82, 0.92, 0.82)
	continue_button.set_subtitle(MathExerciseInfo.title_key(last_ex) if can_continue else "continue_hint")
	FocusManager.set_one(progress_button, SIDE_RIGHT, continue_button if can_continue else progress_button)


func _on_card(sid: String) -> void:
	var c: FocusableCard = cards[sid]
	c.press_feedback()
	if c.dimmed:
		toast(Localization.t("subject_disabled_toast"))
		return
	main.push("subject", {"subject_id": sid})


## Stars for today's finished exercises; a small celebration when the goal is reached (once a day).
func _update_goal() -> void:
	for c in goal_box.get_children():
		goal_box.remove_child(c)
		c.queue_free()
	var goal: int = SettingsRepository.get_parent_settings().get("daily_goal", 3)
	goal_box.visible = goal > 0
	if goal <= 0:
		return
	var done := PauseReminder.done_today()
	var l := Label.new()
	l.theme_type_variation = &"OnDarkBody"
	l.text = "goal_today"
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	goal_box.add_child(l)
	for i in goal:
		var st := TextureRect.new()
		st.texture = preload("res://assets/math/shared_ui/Object_Star_Yellow.png")
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		st.custom_minimum_size = Vector2(46, 46)
		st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if i >= done:
			st.modulate = Color(0.35, 0.4, 0.6, 0.55)
		goal_box.add_child(st)
	var today := PauseReminder.local_day(int(Time.get_unix_time_from_system()))
	if done >= goal and int(SettingsRepository.get_value("goal_day")) != today:
		SettingsRepository.set_value("goal_day", today)
		_celebrate_goal()


func _celebrate_goal() -> void:
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	Juice.burst(self, goal_box.get_global_rect().get_center(), 12, 26)
	Sfx.play("streak")
	toast(tr("goal_done"))
	Voice.say(["ex_correct_3"], false)
