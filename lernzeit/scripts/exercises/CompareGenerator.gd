class_name CompareGenerator
extends MathGenerator
## "Vergleichen bis 10" (kit README: larger_number, smaller_number, comparison_sign,
## compare_groups, equal_quantities, sort_numbers). Includes "=" and equal amounts.

const MODES: Array[String] = ["cmp_larger", "cmp_smaller", "cmp_sign", "cmp_groups", "cmp_equal", "cmp_sort"]
const OBJECTS: Array[String] = ["apple", "star", "balloon", "butterfly"]


func modes() -> Array:
	return MODES


func _pair(lo: int, hi: int, allow_equal: bool) -> Array:
	var x := rng.randi_range(lo, hi)
	var y := rng.randi_range(lo, hi)
	var guard := 0
	while (not allow_equal and x == y) or (difficulty == "hard" and absi(x - y) > 2 and guard < 20):
		y = rng.randi_range(lo, hi)
		guard += 1
	if not allow_equal and x == y:
		y = x + 1 if x < hi else x - 1
	return [x, y]


func make_task(mode: String) -> Dictionary:
	var hi := range_hi()
	var t := {"mode": mode, "prompt": "cmp_prompt_" + mode.trim_prefix("cmp_"), "option_style": "number", "max": max_value}
	match mode:
		"cmp_larger", "cmp_smaller":
			var p := _pair(0, hi, false)
			t["x"] = p[0]
			t["y"] = p[1]
			t["answer"] = maxi(p[0], p[1]) if mode == "cmp_larger" else mini(p[0], p[1])
			t["options"] = [p[0], p[1]]
		"cmp_sign":
			var p := _pair(0, hi, rng.randf() < 0.25)
			t["x"] = p[0]
			t["y"] = p[1]
			t["answer"] = "<" if p[0] < p[1] else (">" if p[0] > p[1] else "=")
			t["options"] = ["<", ">", "="]
			t["option_style"] = "text"
		"cmp_groups":                  # where are fewer?
			var p := _pair(1, hi, false)
			t["x"] = p[0]
			t["y"] = p[1]
			t["answer"] = mini(p[0], p[1])
			t["options"] = [p[0], p[1]]
			t["option_style"] = "group"
			t["object"] = OBJECTS[rng.randi_range(0, OBJECTS.size() - 1)]
		"cmp_equal":                   # same amount? yes / no
			var p := _pair(1, hi, rng.randf() < 0.5)
			if rng.randf() < 0.5:
				p[1] = p[0]
			t["x"] = p[0]
			t["y"] = p[1]
			t["answer"] = "ja" if p[0] == p[1] else "nein"
			t["options"] = ["ja", "nein"]
			t["option_style"] = "text"
			t["translate_options"] = true
			t["object"] = OBJECTS[rng.randi_range(0, OBJECTS.size() - 1)]
		"cmp_sort":                    # which row is ordered from small to big?
			var nums: Array = []
			while nums.size() < 3:
				var v := rng.randi_range(0, hi)
				if not v in nums:
					nums.append(v)
			t["numbers"] = nums
			var asc: Array = nums.duplicate()
			asc.sort()
			var fmt := func(a: Array) -> String: return " · ".join(a.map(func(v): return str(v)))
			t["answer"] = fmt.call(asc)
			var opts: Array = [t["answer"]]
			var perms := [[asc[1], asc[0], asc[2]], [asc[0], asc[2], asc[1]], [asc[2], asc[1], asc[0]], [asc[1], asc[2], asc[0]], [asc[2], asc[0], asc[1]]]
			shuffle(perms)
			for pm in perms:
				var s: String = fmt.call(pm)
				if opts.size() < 3 and not s in opts:
					opts.append(s)
			shuffle(opts)
			t["options"] = opts
			t["option_style"] = "text"
	if t["options"] is Array and t["option_style"] == "number":
		shuffle(t["options"])
	t["key"] = "cmp:%s:%s:%s" % [mode, t.get("x", ""), t.get("y", t.get("numbers", ""))]
	return t


func is_valid(t: Dictionary) -> bool:
	return validate(t)


static func validate(t: Dictionary) -> bool:
	var mx: int = t.get("max", MAX)
	var opts: Array = t["options"]
	if not t["answer"] in opts:
		return false
	var u := {}
	for o in opts:
		if u.has(o):
			return false
		u[o] = true
	match t["mode"]:
		"cmp_larger", "cmp_smaller", "cmp_groups":
			var x: int = t["x"]
			var y: int = t["y"]
			if x == y or maxi(x, y) > mx or mini(x, y) < 0 or opts.size() != 2:
				return false
			var want := maxi(x, y) if t["mode"] == "cmp_larger" else mini(x, y)
			if t["answer"] != want or (t["mode"] == "cmp_groups" and mini(x, y) < 1):
				return false
		"cmp_sign":
			var x: int = t["x"]
			var y: int = t["y"]
			var want := "<" if x < y else (">" if x > y else "=")
			return t["answer"] == want and opts.size() == 3 and maxi(x, y) <= mx
		"cmp_equal":
			return t["answer"] == ("ja" if t["x"] == t["y"] else "nein") and opts.size() == 2 and maxi(t["x"], t["y"]) <= mx
		"cmp_sort":
			var asc: Array = (t["numbers"] as Array).duplicate()
			asc.sort()
			if t["answer"] != " · ".join(asc.map(func(v): return str(v))) or opts.size() != 3:
				return false
			return asc.max() <= mx
		_:
			return false
	return true
