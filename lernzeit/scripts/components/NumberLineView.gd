class_name NumberLineView
extends Control
## Number line 0..10 drawn in code (labels, start marker, backward jumps with
## "−1" chips and the landing point). The landing number stays hidden ("?")
## until the task is solved.

var start := 8
var jumps := 3
var max_n := 10      ## 10 or 20
var solved := false:
	set(v):
		solved = v
		queue_redraw()

const BLUE := Color("1f73e0")
const RED := Color("e8343f")
const GREEN := Color("37b84a")
const ORANGE := Color("f59a1b")


func _x(i: int) -> float:
	var margin := 60.0
	return margin + (size.x - margin * 2.0) * i / float(max_n)


func _draw() -> void:
	var f := UiTheme.font(UiTheme.FONT_XBOLD)
	var y := size.y * 0.62
	# axis with arrow
	draw_line(Vector2(20, y), Vector2(size.x - 14, y), BLUE, 8.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(size.x, y), Vector2(size.x - 30, y - 16), Vector2(size.x - 30, y + 16)]), BLUE)
	var end := start - jumps
	var fs := 44 if max_n <= 10 else 34
	for i in max_n + 1:
		var x := _x(i)
		draw_line(Vector2(x, y - 20), Vector2(x, y + 20), BLUE, 6.0, true)
		if i == start or i == end:
			continue
		var s := str(i)
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(x - w / 2.0, y + 74), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.NAVY)
	# jumps start → start-1 → ... (arcs above the line)
	for k in jumps:
		var x0 := _x(start - k)
		var x1 := _x(start - k - 1)
		var c := Vector2((x0 + x1) / 2.0, y - 10)
		var r := (x0 - x1) / 2.0
		draw_arc(c, r, PI + 0.25, TAU - 0.25, 24, RED, 6.0, true)
		var tip := Vector2(x1 + r * (1 - cos(0.25)), y - 10 - r * sin(0.25))
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-4, 14), tip + Vector2(-14, -10), tip + Vector2(12, -6)]), RED)
		# "−1" chip
		var cw := 68.0 if max_n <= 10 else 50.0
		var chip := Rect2(Vector2(c.x - cw / 2.0, y - r - (70 if max_n <= 10 else 60)), Vector2(cw, 44 if max_n <= 10 else 38))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("ffd9dc")
		sb.border_color = RED
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(18)
		sb.draw(get_canvas_item(), chip)
		var t := "−1"
		var cfs := 30 if max_n <= 10 else 24
		var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, cfs).x
		draw_string(f, Vector2(chip.get_center().x - tw / 2.0, chip.get_center().y + cfs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, cfs, RED)
	_marker(_x(start), y, str(start), BLUE)
	_marker(_x(end), y, str(end) if solved else "?", GREEN if solved else ORANGE)


func _marker(x: float, y: float, text: String, col: Color) -> void:
	var f := UiTheme.font(UiTheme.FONT_XBOLD)
	var big := max_n <= 10
	draw_circle(Vector2(x, y + 50), 38 if big else 32, Color.WHITE)
	draw_circle(Vector2(x, y + 50), 32 if big else 27, col)
	var fs := 42 if big else 34
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, Vector2(x - w / 2.0, y + 50 + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
