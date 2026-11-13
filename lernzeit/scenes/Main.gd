extends Control
## Root of the app: navigation stack, dialogs, toasts and remote-control
## handling (Back / Home behaviour, focus recovery, navigation sounds).

const SCREENS := {
	"home": "res://scenes/home/Home.tscn",
	"subject": "res://scenes/subjects/SubjectMenu.tscn",
	"unavailable": "res://scenes/subjects/Unavailable.tscn",
	"progress": "res://scenes/progress/ProgressOverview.tscn",
	"progress_detail": "res://scenes/progress/ProgressDetail.tscn",
	"settings": "res://scenes/settings/Settings.tscn",
	"pin": "res://scenes/parents/PinGate.tscn",
	"parents": "res://scenes/parents/ParentDashboard.tscn",
	"exercise": "res://scenes/exercises/MathExercise.tscn",
	"exercise_de": "res://scenes/exercises/DeutschExercise.tscn",
	"achievements": "res://scenes/progress/AchievementsScreen.tscn",
	"stickers": "res://scenes/progress/StickerAlbum.tscn",
	"letters": "res://scenes/parents/LettersOverview.tscn",
}

var _host: Control
var _overlay: Control
var _toast: Toast
var _stack: Array = []        ## [{id, screen, focus}]
var _dir_input_ms := -1000
var show_splash := true        ## tests switch it off before adding Main to the tree


func _ready() -> void:
	theme = AppState.theme
	AppState.theme_changed.connect(func(t: Theme): theme = t)
	_host = _full_rect_control()
	add_child(_host)
	_overlay = _full_rect_control()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_toast = Toast.new()
	add_child(_toast)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	push("home")
	var splash := show_splash and AppState.animations_enabled()
	if splash:
		_splash()
	_greet(2.0 if splash else 0.4)


