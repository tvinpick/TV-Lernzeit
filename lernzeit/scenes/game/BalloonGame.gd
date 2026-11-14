extends BaseScreen
## "Ballon-Spiel": a 45-second reward game, unlocked once a day after 15 minutes of
## practice (PauseReminder.game_unlocked). Balloons rise in 7 lanes; ← → move the
## needle, OK pops the lowest balloon above it. Half of the balloons carry a number or
## letter; the owl asks for one of them ("Lass alle Ballons mit 5 platzen!"):
## the right ones give 2 stars, plain balloons 1, other labels none.
## params.seconds shortens the game (tests).

const LANES := 7
const LANE_X0 := 300.0
const LANE_STEP := 220.0
const NEEDLE_Y := 950.0
const COLORS := ["Rot", "Orange", "Gelb", "Gruen", "Blau", "Lila"]
const LETTERS := ["M", "A", "O", "I", "L", "S", "E", "U", "R", "T", "N", "H"]

var lane := 3
var score := 0
var popped := 0
var target := ""             ## number or letter the owl asks for
var balloons: Array = []     ## [{node, lane, label, speed}]
var finished := false
var back_button: PillButton
var _needle: Control
var _sky: Control
var _target_l: Label
var _score_l: Label
var _time_bar: ProgressBar
var _total := 45.0
var _left := 45.0
var _spawn := 0.0
var _retarget := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_total = float(params.get("seconds", 45))
	for arg in OS.get_cmdline_user_args():          # tests: --seconds=12
		if arg.begins_with("--seconds="):
			_total = float(arg.trim_prefix("--seconds="))
	_left = _total
	add_background("res://assets/math/addition_10/backgrounds/Lernzeit_Addition_10_Background_1080p.png")
	SettingsRepository.set_value("game_day", PauseReminder.local_day(int(Time.get_unix_time_from_system())))
	_sky = Control.new()
	_sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky.clip_contents = true
	add_child(_sky)
	# header: back · target · stars · time
	var bar := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.88)
	sb.set_corner_radius_all(40)
	sb.content_margin_left = 14
	sb.content_margin_right = 26
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", sb)
	bar.position = Vector2(SAFE_X, SAFE_Y - 8)
	bar.size = Vector2(1920 - SAFE_X * 2, 84)
	add_child(bar)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	bar.add_child(h)
	back_button = PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"), true)
	back_button.name = "BackButton"
	back_button.custom_minimum_size = Vector2(220, 72)
	back_button.focus_mode = Control.FOCUS_NONE        # Back key of the remote leaves the game
	back_button.sound = "back"
	back_button.pressed.connect(func(): main.pop())
	h.add_child(back_button)
	_target_l = Label.new()
	_target_l.name = "TargetLabel"
	_target_l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_target_l.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
	_target_l.add_theme_font_size_override("font_size", 40)
	_target_l.add_theme_color_override("font_color", Color("1d2b6b"))
	_target_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_target_l)
	var star := TextureRect.new()
	star.texture = preload("res://assets/math/shared_ui/Object_Star_Yellow.png")
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.custom_minimum_size = Vector2(56, 56)
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(star)
	_score_l = Label.new()
	_score_l.name = "ScoreLabel"
	_score_l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_score_l.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
	_score_l.add_theme_font_size_override("font_size", 44)
	_score_l.add_theme_color_override("font_color", Color("c26a00"))
	_score_l.custom_minimum_size = Vector2(90, 0)
	_score_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_score_l)
	_time_bar = ProgressBar.new()
	_time_bar.name = "TimeBar"
	_time_bar.show_percentage = false
	_time_bar.custom_minimum_size = Vector2(260, 26)
	_time_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_time_bar.max_value = _total
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.2, 0.5, 0.2)
	bg.set_corner_radius_all(13)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("39b54a")
	fill.set_corner_radius_all(13)
	_time_bar.add_theme_stylebox_override("background", bg)
	_time_bar.add_theme_stylebox_override("fill", fill)
	h.add_child(_time_bar)
	# the needle (focus owner: arrows and OK go here)
	_needle = Control.new()
	_needle.name = "Needle"
	_needle.focus_mode = Control.FOCUS_ALL
	_needle.size = Vector2(80, 120)
	_needle.draw.connect(_draw_needle)
	_needle.gui_input.connect(_on_needle_input)
	add_child(_needle)
	FocusManager.set_neighbors(_needle, _needle, _needle, _needle, _needle)
	_move_needle(0)
	var hint := Label.new()
	hint.theme_type_variation = &"OnDarkBody"
	hint.text = "game_hint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 1080 - SAFE_Y - 30)
	hint.size = Vector2(1920, 40)
	add_child(hint)
	_score_l.text = "0"
	_new_target()


