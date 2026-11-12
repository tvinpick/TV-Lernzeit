extends Node
## Dev helper: measures load/build time of each screen (desktop numbers, relative only).

func _ms(t0: int) -> String:
	return "%d ms" % ((Time.get_ticks_usec() - t0) / 1000)

func _ready() -> void:
	for p in ["res://assets/backgrounds/main_background_1080p.png", "res://assets/backgrounds/progress_background_1080p.png"]:
		var t0 := Time.get_ticks_usec()
		var tex: Texture2D = load(p)
		print("load %s %dx%d: %s" % [p.get_file(), tex.get_width(), tex.get_height(), _ms(t0)])
	var main = load("res://scenes/Main.tscn").instantiate()
	main.show_splash = false
	add_child(main)
	for i in 10: await get_tree().process_frame
	for id in ["settings", "progress", "subject", "pin", "parents", "settings"]:
		var t0 := Time.get_ticks_usec()
		var s = main.push(id, {"subject_id": "mathematik"})
		var t_build := _ms(t0)
		await RenderingServer.frame_post_draw
		print("%-9s build %s, first frame %s, nodes %d" % [id, t_build, _ms(t0), _count(s)])
		for i in 5: await get_tree().process_frame
		main.pop()
		for i in 5: await get_tree().process_frame
	# switching settings sections (rebuild on every focus move)
	var st = main.push("settings")
	await get_tree().process_frame
	for sec in ["learning", "parents", "data", "about", "general"]:
		var t0 := Time.get_ticks_usec()
		st._build_section(sec)
		await RenderingServer.frame_post_draw
		print("section %-8s %s" % [sec, _ms(t0)])
	get_tree().quit()

func _count(n: Node) -> int:
	var c := 1
	for ch in n.get_children(): c += _count(ch)
	return c
