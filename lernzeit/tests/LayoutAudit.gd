extends Node
## Layout audit: opens every screen / exercise mode / dialog in the current
## language + text size and reports layout problems automatically:
##   - text wider/taller than its Label (would be cut or spill out)
##   - controls outside the 1920×1080 screen
##   - controls spilling out of their panel (PanelContainer) or container
##   - TextureRects without texture (missing icon)
## godot --path . res://tests/LayoutAudit.tscn -- --lz-data-dir=DIR --lang=ru --large=1 --shots=DIR

var main: Control
var lang := "de"
var large := false
var shots_dir := ""
var issues := 0
var screens := 0
var _seen := {}
var focus_checked := 0


func _ready() -> void:
	OS.low_processor_usage_mode = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="): lang = a.trim_prefix("--lang=")
		if a.begins_with("--large="): large = a.trim_prefix("--large=") == "1"
		if a.begins_with("--shots="): shots_dir = a.trim_prefix("--shots=")
	if shots_dir != "":
		DirAccess.make_dir_recursive_absolute(shots_dir)
	SettingsRepository.set_value("language", lang)
	SettingsRepository.set_value("text_size", "large" if large else "normal")
	SettingsRepository.set_value("animations", false)     # static frames for measuring
	# some progress so that progress / letters / achievements / stickers have content
	for i in 4:
		ProgressRepository.add_record(ProgressRecord.create("mathematik", ["zaehlen", "addition", "subtraktion", "vergleichen"][i], 8, 10, 300, "count10-v1", int(Time.get_unix_time_from_system()) - i * 3600))
	ProgressRepository.add_record(ProgressRecord.create("deutsch", "buchstaben", 10, 10, 200, "de-letters-v1"))
	ProgressRepository.add_record(ProgressRecord.create("lesen", "silben", 6, 10, 200, "lesen-v1"))
	for l in ["M", "A", "O", "L", "S"]:
		ProgressRepository.add_letter_results({l: true})
		ProgressRepository.add_letter_results({l: true})
		ProgressRepository.add_letter_results({l: true})
	ProgressRepository.add_letter_results({"R": false})
	SettingsRepository.save_parent_settings({"child_name": "Maximilian"})
	main = load("res://scenes/Main.tscn").instantiate()
	main.show_splash = false
	add_child(main)
	await frames(10)
	await run_all()
	print("LAYOUT AUDIT [%s%s]: %d screens, %d focusable controls checked, %d issues" % [lang, " large" if large else "", screens, focus_checked, issues])
	get_tree().quit(1 if issues > 0 else 0)


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func check_screen(tag: String) -> void:
	await frames(6)
	screens += 1
	var before := issues
	_walk(main, tag)
	_focus_audit(tag)
	if shots_dir != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shots_dir.path_join("%s_%s%s.png" % [tag, lang, "_L" if large else ""]))
	print("  %-38s %s" % [tag, "ok" if issues == before else "%d issue(s)" % (issues - before)])


func _report(tag: String, n: Node, msg: String) -> void:
	var key := "%s|%s|%s" % [tag.split(":")[0], main.get_path_to(n), msg.split("(")[0]]
	if _seen.has(key):
		return
	_seen[key] = true
	issues += 1
	print("    ISSUE %s  %s: %s" % [tag, str(main.get_path_to(n)).right(70), msg])


func _text_of(l: Label) -> String:
	return l.atr(l.text) if l.auto_translate_mode != Node.AUTO_TRANSLATE_MODE_DISABLED else l.text


func _walk(n: Node, tag: String) -> void:
	if n is CanvasItem and not (n as CanvasItem).visible:
		return
	if n is Control:
		_check(n as Control, tag)
	for c in n.get_children():
		_walk(c, tag)


func _scroll_ancestor(c: Control) -> ScrollContainer:
	var p := c.get_parent()
	while p:
		if p is ScrollContainer:
			return p
		p = p.get_parent()
	return null


