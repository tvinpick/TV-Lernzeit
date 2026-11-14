class_name TextaufgabenGenerator
extends MathGenerator
## "Textaufgaben" (word problems up to 10) from res://data/textaufgaben.json:
## "3 Vögel sitzen auf dem Ast. 2 Vögel fliegen dazu. Wie viele Vögel sind es jetzt?"
## The text is read aloud (maths, not reading); the objects are shown as pictures.

const FILE := "res://data/textaufgaben.json"
const ALL_MODES: Array[String] = ["ta_task"]
static var _list: Array = []


static func aufgaben() -> Array:
	if _list.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_list = (d["aufgaben"] if d is Dictionary else []).duplicate()
	return _list


func modes() -> Array:
	return ALL_MODES


func make_task(_mode: String) -> Dictionary:
	var pool := aufgaben()
	if difficulty == "easy":                      # small numbers first
		var small := pool.filter(func(e): return int(e["answer"]) <= 6 and int(e["a"]) <= 6)
		if small.size() >= 10:
			pool = small
	var e: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var a := int(e["a"])
	var b := int(e["b"])
	var ans := int(e["answer"])
	var wrong_op := a - b if e["op"] == "+" else a + b      # typical mistake: wrong operation
	var t := {"mode": "ta_task", "prompt": "ta_prompt", "option_style": "number", "max": 10,
		"text": e["text"], "id": e["id"], "picture": e["picture"], "a": a, "b": b, "op": e["op"], "answer": ans,
		"key": "ta:" + str(e["id"])}
	t["options"] = number_options(ans, [wrong_op, a, b], 0, 10)
	return t


func is_valid(t: Dictionary) -> bool:
	var a: int = t["a"]
	var b: int = t["b"]
	var ok: bool = t["answer"] == (a + b if t["op"] == "+" else a - b)
	return ok and t["answer"] >= 0 and ResourceLoader.exists(t["picture"]) and MathGenerator.options_ok(t, 4)
