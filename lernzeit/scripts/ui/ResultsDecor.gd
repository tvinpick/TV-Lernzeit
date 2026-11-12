class_name ResultsDecor
extends RefCounted
## Decorations for the results overlay: the owl (cheering for 8+ right on the
## first try, happy otherwise) and – when one was earned – the new sticker.

static func add(results: Control, first_try_correct: int, stickers_before: int) -> void:
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
