class_name Juice
extends RefCounted
## "Game feel" effects shared by all exercises. Everything is skipped when the
## "Animationen" setting is off (the result is shown immediately instead).
## Positions are in the host's local coordinates (screens fill the 1920×1080 canvas).

const STAR := preload("res://assets/math/shared_ui/Object_Star_Yellow.png")
const CONFETTI := [Color("ff5d73"), Color("ffc531"), Color("39c26b"), Color("3a8dff"), Color("b05cff"), Color("2fd3e0")]


static func on() -> bool:
	return AppState.animations_enabled()


## Stars + confetti bursting out of `center`, falling with a little gravity.
static func burst(host: Control, center: Vector2, stars: int = 7, confetti: int = 16) -> void:
	if not on():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in stars + confetti:
		var is_star := i < stars
		var p: Control
		if is_star:
			var t := TextureRect.new()
			t.texture = STAR
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var s := rng.randf_range(38, 64)
			t.size = Vector2(s, s)
			p = t
		else:
			var c := ColorRect.new()
			c.color = CONFETTI[rng.randi_range(0, CONFETTI.size() - 1)]
			c.size = Vector2(rng.randf_range(10, 16), rng.randf_range(16, 26))
			p = c
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.pivot_offset = p.size / 2.0
		p.position = center - p.size / 2.0
		p.z_index = 50
		host.add_child(p)
		var ang := rng.randf_range(-PI, 0.0) if is_star else rng.randf_range(-PI * 0.95, -PI * 0.05)
		var dist := rng.randf_range(140, 300) if is_star else rng.randf_range(160, 380)
		var peak := center + Vector2(cos(ang), sin(ang)) * dist
		var land := peak + Vector2(rng.randf_range(-40, 40), rng.randf_range(120, 260))
		var dur := rng.randf_range(0.75, 1.1)
		var tw := host.create_tween().set_parallel()
		tw.tween_property(p, "position", peak - p.size / 2.0, dur * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "position", land - p.size / 2.0, dur * 0.6).set_delay(dur * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(p, "rotation", rng.randf_range(-6.0, 6.0), dur)
		tw.tween_property(p, "modulate:a", 0.0, dur * 0.35).set_delay(dur * 0.65)
		tw.chain().tween_callback(p.queue_free)


## A star flies from `from` to `to` (e.g. into the progress dots), then `on_arrive` runs.
static func fly_star(host: Control, from: Vector2, to: Vector2, on_arrive: Callable = Callable()) -> void:
	if not on():
		if on_arrive.is_valid():
			on_arrive.call()
		return
	var t := TextureRect.new()
	t.texture = STAR
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size = Vector2(80, 80)
	t.pivot_offset = t.size / 2.0
	t.position = from - t.size / 2.0
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.z_index = 60
	host.add_child(t)
	var mid := (from + to) / 2.0 + Vector2(0, -160)
	var tw := host.create_tween()
	tw.tween_method(func(k: float):
		var a := from.lerp(mid, k)
		var b := mid.lerp(to, k)
		t.position = a.lerp(b, k) - t.size / 2.0
		t.scale = Vector2.ONE * lerpf(1.0, 0.45, k)
		t.rotation = k * TAU, 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		t.queue_free()
		if on_arrive.is_valid():
			on_arrive.call())


## Elastic "pop" of a control (scale up and back).
static func pop(c: Control, amount: float = 1.25) -> void:
	if not on() or not is_instance_valid(c):
		return
	c.pivot_offset = c.size / 2.0
	var base := c.scale
	var tw := c.create_tween()
	tw.tween_property(c, "scale", base * amount, 0.09).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(c, "scale", base, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Big banner text in the middle that zooms in and fades away ("3 richtig in Folge!").
static func banner(host: Control, text: String, color: Color = Color("ffb300"), y: float = 470.0) -> void:
	var l := Label.new()
	l.text = text
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
	l.add_theme_font_size_override("font_size", 84)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 18)
	l.add_theme_color_override("font_outline_color", Color.WHITE)
	l.add_theme_color_override("font_shadow_color", Color(0.1, 0.1, 0.35, 0.45))
	l.add_theme_constant_override("shadow_offset_y", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = Vector2(1920, 140)
	l.position = Vector2(0, y - 70)
	l.pivot_offset = l.size / 2.0
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_index = 70
	host.add_child(l)
	if not on():
		host.get_tree().create_timer(1.2).timeout.connect(l.queue_free)
		return
	l.scale = Vector2.ONE * 0.3
	l.modulate.a = 0.0
	var tw := host.create_tween()
	tw.set_parallel()
	tw.tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 1.0, 0.15)
	tw.chain().tween_interval(0.7)
	tw.chain().tween_property(l, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(l.queue_free)


## Gentle repeating glow on the correct answer after a second mistake (hint).
static func hint_pulse(c: Control) -> void:
	if not is_instance_valid(c):
		return
	c.set_meta("hint", true)
	if not on():
		c.modulate = Color(1.15, 1.15, 0.85)
		return
	var tw := c.create_tween().set_loops(4)
	tw.tween_property(c, "modulate", Color(1.3, 1.3, 0.8), 0.35)
	tw.tween_property(c, "modulate", Color.WHITE, 0.35)


## Numbers 1, 2, 3 … appear one by one on the given controls (counting help).
static func count_overlay(host: Control, items: Array) -> void:
	var i := 0
	for c in items:
		if not is_instance_valid(c):
			continue
		i += 1
		var l := Label.new()
		l.text = str(i)
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		l.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_XBOLD))
		l.add_theme_font_size_override("font_size", 40)
		l.add_theme_color_override("font_color", Color.WHITE)
		l.add_theme_constant_override("outline_size", 12)
		l.add_theme_color_override("font_outline_color", Color("1f5fd6"))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = Vector2(60, 60)
		var r: Rect2 = (c as Control).get_global_rect()
		l.global_position = r.get_center() - l.size / 2.0
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.z_index = 40
		l.pivot_offset = l.size / 2.0
		host.add_child(l)
		if on():
			l.scale = Vector2.ZERO
			var tw := host.create_tween()
			tw.tween_interval(0.3 * i)
			tw.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_callback(Sfx.play.bind("move"))
