class_name AdditionGenerator
extends MathGenerator
## "Addition bis 10 / bis 20": a, b >= 0, a + b <= max.
## Representations (kit README): count two groups, equation, complete to ten / twenty
## (ten-frames), add two dice, missing addend, choose the matching equation.

const MODES: Array[String] = ["add_groups", "add_equation", "add_to_ten", "add_dice", "add_missing", "add_choose"]
const OBJECTS: Array[String] = ["apple", "balloon", "star", "butterfly", "car"]


func modes() -> Array:
	return MODES


func make_task(mode: String) -> Dictionary:
	var s_min := range_lo()
	var s_max := range_hi()
	var prompt_mode := mode.trim_prefix("add_")
	if mode == "add_to_ten" and max_value > 10:
		prompt_mode = "to_twenty"
	var t := {"mode": mode, "prompt": "add_prompt_" + prompt_mode, "option_style": "number", "max": max_value}
	var a := 0
	var b := 0
	match mode:
		"add_to_ten":           # complete to 10 (bis 10) or to 20 (bis 20)
			var lo := 1 if difficulty != "hard" else 3
			if max_value > 10:
				lo = 11 if difficulty != "easy" else 8
			a = rng.randi_range(lo, max_value - 1)
			b = max_value - a
		"add_dice":             # two dice: sums up to 12
			var d_max := 12 if max_value > 10 else mini(10, s_max)
			var s := rng.randi_range(mini(2 if max_value <= 10 else 7, d_max), d_max)
			a = rng.randi_range(maxi(1, s - 6), mini(6, s - 1))
			b = s - a
		"add_choose":           # two groups of at most 5 stars: easy to see, enough distractors
			var s := rng.randi_range(mini(s_min, 6), 8)
			a = rng.randi_range(maxi(1, s - 5), mini(5, s - 1))
			b = s - a
		_:
			var s := rng.randi_range(s_min, s_max)
			a = rng.randi_range(1, s - 1)
			if max_value > 10 and mode == "add_groups":
				a = rng.randi_range(maxi(1, s - 10), mini(10, s - 1))   # each group <= 10 objects
			b = s - a
	t["a"] = a
	t["b"] = b
	t["sum"] = a + b
	t["key"] = "add:%s:%d:%d" % [mode, a, b]
	match mode:
		"add_to_ten", "add_missing":
			t["answer"] = b
			t["options"] = number_options(b, [a + b, a])
		"add_choose":
			t["option_style"] = "text"
			t["answer"] = "%d + %d" % [a, b]
			t["options"] = _equation_options(a, b)
		_:
			t["answer"] = a + b
			t["options"] = number_options(a + b, [absi(a - b), maxi(a, b)])
	t["object"] = OBJECTS[rng.randi_range(0, OBJECTS.size() - 1)] if mode == "add_groups" else "star"
	return t


## "a + b" plus 3 equations that do NOT describe the picture: never the swapped
## pair and never the same sum (so only the shown groups match).
func _equation_options(a: int, b: int) -> Array:
	var cands: Array = []
	for d in [[1, 0], [0, 1], [-1, 0], [0, -1], [1, 1], [-1, -1], [2, 0], [0, 2], [-2, 0], [0, -2], [2, 1], [1, 2], [-2, -1], [-1, -2]]:
		var x: int = a + d[0]
		var y: int = b + d[1]
		if x >= 1 and y >= 1 and x + y <= max_value and x + y != a + b and not (x == b and y == a):
			var s := "%d + %d" % [x, y]
			if not s in cands:
				cands.append(s)
	shuffle(cands)
	var opts: Array = ["%d + %d" % [a, b]]
	opts.append_array(cands.slice(0, 3))
	shuffle(opts)
	return opts


func is_valid(t: Dictionary) -> bool:
	return validate(t)


static func validate(t: Dictionary) -> bool:
	var mx: int = t.get("max", MAX)
	var a: int = t["a"]
	var b: int = t["b"]
	if a < 0 or b < 0 or a + b > mx or t["sum"] != a + b:
		return false
	match t["mode"]:
		"add_to_ten":
			if a + b != mx or t["answer"] != b or a < 1:
				return false
		"add_missing":
			if t["answer"] != b:
				return false
		"add_dice":
			if a < 1 or a > 6 or b < 1 or b > 6 or t["answer"] != a + b:
				return false
		"add_choose":
			if t["answer"] != "%d + %d" % [a, b]:
				return false
			for o in t["options"]:
				var p: PackedStringArray = (o as String).split(" + ")
				if o != t["answer"] and (int(p[0]) + int(p[1]) == a + b):
					return false        # a distractor with the same sum would also "fit"
		"add_groups":
			if a > 10 or b > 10 or t["answer"] != a + b:
				return false
		_:
			if t["answer"] != a + b:
				return false
	return MathGenerator.options_ok(t)
