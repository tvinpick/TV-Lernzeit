class_name ResultsDecor
extends RefCounted
## Decorations for the results overlay: the owl (cheering for 8+ right on the
## first try, happy otherwise) and – when one was earned – the new sticker.

static func add(results: Control, first_try_correct: int, stickers_before: int, xp_before: int = -1) -> void:
	if xp_before >= 0:
		_add_xp(results, xp_before)
	var owl := Mascot.make("cheer" if first_try_correct >= 8 else "happy", 330, Vector2(150, 560))
	owl.name = "ResultsOwl"
	results.add_child(owl)
	Mascot.appear(owl)
	var now := Achievements.stickers_earned()
	if now > stickers_before:
		var box := VBoxContainer.new()
		box.name = "NewSticker"
		box.position = Vector2(1460, 520)
		box.size = Vector2(320, 380)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.z_index = 20
		results.add_child(box)
		var l := Label.new()
		l.text = "sticker_new"
		l.theme_type_variation = &"OnDarkBody"
		l.add_theme_font_size_override("font_size", 36)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)
		var st := TextureRect.new()
		st.texture = load(Achievements.sticker_path(now))
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		st.custom_minimum_size = Vector2(260, 260)
		st.pivot_offset = Vector2(130, 130)
		box.add_child(st)
		if AppState.animations_enabled():
			st.scale = Vector2.ZERO
			st.rotation = -0.6
			var tw := st.create_tween().set_parallel()
			tw.tween_property(st, "scale", Vector2.ONE, 0.5).set_delay(0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(st, "rotation", 0.0, 0.5).set_delay(0.9)
			tw.chain().tween_callback(Sfx.play.bind("pop"))


## XP bar at the bottom: fills with the points of this exercise, "Neue Stufe!" on a level-up.
static func _add_xp(results: Control, xp_before: int) -> void:
	var now := Progression.xp_total()
	var box := VBoxContainer.new()
	box.name = "XpBox"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# inside the results panel, above the buttons
	var v: VBoxContainer = null
	for c in results.find_children("*", "VBoxContainer", true, false):
		if c.get_parent() is PanelContainer:
			v = c
			break
	if v:
		v.add_child(box)
		v.move_child(box, v.get_child_count() - 2)
	else:
		box.position = Vector2(560, 905)
		results.add_child(box)
	var gain := Label.new()
	gain.name = "XpGain"
	gain.theme_type_variation = &"RowTitle"
	gain.add_theme_color_override("font_color", Color("c26a00"))
	gain.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	gain.text = Localization.t("xp_gain", {"n": now - xp_before})
	gain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(gain)
	var bar := XpBar.make(620)
	bar.name = "XpBar"
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(bar)
	bar.show_xp(xp_before)
	bar.level_up.connect(func(n: int):
		Sfx.play("streak")
		Juice.banner(results, Localization.t("level_up", {"n": n}), Color("ff9b1a"), 600)
		Juice.burst(results, bar.get_global_rect().get_center(), 12, 26))
	await results.get_tree().create_timer(0.7).timeout
	if is_instance_valid(bar):
		bar.animate(xp_before, now)
