class_name MathExerciseInfo
extends RefCounted
## Small lookup used outside the exercise screen (home "Weiter üben").

const TITLES := {"sub10": "ex_sub10_title", "add10": "ex_add10_title", "count10": "ex_count10_title",
	"sub20": "ex_sub20_title", "cmp10": "ex_cmp10_title", "zr20": "ex_zr_title", "ta10": "ex_ta_title", "add20": "ex_add20_title", "count20": "ex_count20_title",
	"de_letters": "ex_de_letters_title", "de_anlaute": "ex_de_anlaute_title",
	"de_woerter": "ex_de_woerter_title", "de_case": "ex_de_case_title",
	"le_silben": "ex_le_silben_title", "le_woerter": "ex_le_woerter_title",
	"le_saetze": "ex_le_saetze_title", "le_texte": "ex_le_texte_title",
	"lg_muster": "ex_lg_muster_title", "lg_formen": "ex_lg_formen_title", "lg_reihenfolge": "ex_lg_reihenfolge_title", "lg_unterschiede": "ex_lg_unterschiede_title"}


static func title_key(exercise_id: String) -> String:
	return TITLES.get(exercise_id, "continue")


## Short text of a task for the parents' area ("7 − 3", "4 6 ? 10", "Löwe", "b"); "" if none.
static func describe(t: Dictionary) -> String:
	var m: String = t.get("mode", "")
	if t.has("sequence") and (m == "zr_step" or m == "cnt_sequence"):
		var parts: Array = []
		for i in (t["sequence"] as Array).size():
			parts.append("?" if i == int(t["hole"]) else str(t["sequence"][i]))
		return " ".join(parts)
	if m.begins_with("de_") or m.begins_with("le_"):
		if m in ["de_find", "de_case"]:
			return str(t.get("shown", t.get("letter", "")))
		return str(t.get("display", str(t.get("word", "")).capitalize()))
	if m.begins_with("lg_"):
		return ""
	if t.has("a") and t.has("b") and not m.ends_with("dice"):
		return "%d %s %d" % [t["a"], "+" if m.begins_with("add") else "−", t["b"]]
	if t.has("x") and t.has("y"):
		return "%d / %d" % [t["x"], t["y"]]
	return ""
