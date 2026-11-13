extends Node
## Local persistence for app settings (user://settings.cfg) and the parents
## area / child profile (user://parents.cfg). No network, no accounts.
## Corrupt or missing files are replaced by valid defaults.

signal setting_changed(key: String, value: Variant)
signal parent_settings_changed

const SETTINGS_FILE := "settings.cfg"
const PARENTS_FILE := "parents.cfg"

const GENERAL_DEFAULTS := {
	"language": "de",          # de | ru
	"sound": true,
	"volume": 65,              # 0..100, step 5
	"animations": true,
	"text_size": "normal",     # normal | large
	"read_aloud": true,        # German voice-over of the tasks (Voice autoload)
	"repeat_mistakes": true,   # repeat wrongly solved tasks at the end of an exercise
	"pause_day": -1,           # local day on which the break reminder was last shown
}

const PARENT_DEFAULTS := {
	"child_name": "",
	"grade": 1,
	"subjects": {"mathematik": true, "deutsch": true, "lesen": true, "logik": true},
	"difficulty": "auto",      # easy | auto | hard
	"session_minutes": 30,     # 15 | 30 | 45 (recommendation only)
	"help_language": "de",     # de | ru
}

const MAX_NAME_LENGTH := 20

var data_dir := "user://"
var _general := {}
var _parents := {}
var _security := {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lz-data-dir="):
			data_dir = arg.trim_prefix("--lz-data-dir=")
			if not data_dir.ends_with("/"):
				data_dir += "/"
			DirAccess.make_dir_recursive_absolute(data_dir)
	load_all()


func path(file: String) -> String:
	return data_dir + file


func load_all() -> void:
	var cfg := SafeFile.load_config(path(SETTINGS_FILE))
	_general = {}
	for k in GENERAL_DEFAULTS:
		_general[k] = _validate_general(k, cfg.get_value("general", k, GENERAL_DEFAULTS[k]))
	var pcfg := SafeFile.load_config(path(PARENTS_FILE))
	_parents = {}
	for k in PARENT_DEFAULTS:
		_parents[k] = _validate_parent(k, pcfg.get_value("profile", k, PARENT_DEFAULTS[k]))
	_security = {
		"pin_salt": str(pcfg.get_value("security", "pin_salt", "")),
		"pin_hash": str(pcfg.get_value("security", "pin_hash", "")),
		"failed_attempts": int(pcfg.get_value("security", "failed_attempts", 0)),
		"lock_until": int(pcfg.get_value("security", "lock_until", 0)),
		"lock_count": int(pcfg.get_value("security", "lock_count", 0)),
	}
	# First start (or repaired file): write valid defaults immediately.
	if not FileAccess.file_exists(path(SETTINGS_FILE)):
		_save_general()
	if not FileAccess.file_exists(path(PARENTS_FILE)):
		_save_parents()


# ---------------------------------------------------------------- general ---

func get_value(key: String) -> Variant:
	return _general.get(key, GENERAL_DEFAULTS.get(key))


func set_value(key: String, value: Variant) -> void:
	if not GENERAL_DEFAULTS.has(key):
		push_error("Unknown setting " + key)
		return
	var v = _validate_general(key, value)
	if _general.get(key) == v:
		return
	_general[key] = v
	_save_general()
	setting_changed.emit(key, v)


func _validate_general(key: String, v: Variant) -> Variant:
	var d = GENERAL_DEFAULTS[key]
	match key:
		"language":
			return v if v in ["de", "ru"] else d
		"text_size":
			return v if v in ["normal", "large"] else d
		"pause_day":
			return int(v) if (v is int or v is float) else d
		"volume":
			if not (v is int or v is float):
				return d
			return clampi(int(roundf(float(v) / 5.0) * 5), 0, 100)
		_:
			return v if v is bool else d


func _save_general() -> void:
	var cfg := ConfigFile.new()
	for k in _general:
		cfg.set_value("general", k, _general[k])
	SafeFile.save_config(cfg, path(SETTINGS_FILE))


# ---------------------------------------------------------------- parents ---

## Returns a deep copy – screens edit a draft and call save_parent_settings().
func get_parent_settings() -> Dictionary:
	return _parents.duplicate(true)


func save_parent_settings(values: Dictionary) -> void:
	for k in values:
		if PARENT_DEFAULTS.has(k):
			_parents[k] = _validate_parent(k, values[k])
	_save_parents()
	parent_settings_changed.emit()


func is_subject_enabled(subject_id: String) -> bool:
	return bool(_parents["subjects"].get(subject_id, true))


func _validate_parent(key: String, v: Variant) -> Variant:
	var d = PARENT_DEFAULTS[key]
	match key:
		"child_name":
			if not (v is String):
				return d
			return v.strip_edges().substr(0, MAX_NAME_LENGTH)
		"grade":
			return 1
		"subjects":
			var out := {}
			var any := false
			for sid in d:
				var on := true
				if v is Dictionary and v.get(sid) is bool:
					on = v[sid]
				out[sid] = on
				any = any or on
			if not any:
				return d.duplicate()
			return out
		"difficulty":
			return v if v in ["easy", "auto", "hard"] else d
		"session_minutes":
			return int(v) if (v is int or v is float) and int(v) in [15, 30, 45] else d
		"help_language":
			return v if v in ["de", "ru"] else d
	return d


func _save_parents() -> void:
	var cfg := ConfigFile.new()
	for k in _parents:
		cfg.set_value("profile", k, _parents[k])
	for k in _security:
		cfg.set_value("security", k, _security[k])
	SafeFile.save_config(cfg, path(PARENTS_FILE))


# --------------------------------------------------------------- security ---

func has_pin() -> bool:
	return _security["pin_hash"] != "" and _security["pin_salt"] != ""


func set_pin(pin: String) -> bool:
	if not PinHasher.is_valid_pin(pin):
		return false
	var salt := PinHasher.new_salt()
	_security["pin_salt"] = salt
	_security["pin_hash"] = PinHasher.hash_pin(pin, salt)
	_security["failed_attempts"] = 0
	_security["lock_until"] = 0
	_security["lock_count"] = 0
	_save_parents()
	return true


## Seconds until the PIN pad unlocks again (0 = not locked).
func pin_lock_remaining() -> int:
	return maxi(0, _security["lock_until"] - int(Time.get_unix_time_from_system()))


const MAX_ATTEMPTS := 5

## Returns {"ok": bool, "remaining_attempts": int, "locked_seconds": int}
func verify_pin(pin: String) -> Dictionary:
	var locked := pin_lock_remaining()
	if locked > 0:
		return {"ok": false, "remaining_attempts": 0, "locked_seconds": locked}
	var ok := has_pin() and PinHasher.equals(PinHasher.hash_pin(pin, _security["pin_salt"]), _security["pin_hash"])
	if ok:
		_security["failed_attempts"] = 0
		_security["lock_count"] = 0
		_save_parents()
		return {"ok": true, "remaining_attempts": MAX_ATTEMPTS, "locked_seconds": 0}
	_security["failed_attempts"] += 1
	var remaining: int = MAX_ATTEMPTS - _security["failed_attempts"]
	var lock_s := 0
	if remaining <= 0:
		# 60 s after the first series of wrong PINs, 5 min after further series.
		lock_s = 60 if _security["lock_count"] == 0 else 300
		_security["lock_count"] += 1
		_security["lock_until"] = int(Time.get_unix_time_from_system()) + lock_s
		_security["failed_attempts"] = 0
		remaining = 0
	_save_parents()
	return {"ok": false, "remaining_attempts": remaining, "locked_seconds": lock_s}
