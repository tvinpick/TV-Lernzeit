class_name CountingGenerator
extends MathGenerator
## "Zählen bis 10" (numbers 0..10). Representations from the counting mock-ups:
## count objects, which number is bigger, where are more, missing number in a
## sequence (forwards/backwards), dice dots, how many are missing to 10.
## ("Welche Zahl hörst du?" needs recorded audio and is not included yet.)

const MODES: Array[String] = ["cnt_objects", "cnt_bigger", "cnt_more", "cnt_sequence", "cnt_dice", "cnt_to_ten"]
const OBJECTS: Array[String] = ["apple", "balloon", "star", "butterfly", "car"]


func modes() -> Array:
	return MODES


func make_task(mode: String) -> Dictionary:
	var hi := 6 if difficulty == "easy" else MAX
	var t := {"mode": mode, "prompt": "cnt_prompt_" + mode.trim_prefix("cnt_"), "option_style": "number"}
	match mode:
		"cnt_objects":
			var n := rng.randi_range(1 if difficulty != "hard" else 4, hi)
			t["n"] = n
			t["answer"] = n
			t["options"] = number_options(n, [], 1)
			t["object"] = OBJECTS[rng.randi_range(0, OBJECTS.size() - 1)]
			t["key"] = "cnt:o:%d:%s" % [n, t["object"]]
		"cnt_bigger":
			var x := rng.randi_range(0, hi)
			var y := x
			var max_gap := 3 if difficulty == "hard" else hi
			while y == x or absi(y - x) > max_gap:
				y = rng.randi_range(0, hi)
			t["x"] = x
			t["y"] = y
			t["answer"] = maxi(x, y)
			t["options"] = [x, y]
			t["key"] = "cnt:b:%d:%d" % [mini(x, y), maxi(x, y)]
		"cnt_more":
			var x := rng.randi_range(1, hi)
			var y := x
			while y == x:
				y = rng.randi_range(1, hi)
			t["x"] = x
			t["y"] = y
			t["answer"] = maxi(x, y)
			t["options"] = [x, y]
			t["option_style"] = "group"
			t["object"] = "apple"
			t["key"] = "cnt:m:%d:%d" % [mini(x, y), maxi(x, y)]
		"cnt_sequence":
			var backwards := rng.randf() < 0.5
			var start := rng.randi_range(4, hi) if backwards else rng.randi_range(0, hi - 4)
			var seq: Array = []
			for i in 5:
				seq.append(start - i if backwards else start + i)
			var hole := rng.randi_range(1, 4)
			t["sequence"] = seq
			t["hole"] = hole
			t["backwards"] = backwards
			t["prompt"] = "cnt_prompt_backwards" if backwards else "cnt_prompt_forwards"
			t["answer"] = seq[hole]
			t["options"] = number_options(seq[hole], [seq[hole] + (1 if backwards else -1) * 2])
			t["key"] = "cnt:s:%d:%d:%s" % [start, hole, backwards]
		"cnt_dice":
			var s := rng.randi_range(2, mini(10, hi + 2))
			var a := rng.randi_range(maxi(1, s - 6), mini(6, s - 1))
			t["a"] = a
			t["b"] = s - a
			t["answer"] = s
			t["options"] = number_options(s, [], 1)
			t["key"] = "cnt:d:%d:%d" % [a, s - a]
		"cnt_to_ten":
			var n := rng.randi_range(1, 9)
			t["n"] = n
			t["answer"] = MAX - n
			t["options"] = number_options(MAX - n, [n])
			t["key"] = "cnt:t:%d" % n
	return t


func is_valid(t: Dictionary) -> bool:
	return validate(t)


static func validate(t: Dictionary) -> bool:
	match t["mode"]:
		"cnt_objects":
			if t["n"] < 1 or t["n"] > MAX or t["answer"] != t["n"]:
				return false
		"cnt_bigger", "cnt_more":
			if t["x"] == t["y"] or t["answer"] != maxi(t["x"], t["y"]):
				return false
			if t["mode"] == "cnt_more" and mini(t["x"], t["y"]) < 1:
				return false
			return MathGenerator.options_ok(t, 2)
		"cnt_sequence":
			var seq: Array = t["sequence"]
			var step := -1 if t["backwards"] else 1
			for i in range(1, seq.size()):
				if seq[i] - seq[i - 1] != step:
					return false
			if seq.min() < 0 or seq.max() > MAX or t["answer"] != seq[t["hole"]]:
				return false
		"cnt_dice":
			if t["a"] < 1 or t["a"] > 6 or t["b"] < 1 or t["b"] > 6 or t["answer"] != t["a"] + t["b"] or t["answer"] > MAX:
				return false
		"cnt_to_ten":
			if t["n"] < 1 or t["n"] > 9 or t["answer"] != MAX - t["n"]:
				return false
		_:
			return false
	return MathGenerator.options_ok(t)
