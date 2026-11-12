extends Node
## Progress storage behind an interface – UI never touches the JSON file.
## v0.1 contains no exercises, therefore the repository starts empty and all
## screens show honest empty states. add_record() is ready for later versions.

signal progress_changed

const FILE := "progress.json"
const SCHEMA := 1

var _records: Array[ProgressRecord] = []
## Per-letter history for "Gelernte Buchstaben": letter -> "10110…" (1 = right on the first
## try), newest last, at most LETTER_HISTORY entries.
var _letters := {}
const LETTER_HISTORY := 10


func _ready() -> void:
	# SettingsRepository is loaded first and resolves the data directory.
	load_records()


func _path() -> String:
	return SettingsRepository.path(FILE)


func load_records() -> void:
	_records.clear()
	_letters.clear()
	var d := SafeFile.read_json_dict(_path())
	var ld = d.get("letters", {})
	if ld is Dictionary:
		for k in ld:
			if k is String and k.length() == 1 and ld[k] is String:
				_letters[k] = (ld[k] as String).replace("2", "").right(LETTER_HISTORY)
	for item in d.get("records", []):
		if item is Dictionary:
			var r := ProgressRecord.from_dict(item)
			if r != null:
				_records.append(r)
	if not FileAccess.file_exists(_path()):
		_save()


func _save() -> bool:
	var arr := []
	for r in _records:
		arr.append(r.to_dict())
	return SafeFile.write_text(_path(), JSON.stringify({"schema": SCHEMA, "records": arr, "letters": _letters}, "\t"))


func add_record(r: ProgressRecord) -> void:
	_records.append(r)
	_save()
	progress_changed.emit()


func record_count() -> int:
	return _records.size()


func get_records(subject_id: String = "", topic_id: String = "") -> Array[ProgressRecord]:
	var out: Array[ProgressRecord] = []
	for r in _records:
		if (subject_id == "" or r.subject_id == subject_id) and (topic_id == "" or r.topic_id == topic_id):
			out.append(r)
	out.sort_custom(func(a, b): return a.timestamp > b.timestamp)
	return out


## Deletes all learning records (settings and profile stay untouched).
func reset_all() -> int:
	var n := _records.size()
	_records.clear()
	_letters.clear()
	_save()
	progress_changed.emit()
	return n


## Aggregates for a subject ("" = all subjects).
## accuracy is null when nothing was answered yet (never shows 0/0 as a percent).
func summary(subject_id: String = "") -> Dictionary:
	var correct := 0
	var total := 0
	var seconds := 0
	var topics := {}
	var last := 0
	for r in get_records(subject_id):
		correct += r.correct_count
		total += r.total_count
		seconds += r.duration_seconds
		topics[r.subject_id + "/" + r.topic_id] = true
		last = maxi(last, r.timestamp)
	return {
		"tasks_solved": total,
		"correct": correct,
		"accuracy": (float(correct) / float(total)) if total > 0 else null,
		"topics_practiced": topics.size(),
		"duration_seconds": seconds,
		"last_timestamp": last,
		"sessions": get_records(subject_id).size(),
	}


## "not_started" until real records exist. Later: "practice" | "good" | "secure".
func topic_status(subject_id: String, topic_id: String) -> String:
	var recs := get_records(subject_id, topic_id)
	if recs.is_empty():
		return "not_started"
	var s := 0.0
	var t := 0
	for r in recs:
		s += r.correct_count
		t += r.total_count
	if t == 0:
		return "not_started"
	var acc := s / t
	if acc >= 0.9:
		return "secure"
	if acc >= 0.7:
		return "good"
	return "practice"


# ----------------------------------------------------------------- letters ---

## results: {"M": true, "A": false}  (true = right on the first try)
func add_letter_results(results: Dictionary) -> void:
	if results.is_empty():
		return
	for l in results:
		var key := (l as String).to_upper()
		var h: String = _letters.get(key, "")
		h = (h + ("1" if results[l] else "0")).right(LETTER_HISTORY)
		_letters[key] = h
	_save()
	progress_changed.emit()


## "not_started" | "practice" | "secure"
## secure = at least 3 answers and >= 80 % right on the first try among the last 5.
func letter_status(letter: String) -> String:
	var h: String = _letters.get(letter.to_upper(), "")
	if h.is_empty():
		return "not_started"
	var last := h.right(5)
	if h.length() >= 3 and float(last.count("1")) / last.length() >= 0.8:
		return "secure"
	return "practice"


func letter_history(letter: String) -> String:
	return _letters.get(letter.to_upper(), "")


func letters_with_status(status: String) -> Array:
	var out: Array = []
	for l in _letters:
		if letter_status(l) == status:
			out.append(l)
	out.sort()
	return out
