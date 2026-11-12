class_name ExerciseSession
extends RefCounted
## One practice session (10 tasks). Progress only advances on correct answers;
## "first try" correctness is what gets stored. With "Fehler wiederholen" on,
## up to 3 tasks that were wrong on the first try are asked again at the end
## (repetitions do not change the stored counts).

const MAX_REPEATS := 3

var subject_id := ""
var topic_id := ""
var version := ""
var tasks: Array = []
var main_count := 0
var index := 0
var solved := 0              ## main tasks solved (any attempt)
var first_try_correct := 0
var attempts := 0
var repeat_enabled := true
var _current_wrong := false
var _wrong_first: Array = []
var _repeats_added := false
var _start_ms := 0


func _init(p_subject: String, p_topic: String, p_version: String, p_tasks: Array, p_repeat: bool) -> void:
	subject_id = p_subject
	topic_id = p_topic
	version = p_version
	tasks = p_tasks
	main_count = p_tasks.size()
	repeat_enabled = p_repeat
	_start_ms = Time.get_ticks_msec()


func current() -> Dictionary:
	return tasks[index] if index < tasks.size() else {}


func is_repeat() -> bool:
	return current().get("repeat", false)


## Returns true when the value is correct.
func submit(value: int) -> bool:
	var t := current()
	if t.is_empty():
		return false
	attempts += 1
	if value == t["answer"]:
		if not t.get("repeat", false):
			solved += 1
			if not _current_wrong:
				first_try_correct += 1
		return true
	if not _current_wrong and not t.get("repeat", false):
		_wrong_first.append(t)
	_current_wrong = true
	return false


func was_wrong_this_task() -> bool:
	return _current_wrong


## Moves to the next task; returns false when the session is finished.
func advance() -> bool:
	index += 1
	_current_wrong = false
	if index >= tasks.size() and repeat_enabled and not _repeats_added:
		_repeats_added = true
		for t in _wrong_first.slice(0, MAX_REPEATS):
			var r: Dictionary = t.duplicate(true)
			r["repeat"] = true
			tasks.append(r)
	return index < tasks.size()


func duration_seconds() -> int:
	return int((Time.get_ticks_msec() - _start_ms) / 1000)


## Record for the progress repository (only answered main tasks count).
func to_record() -> ProgressRecord:
	return ProgressRecord.create(subject_id, topic_id, first_try_correct, solved, duration_seconds(), version)
