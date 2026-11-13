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
	_history.clear()
	var d := SafeFile.read_json_dict(_path())
	var hd = d.get("history", {})
	if hd is Dictionary:
		for ex in hd:
			if ex is String and hd[ex] is Dictionary:
				_history[ex] = hd[ex]
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
	return SafeFile.write_text(_path(), JSON.stringify({"schema": SCHEMA, "records": arr, "letters": _letters, "history": _history}, "\t"))


# ------------------------------------------------------------ task history ---
## Per exercise: keys of the last tasks (the generator avoids them) and tasks that
## were wrong at the first try (asked again in later sessions until solved twice).

const HISTORY_KEYS := 40
const HISTORY_MISTAKES := 12
var _history := {}


func recent_task_keys(exercise_id: String) -> Array:
	var h: Dictionary = _history.get(exercise_id, {})
	return (h.get("recent", []) as Array).duplicate() if h.get("recent") is Array else []


## Stored tasks with mistakes, oldest first (numbers restored to int).
func mistake_tasks(exercise_id: String) -> Array:
	var h: Dictionary = _history.get(exercise_id, {})
	var out: Array = []
	for m in (h.get("mistakes", []) if h.get("mistakes") is Array else []):
		if m is Dictionary and m.get("task") is Dictionary:
			out.append(_intify(m["task"]))
	return out


## Exercise for "Fehler üben": the playable one with the most open mistakes in an
## enabled subject ("" if none) and how many tasks wait there.
func review_exercise() -> Array:
	for e in mistake_overview():
		var ex: String = e["exercise"]
		if ex in Curriculum.PLAYABLE.values() and SettingsRepository.is_subject_enabled(Curriculum.subject_of(ex)):
			return [ex, (e["tasks"] as Array).size()]
	return ["", 0]


## Exercises with open mistakes: [{exercise, tasks}] (most mistakes first).
func mistake_overview() -> Array:
	var out: Array = []
	for ex in _history:
		var ts := mistake_tasks(ex)
		if not ts.is_empty():
			out.append({"exercise": ex, "tasks": ts})
	out.sort_custom(func(a, b): return a["tasks"].size() > b["tasks"].size())
	return out


## results: [{task, ok}] from ExerciseSession.task_results().
func remember_session(exercise_id: String, results: Array) -> void:
	if results.is_empty():
		return
	var h: Dictionary = _history.get(exercise_id, {})
	var recent: Array = h.get("recent", []) if h.get("recent") is Array else []
	var mistakes: Array = h.get("mistakes", []) if h.get("mistakes") is Array else []
	for r in results:
		var t: Dictionary = (r["task"] as Dictionary).duplicate(true)
		t.erase("repeat")
		var key := str(t.get("key", ""))
		recent.erase(key)
		recent.append(key)
		var found := -1
		for i in mistakes.size():
			if str((mistakes[i] as Dictionary).get("task", {}).get("key", "")) == key:
				found = i
		if not r["ok"]:
			if found >= 0:
				mistakes.remove_at(found)
			mistakes.append({"task": t, "left": 2})          # must be right twice more
		elif found >= 0:
			mistakes[found]["left"] = int(mistakes[found].get("left", 1)) - 1
			if int(mistakes[found]["left"]) <= 0:
				mistakes.remove_at(found)
	h["recent"] = recent.slice(maxi(0, recent.size() - HISTORY_KEYS))
	h["mistakes"] = mistakes.slice(maxi(0, mistakes.size() - HISTORY_MISTAKES))
	_history[exercise_id] = h
	_save()


## JSON turns every number into a float; tasks need whole numbers back as int.
static func _intify(v: Variant) -> Variant:
	if v is float and v == floorf(v):
		return int(v)
	if v is Array:
		return (v as Array).map(func(x): return _intify(x))
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _intify(v[k])
		return d
	return v


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
	_history.clear()
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
