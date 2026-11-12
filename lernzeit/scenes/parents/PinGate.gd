extends BaseScreen
## PIN entry with a focusable on-screen keypad (D-pad + OK, or the number keys
## of the remote). Modes:
##   enter  – first use: create PIN (twice), afterwards verify → Elternbereich
##   reauth – verify again before a sensitive action (params.on_success)
##   change – set a new PIN (from the Elternbereich)
## Back / "Abbrechen" closes without opening anything.

var mode := "enter"
var _step := "verify"          # create | confirm | verify
var _pin := ""
var _first_pin := ""
var _title_l: Label
var _msg_l: Label
var _dots: PinDots
var keypad: Array[PillButton] = []
var cancel_button: PillButton
var _lock_timer: Timer


func _ready() -> void:
	mode = params.get("mode", "enter")
	add_background("res://assets/backgrounds/progress_background_4k.png")
	add_title("pin_title", "res://assets/icons/Parents_Icon_PIN.png")
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel("main", 56))
	panel.position = Vector2(440, 160)
	panel.size = Vector2(1040, 870)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	_title_l = Label.new()
	_title_l.theme_type_variation = &"HeadingLabel"
	_title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_title_l)
	_dots = PinDots.new()
	_dots.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_dots)
	_msg_l = Label.new()
	_msg_l.theme_type_variation = &"BodyLabel"
	_msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg_l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_msg_l.add_theme_color_override("font_color", Color("c62828"))
	_msg_l.custom_minimum_size.y = 44
	v.add_child(_msg_l)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(grid)
	var labels := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "pin_delete", "0", "cancel"]
	for k in labels:
		var b: PillButton
		if k == "pin_delete":
			b = PillButton.make(k, "cyan", null, true)
			b.pressed.connect(_delete)
			b.sound = "back"
		elif k == "cancel":
			b = PillButton.make(k, "light", preload("res://assets/icons/Settings_Icon_Cancel.png"), true)
			b.pressed.connect(_cancel)
			b.sound = "back"
			cancel_button = b
		else:
			b = PillButton.make(k, "light")
			b.theme_type_variation = &"PillButton"
			b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			b.add_theme_font_size_override("font_size", 44)
			b.pressed.connect(_digit.bind(k))
		b.name = "Key_" + k
		b.custom_minimum_size = Vector2(250, 84)
		grid.add_child(b)
		keypad.append(b)
	var hint := Label.new()
	hint.theme_type_variation = &"CaptionLabel"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "pin_hint"
	v.add_child(hint)
	var forgot := Label.new()
	forgot.theme_type_variation = &"CaptionLabel"
	forgot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	forgot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forgot.text = "pin_forgot"
	forgot.visible = mode != "change" and SettingsRepository.has_pin()
	v.add_child(forgot)
	# 3×4 grid navigation
	for i in keypad.size():
		var c := i % 3
		var r := i / 3
		FocusManager.set_neighbors(keypad[i],
			keypad[i - 1] if c > 0 else null,
			keypad[i + 1] if c < 2 else null,
			keypad[i - 3] if r > 0 else null,
			keypad[i + 3] if r < 3 else null)
	_lock_timer = Timer.new()
	_lock_timer.wait_time = 1.0
	_lock_timer.timeout.connect(_update_lock)
	add_child(_lock_timer)
	if mode == "change" or (mode == "enter" and not SettingsRepository.has_pin()):
		_step = "create"
	else:
		_step = "verify"
	_refresh_title()
	_update_lock()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_title()


func get_default_focus() -> Control:
	return keypad[4]   # "5" in the middle


func _refresh_title() -> void:
	match _step:
		"create": _title_l.text = tr("pin_change_new") if mode == "change" else tr("pin_create")
		"confirm": _title_l.text = tr("pin_create_repeat")
		_: _title_l.text = tr("pin_reauth") if mode == "reauth" else tr("pin_enter")


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or main.has_dialog():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k >= KEY_0 and k <= KEY_9:
			_digit(str(k - KEY_0))
			get_viewport().set_input_as_handled()
		elif k >= KEY_KP_0 and k <= KEY_KP_9:
			_digit(str(k - KEY_KP_0))
			get_viewport().set_input_as_handled()


func _digit(d: String) -> void:
	if _step == "verify" and SettingsRepository.pin_lock_remaining() > 0:
		Sfx.play("error")
		_update_lock()
		return
	if _pin.length() >= PinHasher.PIN_LENGTH:
		return
	_pin += d
	_dots.error = false
	_dots.count = _pin.length()
	if _pin.length() == PinHasher.PIN_LENGTH:
		_submit.call_deferred()


func _delete() -> void:
	if _pin.length() > 0:
		_pin = _pin.substr(0, _pin.length() - 1)
		_dots.count = _pin.length()


func _cancel() -> void:
	main.pop()


func _submit() -> void:
	var pin := _pin
	_pin = ""
	match _step:
		"create":
			_first_pin = pin
			_step = "confirm"
			_dots.count = 0
			_msg_l.text = ""
			_refresh_title()
		"confirm":
			if pin != _first_pin:
				_first_pin = ""
				_step = "create"
				_fail(tr("pin_mismatch"))
				_refresh_title()
				return
			SettingsRepository.set_pin(pin)
			_first_pin = ""
			Sfx.play("select")
			toast(tr("pin_saved"))
			_success()
		"verify":
			var res := SettingsRepository.verify_pin(pin)
			if res["ok"]:
				Sfx.play("select")
				_success()
			elif res["locked_seconds"] > 0:
				_fail(Localization.t("pin_locked", {"n": res["locked_seconds"]}))
				_update_lock()
			else:
				_fail(Localization.t("pin_wrong", {"n": res["remaining_attempts"]}))


func _fail(msg: String) -> void:
	Sfx.play("error")
	_msg_l.text = msg
	_dots.count = 0
	_dots.error = true
	if AppState.animations_enabled():
		var t := create_tween()
		var x := _dots.position.x
		for dx in [18.0, -18.0, 12.0, -12.0, 0.0]:
			t.tween_property(_dots, "position:x", x + dx, 0.04)


func _success() -> void:
	match mode:
		"enter":
			main.replace("parents")
		"reauth":
			var cb: Callable = params.get("on_success", Callable())
			main.pop()
			if cb.is_valid():
				cb.call_deferred()
		_:
			main.pop()


func _update_lock() -> void:
	if _step != "verify":
		return
	var s := SettingsRepository.pin_lock_remaining()
	if s > 0:
		_msg_l.text = Localization.t("pin_locked", {"n": s})
		if _lock_timer.is_stopped():
			_lock_timer.start()
	else:
		if not _lock_timer.is_stopped():
			_lock_timer.stop()
			_msg_l.text = ""
			_dots.error = false
