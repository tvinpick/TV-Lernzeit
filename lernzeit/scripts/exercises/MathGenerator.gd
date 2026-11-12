class_name MathGenerator
extends RefCounted
## Base class for the number-range-10 task generators.
## A task is a Dictionary with at least:
##   mode, prompt (localization key), answer, options (Array, contains answer),
##   option_style ("number" | "group" | "text"), key (for de-duplication)
## Subclasses implement modes(), make_task(mode) and is_valid(task).

const MAX := 10              ## default number range

var rng := RandomNumberGenerator.new()
var difficulty := "auto"     ## easy | auto | hard (parents area)
var max_value := MAX         ## number range: 10 or 20


## Lower / upper bound for the "main" numbers of a task in this range.
## bis 10: 2..10 (easy ..6); bis 20: 11..20 mostly (easy 8..12) so the range really is practised.
func range_lo() -> int:
	if max_value <= 10:
		return 2 if difficulty != "hard" else 5
	return 8 if difficulty == "easy" else 11


func range_hi() -> int:
	if max_value <= 10:
		return 6 if difficulty == "easy" else 10
	return 12 if difficulty == "easy" else 20


func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func modes() -> Array:
	return []


func make_task(_mode: String) -> Dictionary:
	return {}


func is_valid(_t: Dictionary) -> bool:
	return false


## `count` tasks: every mode once, the rest random; shuffled; no duplicate tasks.
func make_session(count: int = 10) -> Array:
	var ms: Array = modes().duplicate()
	while ms.size() < count:
		ms.append(modes()[rng.randi_range(0, modes().size() - 1)])
	shuffle(ms)
	var tasks: Array = []
	var seen := {}
	for m in ms.slice(0, count):
		var t := {}
		for attempt in 40:
			t = make_task(m)
			if not seen.has(t["key"]):
				break
		seen[t["key"]] = true
		assert(is_valid(t), "invalid task %s" % t)
		tasks.append(t)
	return tasks


## Answer + near distractors (plus typical mistakes), unique, inside [lo, hi].
func number_options(answer: int, mistakes: Array = [], lo: int = 0, hi: int = -1, count: int = 4) -> Array:
	if hi < 0:
		hi = max_value
	var cands: Array = []
	for d in [1, -1, 2, -2, 3, -3, 4, -4]:
		cands.append(answer + d)
	cands.append_array(mistakes)
	var pool: Array = []
	for c in cands:
		if c >= lo and c <= hi and c != answer and not c in pool:
			pool.append(c)
	var near: Array = pool.slice(0, 5)
	shuffle(near)
	var opts: Array = [answer]
	for c in near:
		if opts.size() < count:
			opts.append(c)
	var v := lo
	while opts.size() < count and v <= hi:
		if not v in opts:
			opts.append(v)
		v += 1
	shuffle(opts)
	return opts


## Shared checks: options unique, contain the answer, numbers inside 0..10.
static func options_ok(t: Dictionary, expected_count: int = 4) -> bool:
	var opts: Array = t["options"]
	if opts.size() != expected_count or not t["answer"] in opts:
		return false
	var uniq := {}
	for o in opts:
		if uniq.has(o):
			return false
		uniq[o] = true
		if (o is int) and (o < 0 or o > int(t.get("max", MAX))):
			return false
	return true


func shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
