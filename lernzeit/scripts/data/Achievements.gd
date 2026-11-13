class_name Achievements
extends RefCounted
## Achievements are computed from the saved progress (nothing extra is stored),
## so they stay consistent with "Fortschritt zurücksetzen".

## id -> [title key, description key, icon]
const LIST := [
	["first_steps", "ach_first_steps", "ach_first_steps_d", "res://assets/mascot/badges/Badge_first_steps.png"],
	["sessions_10", "ach_sessions_10", "ach_sessions_10_d", "res://assets/mascot/badges/Badge_sessions_10.png"],
	["sessions_30", "ach_sessions_30", "ach_sessions_30_d", "res://assets/mascot/badges/Badge_sessions_30.png"],
	["tasks_100", "ach_tasks_100", "ach_tasks_100_d", "res://assets/mascot/badges/Badge_tasks_100.png"],
	["perfect", "ach_perfect", "ach_perfect_d", "res://assets/mascot/badges/Badge_perfect.png"],
	["perfect_3", "ach_perfect_3", "ach_perfect_3_d", "res://assets/mascot/badges/Badge_perfect_3.png"],
	["days_3", "ach_days_3", "ach_days_3_d", "res://assets/mascot/badges/Badge_days_3.png"],
	["days_7", "ach_days_7", "ach_days_7_d", "res://assets/mascot/badges/Badge_days_7.png"],
	["math_trio", "ach_math_trio", "ach_math_trio_d", "res://assets/mascot/badges/Badge_math_trio.png"],
	["math_20", "ach_math_20", "ach_math_20_d", "res://assets/mascot/badges/Badge_math_20.png"],
	["letters_8", "ach_letters_8", "ach_letters_8_d", "res://assets/mascot/badges/Badge_letters_8.png"],
	["letters_19", "ach_letters_19", "ach_letters_19_d", "res://assets/mascot/badges/Badge_letters_19.png"],
	["level_5", "ach_level_5", "ach_level_5_d", "res://assets/mascot/badges/Badge_level_5.png"],
	["level_10", "ach_level_10", "ach_level_10_d", "res://assets/mascot/badges/Badge_level_10.png"],
	["level_20", "ach_level_20", "ach_level_20_d", "res://assets/mascot/badges/Badge_level_20.png"],
	["all_subjects", "ach_all_subjects", "ach_all_subjects_d", "res://assets/mascot/badges/Badge_all_subjects.png"],
	["lesen_3", "ach_lesen_3", "ach_lesen_3_d", "res://assets/mascot/badges/Badge_lesen_3.png"],
	["logik_3", "ach_logik_3", "ach_logik_3_d", "res://assets/mascot/badges/Badge_logik_3.png"],
	["goal_3", "ach_goal_3", "ach_goal_3_d", "res://assets/mascot/badges/Badge_goal_3.png"],
	["perfect_10", "ach_perfect_10", "ach_perfect_10_d", "res://assets/mascot/badges/Badge_perfect_10.png"],
	["sessions_50", "ach_sessions_50", "ach_sessions_50_d", "res://assets/mascot/badges/Badge_sessions_50.png"],
	["tasks_500", "ach_tasks_500", "ach_tasks_500_d", "res://assets/mascot/badges/Badge_tasks_500.png"],
	["letters_all", "ach_letters_all", "ach_letters_all_d", "res://assets/mascot/badges/Badge_letters_all.png"],
	["test_1", "ach_test_1", "ach_test_1_d", "res://assets/mascot/badges/Badge_test_1.png"],
	["test_green", "ach_test_green", "ach_test_green_d", "res://assets/mascot/badges/Badge_test_green.png"],
]


