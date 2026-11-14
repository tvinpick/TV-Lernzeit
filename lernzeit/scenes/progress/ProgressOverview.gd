extends BaseScreen
## "Mein Fortschritt" – child overview. Shows real values from the
## ProgressRepository only: 0 tasks, no percentage for 0/0, empty bars.

var stat_tasks: StatCard
var stat_correct: StatCard
var stat_topics: StatCard
var subject_rows := {}
var back_button: PillButton
var achievements_button: PillButton
var stickers_button: PillButton


func _ready() -> void:
	add_background("res://assets/backgrounds/progress_background_1080p.png")
	add_title("progress", "res://assets/icons/Lernzeit_Icon_Progress.png")

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 30)
	stats.position = Vector2(SAFE_X, 176)
	stats.size = Vector2(1920 - SAFE_X * 2, 190)
	add_child(stats)
	stat_tasks = StatCard.make("res://assets/icons/Lernzeit_Icon_Tasks.png", "stat_tasks", "stat_blue")
	stat_correct = StatCard.make("res://assets/icons/Lernzeit_Icon_Correct.png", "stat_correct", "stat_purple")
	stat_topics = StatCard.make("res://assets/icons/Lernzeit_Icon_Subjects.png", "stat_topics", "stat_gold")
	for s in [stat_tasks, stat_correct, stat_topics]:
		stats.add_child(s)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 14)
	list.position = Vector2(SAFE_X, 394)
	list.size = Vector2(1920 - SAFE_X * 2, 470)
	add_child(list)
	var rows: Array[Control] = []
	for sid in Curriculum.SUBJECT_IDS:
		var r := SubjectProgressRow.make(sid)
		r.name = "Row_" + sid
		list.add_child(r)
		r.pressed.connect(func():
			Sfx.play("select")
			main.push("progress_detail", {"subject_id": sid}))
		subject_rows[sid] = r
		rows.append(r)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 30)
	bottom.position = Vector2(SAFE_X, 914)
	bottom.size = Vector2(1920 - SAFE_X * 2, 100)
	add_child(bottom)
	back_button = PillButton.make("back", "light", preload("res://assets/icons/Settings_Icon_Back.png"))
	back_button.name = "BackButton"
	back_button.sound = "back"
	back_button.custom_minimum_size.x = 300
	bottom.add_child(back_button)
	back_button.pressed.connect(func(): main.pop())
	achievements_button = PillButton.make("achievements", "light", preload("res://assets/icons/Settings_Icon_Achievements.png"))
	achievements_button.name = "AchievementsButton"
	achievements_button.custom_minimum_size.x = 300
	achievements_button.pressed.connect(func(): main.push("achievements"))
	bottom.add_child(achievements_button)
	stickers_button = PillButton.make("stickers", "light", preload("res://assets/mascot/stickers/Sticker_11.png"))
	stickers_button.name = "StickersButton"
	stickers_button.custom_minimum_size.x = 300
	stickers_button.pressed.connect(func(): main.push("stickers"))
	bottom.add_child(stickers_button)
	var note := Label.new()
	note.name = "AchievementsNote"
	note.theme_type_variation = &"OnDarkCaption"
	note.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom.add_child(note)

	FocusManager.link_column(rows)
	for r in rows:
		FocusManager.set_one(r, SIDE_LEFT, r)
		FocusManager.set_one(r, SIDE_RIGHT, r)
	FocusManager.set_one(rows.back(), SIDE_BOTTOM, back_button)
	FocusManager.set_neighbors(back_button, null, achievements_button, rows.back(), null)
	FocusManager.set_neighbors(achievements_button, back_button, stickers_button, rows.back(), null)
	FocusManager.set_neighbors(stickers_button, achievements_button, null, rows.back(), null)
	_refresh()


func on_shown() -> void:
	_refresh()


func get_default_focus() -> Control:
	return subject_rows["mathematik"]


func _refresh() -> void:
	var s := ProgressRepository.summary()
	stat_tasks.set_value(str(s["tasks_solved"]))
	stat_correct.set_value("—" if s["accuracy"] == null else "%d %%" % roundi(s["accuracy"] * 100.0))
	stat_topics.set_value(str(s["topics_practiced"]))
	for sid in subject_rows:
		subject_rows[sid].refresh()
	var note: Label = find_child("AchievementsNote", true, false)
	note.text = Localization.t("ach_count", {"n": Achievements.unlocked_ids().size(), "total": Achievements.LIST.size()})


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()
