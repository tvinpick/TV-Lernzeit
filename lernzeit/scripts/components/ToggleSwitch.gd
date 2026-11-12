class_name ToggleSwitch
extends TextureButton
## On/off switch using the approved switch art. OK toggles it.

signal changed(on: bool)

var locked := false:   ## shown but not changeable (feature not yet available)
	set(v):
		locked = v
		modulate = Color(1, 1, 1, 0.45) if v else Color.WHITE


func _ready() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	texture_normal = preload("res://assets/ui/Settings_Switch_Off.png")
	texture_pressed = preload("res://assets/ui/Settings_Switch_On.png")
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(150, 88)
	toggled.connect(_on_toggled)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func set_on(on: bool) -> void:
	set_pressed_no_signal(on)
	queue_redraw()


func _on_toggled(on: bool) -> void:
	if locked:
		set_pressed_no_signal(not on)
		Sfx.play("error")
		return
	Sfx.play("toggle")
	changed.emit(on)


func _draw() -> void:
	if has_focus():
		UiTheme.focus_ring(int(size.y * 0.42)).draw(get_canvas_item(), Rect2(Vector2(4, 8), size - Vector2(8, 16)))
