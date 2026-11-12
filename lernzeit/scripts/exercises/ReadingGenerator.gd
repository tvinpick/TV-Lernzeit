class_name ReadingGenerator
extends MathGenerator
## "Lesen" (reading) tasks with the pictures from the Lesen word packs.
##   le_syllables – build the word from shuffled syllable tiles (picture shown)
##   le_word_pic  – read the word, choose the matching picture (4 pictures)
##   le_pic_word  – look at the picture, choose the matching word (4 words)
## Words stay German; data in res://data/lesen_words.json.

const WORDS_FILE := "res://data/lesen_words.json"
const ALL_MODES: Array[String] = ["le_syllables", "le_word_pic", "le_pic_word"]

var allowed_modes: Array = ALL_MODES
static var _words: Array = []


static func words() -> Array:
	if _words.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(WORDS_FILE))
		_words = (d["words"] if d is Dictionary else []).duplicate()
	return _words


func modes() -> Array:
	return allowed_modes


## Leicht: only 2-syllable words up to 4 letters; Anspruchsvoll: prefers 3 syllables.
func _pool() -> Array:
	var all := words()
	match difficulty:
		"easy":
			var p := all.filter(func(e): return (e["syllables"] as Array).size() == 2 and (e["word"] as String).length() <= 4)
			return p if p.size() >= 4 else all
		"hard":
			return all
	return all.filter(func(e): return (e["syllables"] as Array).size() <= 3)


func _pick(arr: Array) -> Dictionary:
	return arr[rng.randi_range(0, arr.size() - 1)]


## 3 other words; similar ones first (same first letter or same length).
func _distractors(e: Dictionary) -> Array:
	var others := words().filter(func(x): return x["word"] != e["word"])
	shuffle(others)
	others.sort_custom(func(a, b):
		var sa: int = int(a["word"][0] == e["word"][0]) + int((a["word"] as String).length() == (e["word"] as String).length())
		var sb: int = int(b["word"][0] == e["word"][0]) + int((b["word"] as String).length() == (e["word"] as String).length())
		return sa > sb)
	return others.slice(0, 3)


func make_task(mode: String) -> Dictionary:
	var pool := _pool()
	if difficulty == "hard" and mode == "le_syllables":
		var three := pool.filter(func(e): return (e["syllables"] as Array).size() == 3)
		if not three.is_empty() and rng.randf() < 0.6:
			pool = three
	var e := _pick(pool)
	var t := {"mode": mode, "word": e["word"], "picture": e["picture"], "key": "%s:%s" % [mode, e["word"]]}
	match mode:
		"le_syllables":
			var parts: Array = (e["syllables"] as Array).duplicate()
			var tiles: Array = parts.duplicate()
			for i in 10:
				shuffle(tiles)
				if tiles != parts:
					break
			t["parts"] = parts
			t["tiles"] = tiles
			t["answer"] = e["word"]
			t["options"] = [e["word"]]
			t["option_style"] = "tiles"
			t["prompt"] = "le_prompt_syllables"
		"le_word_pic":
			var opts: Array = [e] + _distractors(e)
			shuffle(opts)
			t["options"] = opts.map(func(x): return x["word"])
			t["pictures"] = opts.map(func(x): return x["picture"])
			t["answer"] = e["word"]
			t["option_style"] = "pictures"
			t["prompt"] = "le_prompt_word_pic"
		"le_pic_word":
			var opts2: Array = [e] + _distractors(e)
			shuffle(opts2)
			t["options"] = opts2.map(func(x): return x["word"])
			t["answer"] = e["word"]
			t["option_style"] = "words"
			t["prompt"] = "le_prompt_pic_word"
	return t


func is_valid(t: Dictionary) -> bool:
	return validate(t)


static func validate(t: Dictionary) -> bool:
	if not ResourceLoader.exists(t["picture"]):
		return false
	match t["mode"]:
		"le_syllables":
			var parts: Array = t["parts"]
			var tiles: Array = (t["tiles"] as Array).duplicate()
			var p2: Array = parts.duplicate()
			tiles.sort()
			p2.sort()
			return "".join(parts) == t["word"] and tiles == p2 and t["answer"] == t["word"]
		"le_word_pic", "le_pic_word":
			var opts: Array = t["options"]
			if opts.size() != 4 or not t["answer"] in opts or opts.count(t["answer"]) != 1:
				return false
			var u := {}
			for o in opts:
				if u.has(o):
					return false
				u[o] = true
			if t["mode"] == "le_word_pic":
				for pth in t["pictures"]:
					if not ResourceLoader.exists(pth):
						return false
				return (t["pictures"] as Array).size() == 4
			return true
	return false
