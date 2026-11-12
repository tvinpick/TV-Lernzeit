extends BaseScreen
## Honest placeholder: the chosen topic/level has no exercises in v0.1.

var _crumb: Label
var back_button: PillButton


func _ready() -> void:
	add_background("res://assets/backgrounds/progress_background_1080p.png")
	var sid: String = params.get("subject_id", "mathematik")
	add_title(Curriculum.title_key(sid), Curriculum.SUBJECTS[sid]["icon"])
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel("main", 70))
	panel.position = Vector2(360, 220)
	panel.size = Vector2(1200, 600)
	add_child(panel)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 26)
	panel.add_child(v)
	_crumb = Label.new()
	_crumb.theme_type_variation = &"CaptionLabel"
	_crumb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crumb.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	v.add_child(_crumb)
	v.add_child(EmptyState.make("res://assets/icons/Lernzeit_Icon_Calendar.png", "not_available", "unavailable_text"))
	var c := CenterContainer.new()
	v.add_child(c)
	back_button = PillButton.make("unavailable_back", "blue", preload("res://assets/icons/Settings_Icon_Back.png"))
	back_button.name = "BackButton"
	back_button.sound = "back"
	back_button.custom_minimum_size.x = 420
	c.add_child(back_button)
	back_button.pressed.connect(func(): main.pop())
	FocusManager.set_neighbors(back_button)
	_update_crumb()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_crumb()


func _update_crumb() -> void:
	var sid: String = params.get("subject_id", "mathematik")
	var parts := [tr(Curriculum.title_key(sid))]
	if params.has("topic_id"):
		parts.append(tr(Curriculum.topic_key(sid, params["topic_id"])))
	if params.has("level"):
		parts.append(Localization.t("level_bis", {"n": params["level"]}))
	_crumb.text = tr("breadcrumb_sep").join(parts)


func get_default_focus() -> Control:
	return back_button