func get_default_focus() -> Control:
	return _needle


func handle_back() -> bool:
	main.pop()
	return true


func _draw_needle() -> void:
	var c := _needle.get_canvas_item()
	var w := _needle.size.x
	# a friendly dart: silver tip, red body, yellow feathers
	_needle.draw_colored_polygon(PackedVector2Array([Vector2(w / 2, 0), Vector2(w / 2 + 9, 34), Vector2(w / 2 - 9, 34)]), Color("d9e2ec"))
	_needle.draw_rect(Rect2(w / 2 - 11, 34, 22, 52), Color("e53935"))
	_needle.draw_colored_polygon(PackedVector2Array([Vector2(w / 2 - 11, 78), Vector2(w / 2 - 34, 116), Vector2(w / 2, 96),
		Vector2(w / 2 + 34, 116), Vector2(w / 2 + 11, 78)]), Color("ffc928"))
	if _needle.has_focus():
		_needle.draw_arc(Vector2(w / 2, 60), 58, 0, TAU, 40, Color(1, 0.85, 0.2, 0.55), 6)


func _move_needle(d: int) -> void:
	lane = clampi(lane + d, 0, LANES - 1)
	var x := LANE_X0 + lane * LANE_STEP
	if AppState.animations_enabled() and is_inside_tree():
		create_tween().tween_property(_needle, "position:x", x - _needle.size.x / 2, 0.08)
	else:
		_needle.position.x = x - _needle.size.x / 2
	_needle.position.y = NEEDLE_Y - 30
	_needle.queue_redraw()


func _on_needle_input(e: InputEvent) -> void:
	if finished:
		return
	if e.is_action_pressed("ui_left"):
		_move_needle(-1)
		Sfx.play("move")
		_needle.accept_event()
	elif e.is_action_pressed("ui_right"):
		_move_needle(1)
		Sfx.play("move")
		_needle.accept_event()
	elif e.is_action_pressed("ui_accept"):
		pop_in_lane()
		_needle.accept_event()
	elif e.is_action_pressed("ui_up") or e.is_action_pressed("ui_down"):
		_needle.accept_event()


## The owl asks for a number (0–9) or a letter, alternating.
func _new_target() -> void:
	var number := target == "" or not target.is_valid_int()
	target = str(_rng.randi_range(1, 9)) if number else LETTERS[_rng.randi_range(0, LETTERS.size() - 1)]
	_retarget = 15.0
	_target_l.text = Localization.t("game_target", {"x": target})
	Juice.pop(_target_l, 1.15)
	Voice.say([Voice.num(int(target)) if number else Voice.letter(target)])


