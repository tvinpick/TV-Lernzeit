class_name AdaptiveLevel
extends RefCounted
## Adaptive difficulty inside one session: 3 tasks right on the first try in a
## row → one step harder; 2 tasks in a row with mistakes → one step easier.
## Stays within one step of the parents' setting. Changing the level regenerates
## the tasks that are still to come (same representations).

const LEVELS := ["easy", "auto", "hard"]

var index := 1
var min_index := 0
var max_index := 2
var _right := 0
var _wrong := 0


func _init(parent_level: String) -> void:
	index = maxi(0, LEVELS.find(parent_level))
	min_index = maxi(0, index - 1)
	max_index = mini(2, index + 1)


func level() -> String:
	return LEVELS[index]


## Returns true when the level changed.
func record(first_try: bool) -> bool:
	if first_try:
		_right += 1
		_wrong = 0
		if _right >= 3 and index < max_index:
			index += 1
			_right = 0
			return true
	else:
		_wrong += 1
		_right = 0
		if _wrong >= 2 and index > min_index:
			index -= 1
			_wrong = 0
			return true
	return false


## Regenerates the main tasks after the current one with the generator's new level.
static func regenerate(session: ExerciseSession, generator) -> void:
	var used := {}
	for i in session.main_count:
		used[session.tasks[i].get("key", "")] = true
	for i in range(session.index + 1, session.main_count):
		if session.tasks[i].get("again", false):
			continue                    # earlier mistakes stay in the session
		for attempt in 30:              # new level, but no task twice in one session
			var t: Dictionary = generator.make_task(session.tasks[i]["mode"])
			if not used.has(t["key"]) or attempt == 29:
				used[t["key"]] = true
				session.tasks[i] = t
				break
