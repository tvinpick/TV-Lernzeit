extends BaseScreen
## "Diagnose" (parents area → App-Version): facts about the TV that help with support –
## app version, processor type (which engine library the TV runs: arm64 / arm32),
## memory, screen, frame rate and how long the last screens took to open.
## Read only; nothing leaves the device.

var back_button: PillButton
var _values := {}         ## key -> value Label
var _timer := 0.0


func _ready() -> void:
	add_background("res://assets/backgrounds/progress_background_1080p.png")
	add_title("diag_title", "res://assets/icons/Parents_Icon_Info.png")
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel("main", 40))
	panel.position = Vector2(SAFE_X, 170)
	panel.size = Vector2(1920 - SAFE_X * 2, 740)
	add_child(panel)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 60)
	panel.add_child(cols)
	var left := _column(cols)
	var right := _column(cols)
	for k in ["diag_app", "diag_device", "diag_cpu", "diag_screen", "diag_fps", "diag_renderer"]:
		_line(left, k)
	for k in ["diag_ram", "diag_app_mem", "diag_video_mem", "diag_open", "diag_data"]:
		_line(right, k)
	back_button = PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back_button.name = "BackButton"
	back_button.sound = "back"
	back_button.custom_minimum_size.x = 300
	back_button.pressed.connect(func(): main.pop())
	add_bottom_bar([back_button], [])
	FocusManager.set_neighbors(back_button)
	_refresh()


func get_default_focus() -> Control:
	return back_button


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 0.5:
		_timer = 0.0
		_refresh()


func _column(parent: Control) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 14)
	parent.add_child(v)
	return v


func _line(parent: Control, key: String) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	parent.add_child(v)
	var t := Label.new()
	t.theme_type_variation = &"CaptionLabel"
	t.text = key
	v.add_child(t)
	var val := Label.new()
	val.theme_type_variation = &"BodyLabel"
	val.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	val.name = "Value_" + key
	v.add_child(val)
	_values[key] = val


static func _mb(bytes: float) -> String:
	return "%d MB" % int(round(bytes / 1048576.0))


## Values as a dictionary (also used by the tests).
static func facts(open_times: Dictionary) -> Dictionary:
	var mem := OS.get_memory_info()
	var size := DisplayServer.screen_get_size()
	var opened: Array = []
	for id in open_times:
		opened.append("%s %d ms" % [id, open_times[id]])
	return {
		"diag_app": "Lernzeit %s (Godot %s)" % [AppState.app_version(), Engine.get_version_info()["string"]],
		"diag_device": "%s · %s %s" % [OS.get_model_name(), OS.get_name(), OS.get_version()],
		"diag_cpu": "%s · %d × %s" % [Engine.get_architecture_name(), OS.get_processor_count(), OS.get_processor_name()],
		"diag_screen": "%d × %d" % [size.x, size.y],
		"diag_fps": "%d" % Engine.get_frames_per_second(),
		"diag_renderer": "%s · %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_driver_name()],
		"diag_ram": "%s / %s" % [_mb(mem.get("available", mem.get("free", 0))), _mb(mem.get("physical", 0))],
		"diag_app_mem": _mb(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"diag_video_mem": _mb(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"diag_open": ", ".join(opened) if not opened.is_empty() else "—",
		"diag_data": "%d" % ProgressRepository.get_records().size(),
	}


func _refresh() -> void:
	var f := facts(main.open_times if main else {})
	for k in f:
		if _values.has(k):
			_values[k].text = f[k]
