class_name Achievements
extends RefCounted
## Achievements are computed from the saved progress (nothing extra is stored),
## so they stay consistent with "Fortschritt zurücksetzen".

## id -> [title key, description key, icon]
const LIST := [
	["first_steps", "ach_first_steps", "ach_first_steps_d", "res://assets/icons/Lernzeit_Icon_Target.png"],
	["sessions_10", "ach_sessions_10", "ach_sessions_10_d", "res://assets/icons/Lernzeit_Icon_Tasks.png"],
	["sessions_30", "ach_sessions_30", "ach_sessions_30_d", "res://assets/icons/Settings_Icon_Achievements.png"],
	["tasks_100", "ach_tasks_100", "ach_tasks_100_d", "res://assets/icons/Lernzeit_Icon_Progress.png"],
	["perfect", "ach_perfect", "ach_perfect_d", "res://assets/icons/Lernzeit_Icon_Correct.png"],
	["perfect_3", "ach_perfect_3", "ach_perfect_3_d", "res://assets/math/shared_ui/Object_Star_Yellow.png"],
	["days_3", "ach_days_3", "ach_days_3_d", "res://assets/icons/Lernzeit_Icon_Calendar.png"],
	["days_7", "ach_days_7", "ach_days_7_d", "res://assets/icons/Settings_Icon_Calendar.png"],
	["math_trio", "ach_math_trio", "ach_math_trio_d", "res://assets/icons/subject_mathematik.png"],
	["math_20", "ach_math_20", "ach_math_20_d", "res://assets/math/counting_10/dice/Counting_Dice_6.png"],
	["letters_8", "ach_letters_8", "ach_letters_8_d", "res://assets/icons/subject_deutsch.png"],
	["letters_19", "ach_letters_19", "ach_letters_19_d", "res://assets/icons/Lernzeit_Icon_Subjects.png"],
]


static func stats() -> Dictionary:
	var recs := ProgressRepository.get_records()
	var days := {}
	var topics := {}
	var perfect := 0
	var tasks := 0
	var math20 := false
	for r in recs:
		var d := Time.get_datetime_dict_from_unix_time(r.timestamp)
		days["%d-%d-%d" % [d.year, d.month, d.day]] = true
		topics[r.subject_id + "/" + r.topic_id] = true
		tasks += r.total_count
		if r.total_count >= 10 and r.correct_count == r.total_count:
			perfect += 1
		if r.exercise_version.contains("20"):
			math20 = true
	return {"sessions": recs.size(), "tasks": tasks, "perfect": perfect, "days": days.size(),
		"topics": topics, "math20": math20,
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
	return false


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
