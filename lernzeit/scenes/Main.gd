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
}

var _host: Control
var _overlay: Control
var _toast: Toast
var _stack: Array = []        ## [{id, screen, focus}]
var _dir_input_ms := -1000


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
	_fade_in(s)
	var f: Control = prev.get("focus")
	if is_instance_valid(f) and f.is_visible_in_tree() and f.focus_mode != Control.FOCUS_NONE:
		f.grab_focus.call_deferred()
	else:
		_focus_default()


func _open(id: String, p: Dictionary) -> BaseScreen:
	var s: BaseScreen = load(SCREENS[id]).instantiate()
	s.main = self
	s.params = p
	_host.add_child(s)
	_stack.append({"id": id, "screen": s, "focus": null})
	_fade_in(s)
	_focus_default()
	return s


func _fade_in(s: Control) -> void:
	if AppState.animations_enabled():
		s.modulate.a = 0.0
		create_tween().tween_property(s, "modulate:a", 1.0, 0.18)
	else:
		s.modulate.a = 1.0


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
