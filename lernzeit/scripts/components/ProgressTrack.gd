class_name ProgressTrack
extends Control
## Progress bar. ratio = null → empty track (no results yet, never a fake fill).

var ratio: Variant = null
var fill_color := Color("1b7cf2")


func _ready() -> void:
	custom_minimum_size = Vector2(200, 44)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func set_ratio(r: Variant) -> void:
	ratio = r
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2(0, (size.y - 40) / 2.0), Vector2(size.x, 40))
	UiSkin.track().draw(get_canvas_item(), r)
	if ratio != null and float(ratio) > 0.0:
		var f := r.grow(-7)
		f.size.x *= clampf(float(ratio), 0.0, 1.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = fill_color
		sb.set_corner_radius_all(int(f.size.y / 2.0))
		sb.draw(get_canvas_item(), f)
