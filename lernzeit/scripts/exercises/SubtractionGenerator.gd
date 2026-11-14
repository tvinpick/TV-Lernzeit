class_name SubtractionGenerator
extends MathGenerator
## "Subtraktion bis 10 / bis 20": 0 <= b <= a <= max, answer = a - b (missing number: answer = b).
## Representations: crossed-out objects, equation, missing number, number line
## (backward jumps), ten-frame (two frames for bis 20), choose the picture.

const MODES: Array[String] = ["objects", "equation", "missing", "number_line", "ten_frame", "picture"]
const OBJECTS: Array[String] = ["apple", "balloon", "star", "butterfly", "car"]


func modes() -> Array:
	return MODES


func make_task(mode: String) -> Dictionary:
	var a_min := range_lo()
	var a_max := range_hi()
	var b_min := 1 if difficulty != "hard" else 2
	if mode == "number_line":
		a_min = maxi(a_min, 3)
	var a := rng.randi_range(a_min, a_max)
	var b_max := a - 1                       # keep at least one left (0 comes in a later stage)
	if mode == "number_line":
		b_max = mini(b_max, 5)               # at most 5 visible jumps
	if mode == "picture":
		# picture cards show the result as stars: keep it <= 10 so the stars stay large
		b_min = maxi(b_min, a - 10)
	var b := rng.randi_range(mini(b_min, b_max), b_max)
	var t := {"mode": mode, "a": a, "b": b, "result": a - b, "max": max_value,
		"prompt": "sub_prompt_" + mode, "key": "sub:%s:%d:%d" % [mode, a, b]}
	t["answer"] = b if mode == "missing" else a - b
	t["object"] = OBJECTS[rng.randi_range(0, OBJECTS.size() - 1)] if mode == "objects" else ("star" if mode == "picture" else "counter")
	t["option_style"] = "group" if mode == "picture" else "number"
	if mode == "picture":
		t["options"] = number_options(t["answer"], [], 1, mini(10, max_value))
	else:
		t["options"] = number_options(t["answer"], [a + b, a])
	return t


func is_valid(t: Dictionary) -> bool:
	return validate(t)


static func validate(t: Dictionary) -> bool:
	var mx: int = t.get("max", MAX)
	var a: int = t["a"]
	var b: int = t["b"]
	if a < 0 or b < 0 or b > a or a > mx:
		return false
	if t["result"] != a - b:
		return false
	var expected: int = b if t["mode"] == "missing" else a - b
	if t["answer"] != expected:
		return false
	if not MathGenerator.options_ok(t):
		return false
	if t["mode"] == "picture" and ((t["options"] as Array).min() < 1 or (t["options"] as Array).max() > 10):
		return false
	if t["mode"] == "number_line" and b > 5:
		return false
	return true
