class_name Curriculum
extends RefCounted
## Static navigation skeleton (subjects → topics → levels). No exercise content.

const SUBJECT_IDS: Array[String] = ["mathematik", "deutsch", "lesen", "logik"]

const SUBJECTS := {
	"mathematik": {"card": "res://assets/buttons/card_mathematik.png", "icon": "res://assets/icons/subject_mathematik.png", "color": Color("1f8be8"), "row": "blue"},
	"deutsch": {"card": "res://assets/buttons/card_deutsch.png", "icon": "res://assets/icons/subject_deutsch.png", "color": Color("8a4fe0"), "row": "purple"},
	"lesen": {"card": "res://assets/buttons/card_lesen.png", "icon": "res://assets/icons/subject_lesen.png", "color": Color("2fae3a"), "row": "blue"},
	"logik": {"card": "res://assets/buttons/card_logik.png", "icon": "res://assets/icons/subject_logik.png", "color": Color("f29a12"), "row": "gold"},
}

const MATH_LEVELS: Array[int] = [10, 20]     ## 1st grade (Bavaria): numbers up to 20

## Topics/levels that already have a real exercise: "subject/topic/level" -> exercise id
## (opened with Main.push("exercise", {"exercise": id})).
const PLAYABLE := {
	"mathematik/zaehlen/10": "count10",
	"mathematik/addition/10": "add10",
	"mathematik/subtraktion/10": "sub10",
	"mathematik/vergleichen/0": "cmp10",
	"mathematik/zahlenreihen/0": "zr20",
	"mathematik/textaufgaben/0": "ta10",
	"mathematik/zaehlen/20": "count20",
	"mathematik/addition/20": "add20",
	"mathematik/subtraktion/20": "sub20",
	"deutsch/buchstaben/0": "de_letters",
	"deutsch/anlaute/0": "de_anlaute",
	"deutsch/woerter/0": "de_woerter",
	"deutsch/gross_klein/0": "de_case",
	"lesen/silben/0": "le_silben",
	"lesen/woerter/0": "le_woerter",
	"lesen/saetze/0": "le_saetze",
	"lesen/texte/0": "le_texte",
	"logik/muster/0": "lg_muster",
	"logik/formen/0": "lg_formen",
	"logik/reihenfolge/0": "lg_reihenfolge",
	"logik/unterschiede/0": "lg_unterschiede",
}


## Screen that runs an exercise id.
static func screen_for(exercise_id: String) -> String:
	return "exercise_de" if exercise_id.begins_with("de_") or exercise_id.begins_with("le_") or exercise_id.begins_with("lg_") else "exercise"


static func subject_of(exercise_id: String) -> String:
	if exercise_id.begins_with("le_"):
		return "lesen"
	if exercise_id.begins_with("lg_"):
		return "logik"
	return "deutsch" if exercise_id.begins_with("de_") else "mathematik"


static func exercise_for(subject_id: String, topic_id: String, level: int = 0) -> String:
	return PLAYABLE.get("%s/%s/%d" % [subject_id, topic_id, level], "")


## Exercise of the most recently practised playable topic ("" if none) – for "Weiter üben".
static func last_practised_exercise() -> String:
	for r in ProgressRepository.get_records():        # newest first
		if r.subject_id in ["deutsch", "lesen", "logik"]:
			var ex: String = PLAYABLE.get("%s/%s/0" % [r.subject_id, r.topic_id], "")
			if ex != "":
				return ex
		else:
			var id := r.exercise_version.split("-v")[0]   # "sub20-v1" -> "sub20"
			if id in PLAYABLE.values():
				return id
	return ""

## topic: {id, key, levels}
const TOPICS := {
	"mathematik": [
		{"id": "zaehlen", "key": "topic_m_zaehlen", "levels": MATH_LEVELS},
		{"id": "addition", "key": "topic_m_addition", "levels": MATH_LEVELS},
		{"id": "subtraktion", "key": "topic_m_subtraktion", "levels": MATH_LEVELS},
		{"id": "vergleichen", "key": "topic_m_vergleichen", "levels": []},
		{"id": "zahlenreihen", "key": "topic_m_zahlenreihen", "levels": []},
		{"id": "textaufgaben", "key": "topic_m_textaufgaben", "levels": []},
	],
	"deutsch": [
		{"id": "buchstaben", "key": "topic_d_buchstaben", "levels": []},
		{"id": "anlaute", "key": "topic_d_anlaute", "levels": []},
		{"id": "woerter", "key": "topic_d_woerter", "levels": []},
		{"id": "gross_klein", "key": "topic_d_gross_klein", "levels": []},
	],
	"lesen": [
		{"id": "silben", "key": "topic_l_silben", "levels": []},
		{"id": "woerter", "key": "topic_l_woerter", "levels": []},
		{"id": "saetze", "key": "topic_l_saetze", "levels": []},
		{"id": "texte", "key": "topic_l_texte", "levels": []},
	],
	"logik": [
		{"id": "muster", "key": "topic_g_muster", "levels": []},
		{"id": "formen", "key": "topic_g_formen", "levels": []},
		{"id": "unterschiede", "key": "topic_g_unterschiede", "levels": []},
		{"id": "reihenfolge", "key": "topic_g_reihenfolge", "levels": []},
	],
}


static func title_key(subject_id: String) -> String:
	return "subject_" + subject_id


static func subtitle_key(subject_id: String) -> String:
	return "subject_" + subject_id + "_sub"


static func topics(subject_id: String) -> Array:
	return TOPICS.get(subject_id, [])


static func topic_key(subject_id: String, topic_id: String) -> String:
	for t in topics(subject_id):
		if t["id"] == topic_id:
			return t["key"]
	return topic_id
