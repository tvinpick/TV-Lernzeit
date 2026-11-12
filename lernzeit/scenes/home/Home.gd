extends BaseScreen
## Home: Lernzeit logo (in the background art), localized prompt, four subject
## cards (2×2), "Mein Fortschritt", disabled "Weiter üben" and the settings gear.

var cards := {}
var progress_button: ArtButton
var continue_button: ArtButton
var gear: TextureButton


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
	continue_button.focus_mode = Control.FOCUS_NONE      # no exercises yet → not selectable
	continue_button.modulate = Color(0.78, 0.82, 0.92, 0.82)
	add_child(continue_button)

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

	var m: Control = cards["mathematik"]
	var d: Control = cards["deutsch"]
	var l: Control = cards["lesen"]
	var g: Control = cards["logik"]
	FocusManager.set_neighbors(m, null, d, null, l)
	FocusManager.set_neighbors(d, m, gear, gear, g)
	FocusManager.set_neighbors(l, null, g, m, progress_button)
	FocusManager.set_neighbors(g, l, null, d, progress_button)
	FocusManager.set_neighbors(progress_button, null, null, l, null)
	FocusManager.set_neighbors(gear, d, null, null, d)
	_refresh()


func get_default_focus() -> Control:
	return cards["mathematik"]


func on_shown() -> void:
	_refresh()


func _refresh() -> void:
	for sid in cards:
		cards[sid].dimmed = not SettingsRepository.is_subject_enabled(sid)


func _on_card(sid: String) -> void:
	var c: FocusableCard = cards[sid]
	c.press_feedback()
	if c.dimmed:
		toast(Localization.t("subject_disabled_toast"))
		return
	main.push("subject", {"subject_id": sid})
