extends Node
## German voice-over (recordings in assets/voice/de/<clip>.ogg, see docs/VOICE_PHRASES.md).
## Clips are played one after another on their own "Voice" bus. "Aufgaben vorlesen"
## switches the voice on/off, "Lautstärke" sets its volume. Missing clips are skipped,
## so the app works with a partial recording set.

const DIR := "res://assets/voice/de/"
const GAP := 0.12                         ## pause between two clips of one sentence

## task prompt keys that have the same text as another recorded clip
const ALIASES := {
	"cmp_prompt_larger": "cnt_prompt_bigger",
	"sub_prompt_equation": "add_prompt_equation",
	"sub_prompt_missing": "add_prompt_missing",
	"add_prompt_to_ten": "cnt_prompt_to_ten",
	"add_prompt_to_twenty": "cnt_prompt_to_twenty",
	"lg_prompt_muster": "g_prompt_muster",
	"lg_prompt_form_thing": "g_prompt_formen",
	"lg_prompt_first": "g_prompt_reihenfolge",
	"lg_prompt_next": "g_prompt_reihenfolge_next",
	"lg_prompt_unterschiede": "g_prompt_unterschiede",
}

var _player: AudioStreamPlayer
var _bus := 0
var _queue: Array[String] = []
var _cache := {}
var _gap_timer: SceneTreeTimer
## clip names in the order they were started (used by the tests)
var history: Array[String] = []


func _ready() -> void:
	_bus = AudioServer.bus_count
	AudioServer.add_bus(_bus)
	AudioServer.set_bus_name(_bus, "Voice")
	AudioServer.set_bus_send(_bus, "Master")
	_player = AudioStreamPlayer.new()
	_player.bus = "Voice"
	add_child(_player)
	_player.finished.connect(_on_finished)
	_apply()
	SettingsRepository.setting_changed.connect(func(key: String, _v): if key in ["read_aloud", "volume"]: _apply())


func _apply() -> void:
	var vol: int = SettingsRepository.get_value("volume")
	AudioServer.set_bus_mute(_bus, not enabled())
	AudioServer.set_bus_volume_db(_bus, linear_to_db(maxf(0.001, vol / 100.0)))
	if not enabled():
		stop()


func enabled() -> bool:
	return bool(SettingsRepository.get_value("read_aloud")) and int(SettingsRepository.get_value("volume")) > 0


func clip_name(key: String) -> String:
	return ALIASES.get(key, key)


func has(clip: String) -> bool:
	return ResourceLoader.exists(DIR + clip_name(clip) + ".ogg")


func _stream(clip: String) -> AudioStream:
	if not _cache.has(clip):
		_cache[clip] = load(DIR + clip + ".ogg") if has(clip) else null
	return _cache[clip]


## Says the clips in order. interrupt = true stops what is playing now;
## false lets the current clip finish first (e.g. "Richtig!" before the next task).
## Returns false if nothing will be said (voice off or no clip recorded).
func say(clips: Array, interrupt: bool = true) -> bool:
	if not enabled():
		return false
	var list: Array[String] = []
	for c in clips:
		var n := clip_name(str(c))
		if has(n):
			list.append(n)
	if list.is_empty():
		return false
	_queue = list
	if interrupt or not _player.playing:
		_player.stop()
		_gap_timer = null
		_next()
	return true


## Says the clips only if every one of them is recorded (a sentence with a gap
## would be confusing, e.g. "Finde den Buchstaben …" without the letter).
func say_all(clips: Array, interrupt: bool = true) -> bool:
	for c in clips:
		if not has(str(c)):
			return false
	return say(clips, interrupt)


## One of several recorded variants, e.g. random_of(["ex_correct", "ex_correct_2"]).
func say_random(clips: Array, interrupt: bool = true) -> bool:
	var ok := clips.filter(func(c): return has(str(c)))
	return false if ok.is_empty() else say([ok.pick_random()], interrupt)


func stop() -> void:
	_queue.clear()
	_gap_timer = null
	if _player:
		_player.stop()


func is_speaking() -> bool:
	return _player.playing or not _queue.is_empty()


func _next() -> void:
	if _queue.is_empty():
		return
	var clip: String = _queue.pop_front()
	history.append(clip)
	_player.stream = _stream(clip)
	_player.play()


func _on_finished() -> void:
	if _queue.is_empty():
		return
	var t := get_tree().create_timer(GAP)
	_gap_timer = t
	await t.timeout
	if _gap_timer == t and not _player.playing:
		_next()


# ------------------------------------------------------------ clip helpers ---

static func num(n: int) -> String:
	return "num_%d" % n


## "Ä" → "letter_AE"; lower case letters use the same recording.
static func letter(l: String) -> String:
	var u := l.to_upper()
	return "letter_" + {"Ä": "AE", "Ö": "OE", "Ü": "UE"}.get(u, u)


## how the letter sounds at the start of a word: "M" → "sound_M" ("mmm")
static func sound(l: String) -> String:
	return letter(l).replace("letter_", "sound_")


## picture path → word clip: ".../Deutsch_L_Loewe.png" → "word_Loewe"
static func word_from_picture(path: String) -> String:
	return "word_" + path.get_file().get_basename().get_slice("_", path.get_file().get_basename().get_slice_count("_") - 1)


## "Löwe" → "word_Loewe", "Fuß" → "word_Fuss"
static func word(w: String) -> String:
	var s := w.capitalize() if w == w.to_upper() else w
	s = s.replace("ä", "ae").replace("ö", "oe").replace("ü", "ue").replace("ß", "ss")
	s = s.replace("Ä", "Ae").replace("Ö", "Oe").replace("Ü", "Ue")
	return "word_" + s


func _exit_tree() -> void:
	stop()
	if _player:
		_player.stream = null
	_cache.clear()