func _panel_ancestor(c: Control) -> PanelContainer:
	var p := c.get_parent()
	while p and p != main:
		if p is PanelContainer:
			return p
		if p is ScrollContainer:
			return null
		p = p.get_parent()
	return null


func _check(c: Control, tag: String) -> void:
	if c.z_index >= 40 or c.has_meta("audit_skip"):
		return
	var r := c.get_global_rect()
	if r.size.x < 1 or r.size.y < 1:
		return
	var tol := 3.0
	var scroll := _scroll_ancestor(c)
	# 1. on screen (scroll content is checked horizontally only)
	if r.position.x < -tol or r.end.x > 1920 + tol or (scroll == null and (r.position.y < -tol or r.end.y > 1080 + tol)):
		if not (c is TextureRect and r.size.x >= 1900):     # full-screen backgrounds
			_report(tag, c, "outside the screen %s" % r)
	# 2. inside the panel it belongs to
	var panel := _panel_ancestor(c)
	if panel:
		var pr := panel.get_global_rect()
		if r.position.x < pr.position.x - tol or r.end.x > pr.end.x + tol or r.position.y < pr.position.y - tol or r.end.y > pr.end.y + tol:
			_report(tag, c, "spills out of its panel %s (panel %s)" % [r, pr])
	if scroll:
		var sr := scroll.get_global_rect()
		if r.position.x < sr.position.x - tol or r.end.x > sr.end.x + tol:
			_report(tag, c, "wider than its scroll area %s (area %s)" % [r, sr])
	# 3. text fits its label
	if c is Label:
		var l := c as Label
		var txt := _text_of(l)
		if txt.strip_edges() == "":
			return
		var f := l.get_theme_font("font")
		var fs := l.get_theme_font_size("font_size")
		if l.autowrap_mode == TextServer.AUTOWRAP_OFF:
			var w := 0.0
			for line in txt.split("\n"):
				w = maxf(w, f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
			if w > l.size.x + 4:
				_report(tag, l, "text '%s' %s (%d > %d)" % [txt.left(30), "is cut off" if l.clip_text else "wider than its label", w, l.size.x])
		var needed := l.get_line_count() * (f.get_height(fs) + l.get_theme_constant("line_spacing"))
		if needed > l.size.y + 6 and (l.max_lines_visible < 0):
			_report(tag, l, "text '%s' taller than its label (%d > %d)" % [txt.left(30), needed, l.size.y])
	# 4. button text fits
	if c is Button and (c as Button).text != "" and not (c as Button).clip_text:
		var b := c as Button
		if b.get_minimum_size().x > b.size.x + 4:
			_report(tag, b, "button text does not fit (%d > %d)" % [b.get_minimum_size().x, b.size.x])
	# 5. missing textures
	if c is TextureRect and (c as TextureRect).texture == null and not c.has_meta("may_be_empty"):
		_report(tag, c, "TextureRect without texture")


# ---------------------------------------------------------------- screens ---

func run_all() -> void:
	if OS.get_cmdline_user_args().has("--selftest"):
		var b := Button.new()
		b.text = "X"
		b.position = Vector2(900, 700)
		main.current_screen().add_child(b)
		FocusManager.set_neighbors(b)          # isolated: no arrow leads to it
		var gear: Control = main.current_screen().gear
		FocusManager.set_one(gear, SIDE_BOTTOM, b)
		b.visible = true
		var g2 := Button.new()
		g2.text = "Y"
		g2.position = Vector2(1000, 700)
		main.current_screen().add_child(g2)
		FocusManager.set_neighbors(g2)
	await check_screen("home")
	for sid in Curriculum.SUBJECT_IDS:
		var s = main.push("subject", {"subject_id": sid})
		await check_screen("subject_" + sid)
		if sid == "mathematik":
			s.topic_buttons[0].grab_focus()
			await check_screen("subject_math_levels")
		main.pop()
	main.push("unavailable", {"subject_id": "mathematik", "topic_id": "zaehlen", "level": 100})
	await check_screen("unavailable")
	main.pop()
	main.push("progress")
	await check_screen("progress")
	for sid in Curriculum.SUBJECT_IDS:
		main.push("progress_detail", {"subject_id": sid})
		await check_screen("progress_detail_" + sid)
		main.pop()
	main.push("achievements")
	await check_screen("achievements")
	main.pop()
	main.push("stickers")
	await check_screen("stickers")
	main.pop()
	main.pop()
	var st = main.push("settings")
	for sec in ["general", "learning", "parents", "data", "about"]:
		st._build_section(sec)
		await check_screen("settings_" + sec)
		# scrolled to the bottom as well
		st._scroll.scroll_vertical = 100000
		await check_screen("settings_%s_bottom" % sec)
	main.pop()
	main.push("pin", {"mode": "enter"})
	await check_screen("pin")
	main.pop()
	var pd = main.push("parents")
	await check_screen("parents")
	pd._scroll.scroll_vertical = 100000
	await check_screen("parents_bottom")
	pd._edit_name()
	await check_screen("parents_name_popup")
	main.overlay().get_child(main.overlay().get_child_count() - 1).close_popup()
	await frames(3)
	main.push("letters")
	await check_screen("letters")
	main.pop()
	main.pop()
	main._ask_exit()
	await check_screen("dialog_exit")
	main.top_dialog().cancel()
	var d := ConfirmDialog.make("pause_title", Localization.t("pause_message", {"n": 30}), "pause_home", "green", "pause_continue")
	d.image = preload("res://assets/mascot/owl/Mascot_Owl_Sleep.png")
	main.show_dialog(d)
	await check_screen("dialog_pause")
	d.cancel()
	var dr := ConfirmDialog.make("p_reset_title", Localization.t("p_reset_message", {"n": 12}), "p_reset_button", "red")
	main.show_dialog(dr)
	await check_screen("dialog_reset")
	dr.cancel()
	await frames(3)
	# every mode of every exercise, in all difficulties' widest cases
	for ex_id in ["count10", "add10", "sub10", "count20", "add20", "sub20", "cmp10", "zr20"]:
		await audit_exercise("exercise", ex_id)
	for ex_id in ["de_letters", "le_woerter", "lg_muster", "lg_formen", "lg_reihenfolge"]:
		await audit_exercise("exercise_de", ex_id)


func audit_exercise(screen_id: String, ex_id: String) -> void:
	var ex = main.push(screen_id, {"exercise": ex_id, "seed": 4})
	await frames(4)
	for diff in ["easy", "hard"]:
		ex.generator.difficulty = diff
		for m in ex.generator.modes():
			for k in 2:                       # two samples per mode (different sizes)
				ex.session.tasks[0] = ex.generator.make_task(m)
				ex._show_task()
				await check_screen("%s:%s:%s" % [ex_id, m, diff])
				if screen_id == "exercise_de":
					_check_stage_above_answers(ex, "%s:%s:%s" % [ex_id, m, diff])
	# tip state + results overlay
	ex._prompt.set_wrapped(true, 30)
	ex._prompt.text = Localization.t("ex_tip", {"t": tr("tip_sub_missing").format({"a": 18, "r": 9})})
	await check_screen(ex_id + ":tip")
	ex.session.solved = 10
	ex.session.first_try_correct = 9
	ex._finish()
	await frames(4)
	await check_screen(ex_id + ":results")
	main.pop()
	await frames(3)


# ------------------------------------------------------------ focus graph ---

func _focus_root() -> Control:
	var d = main.top_dialog()
	if d:
		return d
	for c in main.overlay().get_children():
		if c.has_method("close_popup") and not c.is_queued_for_deletion():
			return c
	return main.current_screen()


func _focusable(c: Control) -> bool:
	if not c.is_visible_in_tree() or c.focus_mode == Control.FOCUS_NONE or c is ScrollBar:
		return false
	if c is BaseButton and (c as BaseButton).disabled:
		return false
	return true


func _collect_focusable(n: Node, out: Array) -> void:
	if n is CanvasItem and not (n as CanvasItem).visible:
		return
	if n is Control and _focusable(n):
		out.append(n)
	for c in n.get_children():
		_collect_focusable(c, out)


## From the focused control, follow the remote's arrow keys (explicit focus
## neighbours or Godot's automatic choice) and check that every visible,
## enabled control of the screen can be reached and no arrow leads to a dead control.
func _focus_audit(tag: String) -> void:
	var root := _focus_root()
	if root == null:
		return
	var start := get_viewport().gui_get_focus_owner()
	var all: Array = []
	_collect_focusable(root, all)
	if all.is_empty():
		return
	if start == null or not root.is_ancestor_of(start):
		_report(tag, root, "nothing focused on this screen (remote cannot start)")
		return
	var seen := {start: true}
	var queue: Array = [start]
	while not queue.is_empty():
		var c: Control = queue.pop_front()
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			var path: NodePath = c.get_focus_neighbor(side)
			var n: Control = null
			if path != NodePath(""):
				n = c.get_node_or_null(path) as Control
				if n == null:
					_report(tag, c, "arrow %d points to a missing node" % side)
					continue
			elif c.has_method("find_valid_focus_neighbor"):
				n = c.find_valid_focus_neighbor(side)
			if n == null or n == c:
				continue
			if not _focusable(n):
				# Godot skips such neighbours by itself only for automatic navigation
				if path != NodePath(""):
					_report(tag, c, "arrow %d leads to a hidden/disabled control %s" % [side, n.name])
				continue
			if not seen.has(n):
				seen[n] = true
				queue.append(n)
	focus_checked += all.size()
	# buttons must not be covered by / collide with panels they don't belong to
	var panels: Array = []
	_collect_panels(main, panels)
	for f in all:
		var fr: Rect2 = (f as Control).get_global_rect().grow(-6)
		for pnl in panels:
			if pnl == f or pnl.is_ancestor_of(f) or (f as Control).is_ancestor_of(pnl):
				continue
			if not root.is_ancestor_of(pnl) and pnl != root:
				continue
			var pr: Rect2 = (pnl as Control).get_global_rect()
			var sc := _scroll_ancestor(pnl)
			if sc:                       # rows of a scroll list are only visible inside it
				pr = pr.intersection(sc.get_global_rect())
			if pr.size.x > 0 and fr.intersects(pr.grow(-6)):
				_report(tag, f, "overlaps panel %s" % pnl.name)
	for c in all:
		if not seen.has(c) and root.is_ancestor_of(c):
			_report(tag, c, "cannot be reached with the arrow keys")


func _collect_panels(n: Node, out: Array) -> void:
	if n is CanvasItem and not (n as CanvasItem).visible:
		return
	if n is PanelContainer and not n.has_meta("audit_skip"):
		out.append(n)
	for c in n.get_children():
		_collect_panels(c, out)


## The task picture / word area must not reach into the row of answer buttons.
func _check_stage_above_answers(ex, tag: String) -> void:
	var top := INF
	for b in ex.active_buttons():
		top = minf(top, (b as Control).get_global_rect().position.y)
	var bottom := 0.0
	var stack: Array = ex._stage.get_children()
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		stack.append_array(c.get_children())
		var drawn: bool = (c is TextureRect and (c as TextureRect).texture != null) or c is PanelContainer
		if drawn and (c as Control).is_visible_in_tree() and (c as Control).size.y > 0:
			bottom = maxf(bottom, (c as Control).get_global_rect().end.y)
	if bottom > top - 6:
		_report(tag, ex._stage, "task picture reaches the answer buttons (%d > %d)" % [bottom, top - 6])
