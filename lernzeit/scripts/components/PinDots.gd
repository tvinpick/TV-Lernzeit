class_name PinDots
extends Control
## Four hidden PIN positions (filled circles for entered digits).

var count := 0:
	set(v):
		count = v
		queue_redraw()
var error := false:
	set(v):
		error = v
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(420, 90)


func _draw() -> void:
	var n := PinHasher.PIN_LENGTH
	var gap := 100.0
	var start := size.x / 2.0 - gap * (n - 1) / 2.0
	for i in n:
		var c := Vector2(start + gap * i, size.y / 2.0)
		draw_circle(c, 32, Color(1, 1, 1, 0.92))
		draw_circle(c, 32, Color("ff6b6b") if error else Color("7fa8ff"), false, 4.0, true)
		if i < count:
			draw_circle(c, 17, UiTheme.NAVY)
