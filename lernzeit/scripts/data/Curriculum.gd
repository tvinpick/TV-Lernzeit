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

const MATH_LEVELS: Array[int] = [10, 20, 50, 100]

## Topics/levels that already have a real exercise: "subject/topic/level" -> exercise id
## (opened with Main.push("exercise", {"exercise": id})).
const PLAYABLE := {
	"mathematik/zaehlen/10": "count10",
	"mathematik/addition/10": "add10",
	"mathematik/subtraktion/10": "sub10",
}


static func exercise_for(subject_id: String, topic_id: String, level: int = 0) -> String:
	return PLAYABLE.get("%s/%s/%d" % [subject_id, topic_id, level], "")


## Exercise of the most recently practised playable topic ("" if none) – for "Weiter üben".
static func last_practised_exercise() -> String:
	var best := ""
	var best_ts := -1
	for k in PLAYABLE:
		var p: PackedStringArray = (k as String).split("/")
		var recs := ProgressRepository.get_records(p[0], p[1])
		if not recs.is_empty() and recs[0].timestamp > best_ts:
			best_ts = recs[0].timestamp
			best = PLAYABLE[k]
	return best

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
