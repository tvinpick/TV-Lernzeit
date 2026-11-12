class_name SubtractionGenerator
extends RefCounted
## Task generator "Subtraktion bis 10". Every task is validated before use:
## 0 <= b <= a <= 10, answer = a - b, 4 unique options in range, one of them correct.
## The correct answer is stored in the task data – never inferred from visuals.

const MODES: Array[String] = ["objects", "equation", "missing", "number_line", "ten_frame", "picture"]
const MAX := 10
const OBJECTS: Array[String] = ["apple", "balloon", "star", "butterfly", "car"]

var rng := RandomNumberGenerator.new()
var difficulty := "auto"     ## easy | auto | hard (from the parents area)


func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


## 10 tasks: each of the 6 modes once + 4 random modes, shuffled, no duplicate tasks.
func make_session(count: int = 10) -> Array:
	var modes: Array = MODES.duplicate()
	while modes.size() < count:
		modes.append(MODES[rng.randi_range(0, MODES.size() - 1)])
	_shuffle(modes)
	var tasks: Array = []
	var seen := {}
	for m in modes.slice(0, count):
		var t := {}
		for attempt in 30:
			t = make_task(m)
			var key := "%s:%d:%d" % [m, t["a"], t["b"]]
			if not seen.has(key):
				seen[key] = true
				break
		tasks.append(t)
	return tasks


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
	var t := {"mode": mode, "a": a, "b": b, "result": a - b}
	t["answer"] = b if mode == "missing" else a - b
	t["object"] = OBJECTS[rng.randi_range(0, OBJECTS.size() - 1)] if mode == "objects" else ("star" if mode == "picture" else "counter")
	t["options"] = _options(t["answer"], a, b, 1 if mode == "picture" else 0)
	assert(validate(t), "invalid subtraction task %s" % t)
	return t


func _options(answer: int, a: int, b: int, min_value: int) -> Array:
	var cands: Array = []
	for d in [1, -1, 2, -2, 3, -3, 4, -4]:
		cands.append(answer + d)
	cands.append(a + b)        # typical mistake: added instead of subtracted
	cands.append(a)            # typical mistake: forgot to subtract
	var pool: Array = []
	for c in cands:
		if c >= min_value and c <= MAX and c != answer and not c in pool:
			pool.append(c)
	var near: Array = pool.slice(0, 5)
	_shuffle(near)
	var opts: Array = [answer]
	for c in near:
		if opts.size() < 4:
			opts.append(c)
	var v := min_value
	while opts.size() < 4:          # tiny ranges: fill with any free value
		if not v in opts:
			opts.append(v)
		v += 1
	_shuffle(opts)
	return opts


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
	var opts: Array = t["options"]
	if opts.size() != 4 or not t["answer"] in opts:
		return false
	var uniq := {}
	for o in opts:
		if o < 0 or o > MAX or uniq.has(o):
			return false
		uniq[o] = true
	if t["mode"] == "picture" and opts.min() < 1:
		return false
	return true


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
