class_name SubjectProgressRow
extends Button
## One subject line in "Mein Fortschritt": icon, name, status, bar, result.

var subject_id := ""
var _status_box: HBoxContainer
var _track: ProgressTrack
var _result: Label
var _tween: Tween


static func make(sid: String) -> SubjectProgressRow:
	var r := SubjectProgressRow.new()
	r.subject_id = sid
	return r


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(0, 104)
	var sb := UiSkin.panel("wide", 30)
	for s in ["normal", "hover", "pressed"]:
		add_theme_stylebox_override(s, sb)
	add_theme_stylebox_override("focus", UiTheme.focus_ring(30))
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 28
	h.offset_right = -28
	h.add_theme_constant_override("separation", 26)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h)
	var ic := TextureRect.new()
	ic.texture = load(Curriculum.SUBJECTS[subject_id]["icon"])
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(84, 84)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var name_l := FitLabel.new()
	name_l.theme_type_variation = &"RowTitle"
	name_l.text = Curriculum.title_key(subject_id)
	name_l.custom_minimum_size.x = 300
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_l.size_flags_vertical = Control.SIZE_FILL
	h.add_child(name_l)
	_status_box = HBoxContainer.new()
	_status_box.custom_minimum_size.x = 380
	_status_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_status_box)
	_track = ProgressTrack.new()
	_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_track)
	_result = Label.new()
	_result.theme_type_variation = &"RowTitle"
	_result.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_result.custom_minimum_size.x = 110
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_result)
	var chev := Label.new()
	chev.theme_type_variation = &"HeadingLabel"
	chev.text = "›"
	chev.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	chev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(chev)
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	resized.connect(func(): pivot_offset = size / 2.0)
	refresh()


func refresh() -> void:
	var s := ProgressRepository.summary(subject_id)
	for c in _status_box.get_children():
		c.queue_free()
	if s["sessions"] == 0:
		_status_box.add_child(StatusChip.make("status_not_started"))
	_track.set_ratio(s["accuracy"])
	_result.text = "—" if s["accuracy"] == null else "%d %%" % roundi(s["accuracy"] * 100.0)


func _on_focus(on: bool) -> void:
	if _tween:
		_tween.kill()
	var target := Vector2.ONE * (1.02 if on else 1.0)
	if AppState.animations_enabled():
		_tween = create_tween()
		_tween.tween_property(self, "scale", target, 0.12)
	else:
		scale = target