static func stats() -> Dictionary:
	var recs := ProgressRepository.get_records()
	var days := {}
	var topics := {}
	var perfect := 0
	var tasks := 0
	var math20 := false
	var per_subject := {}
	var per_day := {}           # finished exercises per day (daily goal)
	for r in recs:
		per_subject[r.subject_id] = int(per_subject.get(r.subject_id, 0)) + 1
		if r.complete:
			var dk := PauseReminder.local_day(r.timestamp)
			per_day[dk] = int(per_day.get(dk, 0)) + 1
		var d := Time.get_datetime_dict_from_unix_time(r.timestamp)
		days["%d-%d-%d" % [d.year, d.month, d.day]] = true
		topics[r.subject_id + "/" + r.topic_id] = true
		tasks += r.total_count
		if r.complete and r.correct_count == r.total_count:
			perfect += 1
		if r.exercise_version.contains("20"):
			math20 = true
	var goal: int = SettingsRepository.get_parent_settings().get("daily_goal", 3)
	if goal <= 0:
		goal = 3
	var goal_days := 0
	for dk in per_day:
		if per_day[dk] >= goal:
			goal_days += 1
	var tests := ProgressRepository.get_tests()
	var green := false
	for t in tests:
		green = green or is_test_green(t)
	return {"sessions": recs.size(), "tasks": tasks, "perfect": perfect, "days": days.size(),
		"topics": topics, "math20": math20, "subjects": per_subject, "goal_days": goal_days,
		"level": Progression.level(), "tests": tests.size(), "test_green": green,
		"letters_secure": ProgressRepository.letters_with_status("secure").size()}


static func is_unlocked(id: String, s: Dictionary) -> bool:
	match id:
		"first_steps": return s["sessions"] >= 1
		"sessions_10": return s["sessions"] >= 10
		"sessions_30": return s["sessions"] >= 30
		"tasks_100": return s["tasks"] >= 100
		"perfect": return s["perfect"] >= 1
		"perfect_3": return s["perfect"] >= 3
		"days_3": return s["days"] >= 3
		"days_7": return s["days"] >= 7
		"math_trio":
			var t: Dictionary = s["topics"]
			return t.has("mathematik/zaehlen") and t.has("mathematik/addition") and t.has("mathematik/subtraktion")
		"math_20": return s["math20"]
		"letters_8": return s["letters_secure"] >= 8
		"letters_19": return s["letters_secure"] >= 19
		"level_5": return s["level"] >= 5
		"level_10": return s["level"] >= 10
		"level_20": return s["level"] >= 20
		"all_subjects": return (s["subjects"] as Dictionary).size() >= 4
		"lesen_3": return int(s["subjects"].get("lesen", 0)) >= 3
		"logik_3": return int(s["subjects"].get("logik", 0)) >= 3
		"goal_3": return s["goal_days"] >= 3
		"perfect_10": return s["perfect"] >= 10
		"sessions_50": return s["sessions"] >= 50
		"tasks_500": return s["tasks"] >= 500
		"letters_all": return s["letters_secure"] >= LetterGenerator.LETTERS_ALL.size()
		"test_1": return s["tests"] >= 1
		"test_green": return s["test_green"]
	return false


## Lernkontrolle: every topic at least 80 % right ("sicher").
static func is_test_green(t: Dictionary) -> bool:
	var topics: Dictionary = t.get("topics", {})
	if topics.is_empty():
		return false
	for k in topics:
		var v: Array = topics[k]
		if int(v[1]) == 0 or float(v[0]) / float(v[1]) < 0.8:
			return false
	return true


static func unlocked_ids() -> Array:
	var s := stats()
	var out: Array = []
	for a in LIST:
		if is_unlocked(a[0], s):
			out.append(a[0])
	return out


static func title_key(id: String) -> String:
	for a in LIST:
		if a[0] == id:
			return a[1]
	return id


# ----------------------------------------------------------------- stickers ---
## Sticker album: one sticker for every new level ("Stufe"), 20 in total.
const STICKER_COUNT := 20


static func sticker_path(i: int) -> String:
	return "res://assets/mascot/stickers/Sticker_%02d.png" % i


static func stickers_earned() -> int:
	return clampi(Progression.level() - 1, 0, STICKER_COUNT)
