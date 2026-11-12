extends BaseScreen
## Subject details: topics with status/result, parent figures and history.
## Without records everything shows "Nicht begonnen" / "—" / empty history.

var back_button: PillButton
var _figures := {}


func _ready() -> void:
	var sid: String = params.get("subject_id", "mathematik")
	add_background("res://assets/backgrounds/progress_background_4k.png")
	add_title(Curriculum.title_key(sid), Curriculum.SUBJECTS[sid]["icon"])

	# --- topics & results ---
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UiSkin.panel("main", 46))
	left.position = Vector2(SAFE_X, 176)
	left.size = Vector2(1000, 720)
	add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 10)
	left.add_child(lv)
	var lt := Label.new()
	lt.theme_type_variation = &"HeadingLabel"
	lt.text = "detail_topics"
	lv.add_child(lt)
	for t in Curriculum.topics(sid):
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UiSkin.row("blue"))
		row.custom_minimum_size.y = 86
		lv.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		row.add_child(h)
		var n := FitLabel.new()
		n.theme_type_variation = &"BodyLabel"
		n.text = t["key"]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		n.size_flags_vertical = Control.SIZE_FILL
		h.add_child(n)
		var status := ProgressRepository.topic_status(sid, t["id"])
		h.add_child(StatusChip.make("status_topic_not_started" if status == "not_started" else "status_" + status))
		var res := Label.new()
		res.theme_type_variation = &"RowTitle"
		res.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		res.custom_minimum_size.x = 100
		res.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		res.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var recs := ProgressRepository.get_records(sid, t["id"])
		res.text = "—" if recs.is_empty() else str(recs.size())
		h.add_child(res)

	# --- parents figures + history ---
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", UiSkin.panel("main", 46))
	right.position = Vector2(1126, 176)
	right.size = Vector2(1920 - SAFE_X - 1126, 720)
	add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 10)
	right.add_child(rv)
	var pt := Label.new()
	pt.theme_type_variation = &"HeadingLabel"
	pt.text = "detail_parents"
	rv.add_child(pt)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 6)
	rv.add_child(grid)
	for k in ["detail_tasks", "detail_accuracy", "detail_time", "detail_last"]:
		var kl := Label.new()
		kl.theme_type_variation = &"BodyLabel"
		kl.text = k
		kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(kl)
		var vl := Label.new()
		vl.theme_type_variation = &"RowTitle"
		vl.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(vl)
		_figures[k] = vl
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 20)
	rv.add_child(sep)
	var ht := Label.new()
	ht.theme_type_variation = &"HeadingLabel"
	ht.text = "detail_history"
	rv.add_child(ht)
	var recs_all := ProgressRepository.get_records(sid)
	if recs_all.is_empty():
		var e := EmptyState.make("res://assets/icons/Lernzeit_Icon_Calendar.png", "detail_no_history", "detail_no_history_text")
		e.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rv.add_child(e)
	else:
		for r in recs_all.slice(0, 5):
			var l := Label.new()
			l.theme_type_variation = &"BodyLabel"
			l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			var dt := Time.get_datetime_dict_from_unix_time(r.timestamp)
			l.text = "%02d.%02d.%d  %s  %d/%d" % [dt.day, dt.month, dt.year, tr(Curriculum.topic_key(sid, r.topic_id)), r.correct_count, r.total_count]
			rv.add_child(l)

	back_button = PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back_button.name = "BackButton"
	back_button.sound = "back"
	back_button.position = Vector2(SAFE_X, 922)
	back_button.custom_minimum_size.x = 300
	add_child(back_button)
	back_button.pressed.connect(func(): main.pop())
	FocusManager.set_neighbors(back_button)
	_refresh_figures()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_figures()


func _refresh_figures() -> void:
	var s := ProgressRepository.summary(params.get("subject_id", "mathematik"))
	_figures["detail_tasks"].text = str(s["tasks_solved"])
	_figures["detail_accuracy"].text = "—" if s["accuracy"] == null else "%d %%" % roundi(s["accuracy"] * 100.0)
	_figures["detail_time"].text = Localization.t("minutes_short", {"n": int(s["duration_seconds"] / 60)})
	if s["last_timestamp"] > 0:
		var dt := Time.get_datetime_dict_from_unix_time(s["last_timestamp"])
		_figures["detail_last"].text = "%02d.%02d.%d" % [dt.day, dt.month, dt.year]
	else:
		_figures["detail_last"].text = "—"


func get_default_focus() -> Control:
	return back_button