func _spawn_balloon() -> void:
	var free := []
	for l in LANES:
		var busy := false
		for b in balloons:
			if b["lane"] == l and (b["node"] as Control).position.y > 820:
				busy = true
		if not busy:
			free.append(l)
	if free.is_empty():
		return
	var l: int = free[_rng.randi_range(0, free.size() - 1)]
	var label := ""
	if _rng.randf() < 0.5:                         # half of the balloons carry a sign
		var number := target.is_valid_int()
		if _rng.randf() < 0.45:
			label = target
		elif number:
			label = str(_rng.randi_range(0, 9))
		else:
			label = LETTERS[_rng.randi_range(0, LETTERS.size() - 1)]
	var r := TextureRect.new()
	r.texture = load("res://assets/game/Balloon_%s.png" % COLORS[_rng.randi_range(0, COLORS.size() - 1)])
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.size = Vector2(170, 170)
	r.position = Vector2(LANE_X0 + l * LANE_STEP - 85, 1090)
	r.pivot_offset = r.size / 2.0
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if label != "":
		var t := Label.new()
		t.text = label
		t.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		t.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
		t.add_theme_font_size_override("font_size", 66)
		t.add_theme_color_override("font_color", Color.WHITE)
		t.add_theme_constant_override("outline_size", 12)
		t.add_theme_color_override("font_outline_color", Color(0.1, 0.12, 0.3, 0.85))
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		t.position = Vector2(0, -4)
		t.size = Vector2(170, 120)
		r.add_child(t)
	_sky.add_child(r)
	balloons.append({"node": r, "lane": l, "label": label, "speed": _rng.randf_range(130.0, 190.0)})


func _process(delta: float) -> void:
	if finished or not is_visible_in_tree():
		return
	_left -= delta
	_time_bar.value = maxf(0.0, _left)
	if _left <= 0.0:
		_finish()
		return
	_retarget -= delta
	if _retarget <= 0.0:
		_new_target()
	_spawn -= delta
	if _spawn <= 0.0:
		_spawn = _rng.randf_range(0.55, 0.85)
		_spawn_balloon()
	for b in balloons.duplicate():
		var n: Control = b["node"]
		n.position.y -= b["speed"] * delta
		n.position.x += sin((n.position.y + b["lane"] * 37.0) / 60.0) * 0.4      # a little sway
		if n.position.y < -200:
			balloons.erase(b)
			n.queue_free()


## Pops the lowest balloon above the needle; returns the points (or -1 if none).
func pop_in_lane() -> int:
	var best: Dictionary = {}
	for b in balloons:
		var y: float = (b["node"] as Control).position.y
		if b["lane"] == lane and y < NEEDLE_Y - 60 and y > 60 and (best.is_empty() or y > (best["node"] as Control).position.y):
			best = b
	if best.is_empty():
		Juice.pop(_needle, 0.85)
		return -1
	var pts := 1
	if best["label"] != "":
		pts = 2 if best["label"] == target else 0
	balloons.erase(best)
	var n: Control = best["node"]
	Juice.burst(self, n.get_global_rect().get_center(), 10 if pts > 0 else 4, 22)
	Sfx.play("pop" if pts > 0 else "toggle")
	popped += 1
	score += pts
	_score_l.text = str(score)
	if pts > 0:
		Juice.pop(_score_l, 1.3)
	n.queue_free()
	return pts


func _finish() -> void:
	finished = true
	for b in balloons:
		(b["node"] as Control).queue_free()
	balloons.clear()
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.25, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.97)
	sb.set_corner_radius_all(48)
	sb.content_margin_left = 70
	sb.content_margin_right = 70
	sb.content_margin_top = 40
	sb.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(820, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	panel.add_child(v)
	var t := Label.new()
	t.theme_type_variation = &"HeadingLabel"
	t.add_theme_font_size_override("font_size", 60)
	t.add_theme_color_override("font_color", Color("1d2b6b"))
	t.text = "game_done"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var m := Label.new()
	m.name = "ResultText"
	m.theme_type_variation = &"BodyLabel"
	m.add_theme_color_override("font_color", Color("1d2b6b"))
	m.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	m.text = Localization.t("game_result", {"n": score, "b": popped})
	m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(m)
	var back := PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back.name = "ResultsBack"
	back.custom_minimum_size.x = 340
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.sound = "back"
	back.pressed.connect(func(): main.pop())
	v.add_child(back)
	FocusManager.set_neighbors(back)
	_needle.focus_mode = Control.FOCUS_NONE
	var owl := Mascot.make("cheer", 300, Vector2(150, 600))
	add_child(owl)
	Mascot.appear(owl)
	Juice.burst(self, Vector2(960, 300), 12, 30)
	Sfx.play("streak")
	Voice.say(["ex_correct_3"], false)
	back.grab_focus.call_deferred()