## "Was möchtest du heute üben?" once after the start (German interface only).
func _greet(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_inside_tree() and Localization.current == "de" and _stack.size() == 1:
		Voice.say(["home_prompt"], false)


## Start animation: logo pops in with sparkles, then fades into the home screen.
func _splash() -> void:
	var sp := Control.new()
	sp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sp.z_index = 100
	add_child(sp)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.36, 0.78, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sp.add_child(bg)
	var logo := TextureRect.new()
	logo.texture = preload("res://assets/branding/icon_192.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size = Vector2(260, 260)
	logo.position = Vector2(960 - 130, 300)
	logo.pivot_offset = logo.size / 2.0
	logo.scale = Vector2.ZERO
	sp.add_child(logo)
	var title := Label.new()
	title.text = "Lernzeit"
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
	title.add_theme_font_size_override("font_size", 120)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.15, 0.5, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(1920, 160)
	title.position = Vector2(0, 590)
	title.modulate.a = 0.0
	sp.add_child(title)
	var owl := Mascot.make("wave", 330, Vector2(1380, 360))
	sp.add_child(owl)
	Mascot.appear(owl)
	var tw := create_tween()
	tw.tween_property(logo, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(title, "modulate:a", 1.0, 0.25)
	tw.tween_callback(func():
		Juice.burst(sp, Vector2(960, 430), 9, 18)
		Sfx.play("streak"))
	tw.tween_interval(0.75)
	tw.tween_property(sp, "modulate:a", 0.0, 0.4)
	tw.tween_callback(sp.queue_free)


func _full_rect_control() -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	return c


# ------------------------------------------------------------- navigation ---

func push(id: String, p: Dictionary = {}) -> BaseScreen:
	var cur := _top()
	if not cur.is_empty():
		cur["focus"] = get_viewport().gui_get_focus_owner()
		cur["screen"].visible = false
	return _open(id, p)


func replace(id: String, p: Dictionary = {}) -> BaseScreen:
	var cur := _top()
	if not cur.is_empty():
		_stack.pop_back()
		cur["screen"].queue_free()
	return _open(id, p)


func pop() -> void:
	if _stack.size() <= 1:
		return
	var cur: Dictionary = _stack.pop_back()
	cur["screen"].queue_free()
	var prev := _top()
	var s: BaseScreen = prev["screen"]
	s.visible = true
	s.on_shown()
	_slide_in(s, -1)
	var f = prev.get("focus")       # untyped: the remembered control may have been freed meanwhile
	if is_instance_valid(f) and f is Control and f.is_visible_in_tree() and f.focus_mode != Control.FOCUS_NONE:
		f.grab_focus.call_deferred()
	else:
		_focus_default()


## Closes every screen above Home (e.g. "Pause machen").
func pop_to_home() -> void:
	while _stack.size() > 1:
		var cur: Dictionary = _stack.pop_back()
		cur["screen"].queue_free()
	var home: BaseScreen = _top()["screen"]
	home.visible = true
	home.on_shown()
	_slide_in(home, -1)
	_focus_default()


func _open(id: String, p: Dictionary) -> BaseScreen:
	var s: BaseScreen = load(SCREENS[id]).instantiate()
	s.main = self
	s.params = p
	_host.add_child(s)
	_stack.append({"id": id, "screen": s, "focus": null})
	_slide_in(s, 1)
	_focus_default()
	return s


## New screens slide in from the right (back: from the left) while fading in.
func _slide_in(s: Control, dir: int) -> void:
	if AppState.animations_enabled():
		s.modulate.a = 0.0
		s.position.x = 80.0 * dir
		var tw := create_tween().set_parallel()
		tw.tween_property(s, "modulate:a", 1.0, 0.2)
		tw.tween_property(s, "position:x", 0.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		s.modulate.a = 1.0
		s.position.x = 0.0


func _focus_default() -> void:
	var s := current_screen()
	if s == null:
		return
	var f := s.get_default_focus()
	if f:
		f.grab_focus.call_deferred()


func _top() -> Dictionary:
	return _stack.back() if not _stack.is_empty() else {}


func current_screen() -> BaseScreen:
	var t := _top()
	return t["screen"] if not t.is_empty() else null


func current_id() -> String:
	var t := _top()
	return t["id"] if not t.is_empty() else ""


func stack_ids() -> Array:
	return _stack.map(func(e): return e["id"])


# ---------------------------------------------------------------- dialogs ---

func show_dialog(d: ConfirmDialog) -> ConfirmDialog:
	_overlay.add_child(d)
	return d


func has_dialog() -> bool:
	for c in _overlay.get_children():
		if c is ConfirmDialog and not c.is_queued_for_deletion():
			return true
	return false


func top_dialog() -> ConfirmDialog:
	for i in range(_overlay.get_child_count() - 1, -1, -1):
		var c := _overlay.get_child(i)
		if c is ConfirmDialog and not c.is_queued_for_deletion():
			return c
	return null


## Overlay layer for screen-owned popups (e.g. name editor).
func overlay() -> Control:
	return _overlay


func toast(text: String) -> void:
	_toast.show_text(text)


# ------------------------------------------------------------ remote input ---

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


func _input(event: InputEvent) -> void:
	for a in ["ui_up", "ui_down", "ui_left", "ui_right"]:
		if event.is_action_pressed(a, true):
			_dir_input_ms = Time.get_ticks_msec()
			# focus recovery: never leave the user without a focused element
			if get_viewport().gui_get_focus_owner() == null:
				var d := top_dialog()
				if d:
					d.ensure_focus()
				else:
					_focus_default()
				get_viewport().set_input_as_handled()
			return


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("lz_back"):
		get_viewport().set_input_as_handled()
		go_back()


func go_back() -> void:
	if not AppState.accept_back_press():
		return
	var d := top_dialog()
	if d:
		Sfx.play("back")
		d.cancel()
		return
	for c in _overlay.get_children():
		if c.has_method("close_popup") and not c.is_queued_for_deletion():
			Sfx.play("back")
			c.close_popup()
			return
	var s := current_screen()
	if s and s.handle_back():
		return
	if _stack.size() > 1:
		Sfx.play("back")
		pop()
	else:
		_ask_exit()


func _ask_exit() -> void:
	var d := ConfirmDialog.make("exit_title", "exit_message", "exit_confirm", "red")
	d.confirmed.connect(func(): get_tree().quit())
	show_dialog(d)


func _on_focus_changed(c: Control) -> void:
	if Time.get_ticks_msec() - _dir_input_ms < 250:
		Sfx.play("move")
	# keep focus inside an open dialog
	var d := top_dialog()
	if d and c and not d.is_ancestor_of(c):
		d.ensure_focus.call_deferred()
