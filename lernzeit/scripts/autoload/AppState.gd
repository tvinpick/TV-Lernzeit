extends Node
## Global UI state: input mapping for the Sony remote, current theme
## (text size), animation preference and app version.

signal theme_changed(theme: Theme)

const APP_VERSION_FALLBACK := "0.1.0"

## Background art is decoded once at start-up and kept in memory, so
## opening a screen never re-decodes it.
const RESIDENT_TEXTURES := [
	"res://assets/backgrounds/main_background_1080p.png",
	"res://assets/backgrounds/progress_background_1080p.png",
]

var theme: Theme
var _last_back_ms := -10000
var _textures := {}


func _ready() -> void:
	_setup_input()
	for p in RESIDENT_TEXTURES:
		_textures[p] = load(p)
	theme = UiTheme.build(text_scale())
	SettingsRepository.setting_changed.connect(_on_setting_changed)


func texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path)
	return _textures[path]


func app_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", APP_VERSION_FALLBACK))


func animations_enabled() -> bool:
	return bool(SettingsRepository.get_value("animations"))


func text_scale() -> float:
	return 1.18 if SettingsRepository.get_value("text_size") == "large" else 1.0


func _on_setting_changed(key: String, _value: Variant) -> void:
	if key == "text_size":
		theme = UiTheme.build(text_scale())
		theme_changed.emit(theme)


## Android delivers BACK both as a go-back request and (on some remotes) as a key
## event – this guard makes one physical press count once.
func accept_back_press() -> bool:
	var now := Time.get_ticks_msec()
	if now - _last_back_ms < 250:
		return false
	_last_back_ms = now
	return true


func _setup_input() -> void:
	# D-pad / OK: keyboard keys (remote as keyboard) + joypad (remote as D-pad device).
	_add_joy("ui_up", JOY_BUTTON_DPAD_UP)
	_add_joy("ui_down", JOY_BUTTON_DPAD_DOWN)
	_add_joy("ui_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy("ui_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy("ui_accept", JOY_BUTTON_A)
	_add_key("ui_accept", KEY_ENTER)
	_add_key("ui_accept", KEY_KP_ENTER)
	if not InputMap.has_action("lz_back"):
		InputMap.add_action("lz_back")
	_add_key("lz_back", KEY_ESCAPE)
	_add_key("lz_back", KEY_BACK)
	_add_key("lz_back", KEY_BACKSPACE)
	_add_joy("lz_back", JOY_BUTTON_B)


func _add_key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.keycode = key
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and e.keycode == key:
			return
	InputMap.action_add_event(action, ev)


func _add_joy(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and e.button_index == button:
			return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
