class_name MathExerciseInfo
extends RefCounted
## Small lookup used outside the exercise screen (home "Weiter üben").

const TITLES := {"sub10": "ex_sub10_title", "add10": "ex_add10_title", "count10": "ex_count10_title",
	"sub20": "ex_sub20_title", "cmp10": "ex_cmp10_title", "add20": "ex_add20_title", "count20": "ex_count20_title",
	"de_letters": "ex_de_letters_title", "de_anlaute": "ex_de_anlaute_title",
	"de_woerter": "ex_de_woerter_title", "de_case": "ex_de_case_title",
	"le_silben": "ex_le_silben_title", "le_woerter": "ex_le_woerter_title",
	"lg_muster": "ex_lg_muster_title", "lg_formen": "ex_lg_formen_title", "lg_reihenfolge": "ex_lg_reihenfolge_title"}


static func title_key(exercise_id: String) -> String:
	return TITLES.get(exercise_id, "continue")
