class_name SubtractionGenerator
extends MathGenerator
## "Subtraktion bis 10": 0 <= b <= a <= 10, answer = a - b (missing number: answer = b).
## Representations: crossed-out objects, equation, missing number, number line
## (backward jumps), ten-frame, choose the picture.

const MODES: Array[String] = ["objects", "equation", "missing", "number_line", "ten_frame", "picture"]
const OBJECTS: Array[String] = ["apple", "balloon", "star", "butterfly", "car"]


func modes() -> Array:
	return MODES


func make_task(mode: String) -> Dictionary:
	var a_min := 2
	var a_max := MAX
	var b_min := 1
	match difficulty:
		"easy":
			a_max = 6
		"hard":
			a_min = 5
			b_min = 2
	if mode == "number_line":
		a_min = maxi(a_min, 3)
	var a := rng.randi_range(a_min, a_max)
	var b_max := a - 1                       # keep at least one left (0 comes in a later stage)
	if mode == "number_line":
		b_max = mini(b_max, 5)               # at most 5 visible jumps
	var b := rng.randi_range(mini(b_min, b_max), b_max)
	var t := {"mode": mode, "a": a, "b": b, "result": a - b, "prompt": "sub_prompt_" + mode,
		"key": "sub:%s:%d:%d" % [mode, a, b]}
	t["answer"] = b if mode == "missing" else a - b
	t["object"] = OBJECTS[rng.randi_range(0, OBJECTS.size() - 1)] if mode == "objects" else ("star" if mode == "picture" else "counter")
	t["option_style"] = "group" if mode == "picture" else "number"
	t["options"] = number_options(t["answer"], [a + b, a], 1 if mode == "picture" else 0)
	return t


func is_valid(t: Dictionary) -> bool:
	return validate(t)


static func validate(t: Dictionary) -> bool:
	var a: int = t["a"]
	var b: int = t["b"]
	if a < 0 or b < 0 or b > a or a > MAX:
		return false
	if t["result"] != a - b:
		return false
	var expected: int = b if t["mode"] == "missing" else a - b
	if t["answer"] != expected:
		return false
	if not MathGenerator.options_ok(t):
		return false
	if t["mode"] == "picture" and (t["options"] as Array).min() < 1:
		return false
	return true
