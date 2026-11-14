extends Node
## Dev helper: runs Main and saves one screenshot after N frames.
## godot --path . res://tests/Shot.tscn -- --out=/tmp/x.png [--frames=40]

func _ready() -> void:
	var out := "user://shot.png"
	var frames := 40
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--frames="): frames = int(a.trim_prefix("--frames="))
	var main = load("res://scenes/Main.tscn").instantiate()
	main.show_splash = false
	add_child(main)
	for i in frames:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()
