class_name MathExerciseInfo
extends RefCounted
## Small lookup used outside the exercise screen (home "Weiter üben").

const TITLES := {"sub10": "ex_sub10_title", "add10": "ex_add10_title", "count10": "ex_count10_title"}


static func title_key(exercise_id: String) -> String:
	return TITLES.get(exercise_id, "continue")
