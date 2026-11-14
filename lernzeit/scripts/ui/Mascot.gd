class_name Mascot
extends RefCounted
## The schoolgirl owl (assets/mascot/owl). Poses: idle, happy, thinking, cheer, sleep, wave.

static func texture(pose: String) -> Texture2D:
	return load("res://assets/mascot/owl/Mascot_Owl_%s.png" % pose.capitalize())


## Owl sprite that gently bobs up and down (or stands still without animations).
static func make(pose: String, size: float, pos: Vector2) -> TextureRect:
	var o := TextureRect.new()
	o.texture = texture(pose)
	o.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	o.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	o.size = Vector2(size, size)
	o.position = pos
	o.pivot_offset = Vector2(size / 2.0, size)
	o.mouse_filter = Control.MOUSE_FILTER_IGNORE
	o.z_index = 20
	return o


static func bob(o: Control) -> void:
	if not AppState.animations_enabled() or not is_instance_valid(o):
		return
	var y := o.position.y
	var tw := o.create_tween().set_loops()
	tw.tween_property(o, "position:y", y - 14, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(o, "position:y", y, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Pop-in from below.
static func appear(o: Control) -> void:
	if not AppState.animations_enabled():
		return
	o.scale = Vector2.ZERO
	var tw := o.create_tween()
	tw.tween_property(o, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(bob.bind(o))
