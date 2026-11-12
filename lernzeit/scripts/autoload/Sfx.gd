extends Node
## Short UI sounds on their own "UI" audio bus. "Soundeffekte" mutes the bus,
## "Lautstärke" sets its volume (0–100 %). Sounds are self-generated (tools/make_sounds.py).

const SOUNDS := {
	"move": preload("res://assets/sounds/move.wav"),
	"select": preload("res://assets/sounds/select.wav"),
	"back": preload("res://assets/sounds/back.wav"),
	"toggle": preload("res://assets/sounds/toggle.wav"),
	"error": preload("res://assets/sounds/error.wav"),
	"streak": preload("res://assets/sounds/streak.wav"),
	"pop": preload("res://assets/sounds/pop.wav"),
	"pause": preload("res://assets/sounds/pause.wav"),
}

var _players: Array[AudioStreamPlayer] = []
var _bus := 0
var _next := 0


func _ready() -> void:
	_bus = AudioServer.bus_count
	AudioServer.add_bus(_bus)
	AudioServer.set_bus_name(_bus, "UI")
	AudioServer.set_bus_send(_bus, "Master")
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.bus = "UI"
		add_child(p)
		_players.append(p)
	_apply()
	SettingsRepository.setting_changed.connect(_on_setting_changed)


func _on_setting_changed(key: String, _value: Variant) -> void:
	if key in ["sound", "volume"]:
		_apply()


func _apply() -> void:
	var on: bool = SettingsRepository.get_value("sound")
	var vol: int = SettingsRepository.get_value("volume")
	AudioServer.set_bus_mute(_bus, (not on) or vol == 0)
	AudioServer.set_bus_volume_db(_bus, linear_to_db(maxf(0.001, vol / 100.0)))


func bus_index() -> int:
	return _bus


func play(name: String) -> void:
	if not SOUNDS.has(name):
		return
	if AudioServer.is_bus_mute(_bus):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = SOUNDS[name]
	p.play()
