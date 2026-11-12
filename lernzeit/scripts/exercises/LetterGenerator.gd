class_name LetterGenerator
extends MathGenerator
## "Deutsch · Buchstaben" tasks (no audio needed). Letters and words stay German.
## Modes:
##   de_find     – find the shown uppercase letter among similar letters
##   de_case     – matching lowercase for an uppercase letter (or the reverse)
##   de_first    – first letter of a pictured word (picture only, word not written)
##   de_missing  – which letter is missing in the word
##   de_build    – build the shown word from shuffled letter tiles
## The letter set grows with the difficulty (Leicht: M A O I L S E U).
## Picture words come from res://data/deutsch_words.json (alphabet pack + first kit).
## Spelling tasks only use words whose letters are all unlocked (kit README).

const ALL_MODES: Array[String] = ["de_find", "de_case", "de_first", "de_missing", "de_build"]

const LETTERS_EASY := ["M", "A", "O", "I", "L", "S", "E", "U"]
const LETTERS_AUTO := ["M", "A", "O", "I", "L", "S", "E", "U", "R", "T", "N", "H", "F", "D", "W", "B", "P", "K", "G"]
const LETTERS_ALL := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R",
	"S", "T", "U", "V", "W", "X", "Y", "Z", "Ä", "Ö", "Ü"]

## Letters that are easy to confuse (used as distractors first).
const SIMILAR := {
	"M": ["N", "W", "H"], "N": ["M", "H", "U"], "W": ["M", "V", "N"], "H": ["N", "M", "K"],
	"A": ["O", "E", "H"], "O": ["Q", "U", "A"], "U": ["O", "V", "N"], "E": ["F", "B", "A"],
	"F": ["E", "T", "P"], "B": ["D", "P", "R"], "D": ["B", "O", "P"], "P": ["B", "R", "F"],
	"R": ["P", "B", "K"], "I": ["L", "T", "J"], "L": ["I", "T", "E"], "T": ["F", "I", "L"],
	"S": ["Z", "B", "C"], "K": ["R", "H", "X"],
}
const SIMILAR_LOWER := {
	"m": ["n", "w", "h"], "n": ["m", "h", "u"], "w": ["m", "v", "n"], "h": ["n", "b", "k"],
	"a": ["o", "e", "d"], "o": ["a", "e", "c"], "u": ["n", "v", "o"], "e": ["a", "o", "c"],
	"f": ["t", "k", "l"], "b": ["d", "p", "q"], "d": ["b", "p", "q"], "p": ["q", "b", "d"],
	"r": ["n", "v", "t"], "i": ["j", "t", "f"], "l": ["t", "f", "k"], "t": ["f", "l", "k"],
	"s": ["z", "c", "e"], "k": ["h", "x", "t"],
}

const WORDS_FILE := "res://data/deutsch_words.json"

var allowed_modes: Array = ALL_MODES
static var _dictionary: Array = []


## [{word: "Löwe", upper: "LÖWE", letter: "L", picture: "res://..."}]
static func dictionary() -> Array:
	if _dictionary.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(WORDS_FILE))
		for e in (d["words"] if d is Dictionary else []):
			_dictionary.append({"word": e["word"], "upper": (e["word"] as String).to_upper(),
				"letter": e["letter"], "picture": e["picture"]})
	return _dictionary


func modes() -> Array:
	return allowed_modes


func letters() -> Array:
	match difficulty:
		"easy": return LETTERS_EASY
		"hard": return LETTERS_ALL
		_: return LETTERS_AUTO


func max_word_len() -> int:
	return {"easy": 4, "hard": 6}.get(difficulty, 5)


## Pictures whose first letter is unlocked (first-letter task).
func first_letter_words() -> Array:
	var ls := letters()
	return dictionary().filter(func(e): return e["letter"] in ls)


## Words for spelling tasks: short enough, no ß, umlauts only on "hard",
## every letter already unlocked (falls back to length/charset rules if too few).
func spelling_words() -> Array:
	var ls := letters()
	var ok_chars := func(e) -> bool:
		var u: String = e["upper"]
		if u.length() > max_word_len() or u.contains("ß") or u.contains("ẞ"):
			return false
		for i in u.length():
			var c := u.substr(i, 1)
			if c in ["Ä", "Ö", "Ü"] and difficulty != "hard":
				return false
		return true
	var base: Array = dictionary().filter(ok_chars)
	var unlocked: Array = base.filter(func(e):
		for i in (e["upper"] as String).length():
			if not (e["upper"] as String).substr(i, 1) in ls:
				return false
		return true)
	return unlocked if unlocked.size() >= 4 else base


func _pick(arr: Array):
	return arr[rng.randi_range(0, arr.size() - 1)]


func _letter_options(target: String, lower: bool) -> Array:
	var sim: Array = (SIMILAR_LOWER.get(target, []) if lower else SIMILAR.get(target, [])).duplicate()
	var pool: Array = []
	for c in sim:
		if c != target and not c in pool:
			pool.append(c)
	var all_l: Array = letters().map(func(c): return c.to_lower() if lower else c)
	shuffle(all_l)
	for c in all_l:
		if pool.size() >= 6:
			break
		if c != target and not c in pool:
			pool.append(c)
	var opts: Array = [target]
	for c in pool:
		if opts.size() < 4:
			opts.append(c)
	shuffle(opts)
	return opts


func make_task(mode: String) -> Dictionary:
	var t := {"mode": mode, "option_style": "letter"}
	match mode:
		"de_find":
			var l: String = _pick(letters())
			t["letter"] = l
			t["answer"] = l
			t["options"] = _letter_options(l, false)
			t["prompt"] = "de_prompt_find"
			t["args"] = {"l": l}
			t["key"] = "find:" + l
		"de_case":
			var l: String = _pick(letters().filter(func(c): return not c in ["Ä", "Ö", "Ü"]))
			var to_lower := rng.randf() < 0.65
			t["shown"] = l if to_lower else l.to_lower()
			t["answer"] = l.to_lower() if to_lower else l
			t["options"] = _letter_options(t["answer"], to_lower)
			t["prompt"] = "de_prompt_lower" if to_lower else "de_prompt_upper"
			t["args"] = {"l": t["shown"]}
			t["key"] = "case:%s:%s" % [l, to_lower]
		"de_first":
			var e: Dictionary = _pick(first_letter_words())
			t["word"] = e["upper"]
			t["picture"] = e["picture"]
			t["answer"] = e["letter"]
			t["options"] = _letter_options(t["answer"], false)
			t["prompt"] = "de_prompt_first"
			t["key"] = "first:" + e["word"]
		"de_missing":
			var e: Dictionary = _pick(spelling_words())
			var w: String = e["upper"]
			var hole := rng.randi_range(0, w.length() - 1)
			t["word"] = w
			t["hole"] = hole
			t["picture"] = e["picture"]
			t["answer"] = w.substr(hole, 1)
			var opts := _letter_options(t["answer"], false)
			t["options"] = opts
			t["prompt"] = "de_prompt_missing"
			t["key"] = "miss:%s:%d" % [w, hole]
		"de_build":
			var e: Dictionary = _pick(spelling_words().filter(func(x): return (x["upper"] as String).length() <= 5))
			var w: String = e["upper"]
			var tiles: Array = []
			for i in w.length():
				tiles.append(w.substr(i, 1))
			for attempt in 10:
				shuffle(tiles)
				if "".join(tiles) != w:
					break
			t["word"] = w
			t["picture"] = e["picture"]
			t["tiles"] = tiles
			t["answer"] = w
			t["options"] = [w]
			t["option_style"] = "tiles"
			t["prompt"] = "de_prompt_build"
			t["args"] = {"w": w}
			t["key"] = "build:" + w
	return t


func is_valid(t: Dictionary) -> bool:
	return validate(t)


static func validate(t: Dictionary) -> bool:
	match t["mode"]:
		"de_find":
			if t["answer"] != t["letter"]:
				return false
		"de_case":
			var shown: String = t["shown"]
			if t["answer"] == shown or (t["answer"] as String).to_upper() != shown.to_upper():
				return false
			for o in t["options"]:   # never mix cases among the options
				var lower: bool = t["answer"] == (t["answer"] as String).to_lower()
				if (o == (o as String).to_lower()) != lower:
					return false
		"de_first":
			if t["answer"] != (t["word"] as String).substr(0, 1) or not ResourceLoader.exists(t["picture"]):
				return false
		"de_missing":
			if t["answer"] != (t["word"] as String).substr(t["hole"], 1):
				return false
			if t["picture"] != "" and not ResourceLoader.exists(t["picture"]):
				return false
		"de_build":
			var a: Array = (t["tiles"] as Array).duplicate()
			var b: Array = []
			for i in (t["word"] as String).length():
				b.append((t["word"] as String).substr(i, 1))
			a.sort()
			b.sort()
			return a == b and t["answer"] == t["word"]
		_:
			return false
	var opts: Array = t["options"]
	if opts.size() != 4 or not t["answer"] in opts:
		return false
	var u := {}
	for o in opts:
		if u.has(o):
			return false
		u[o] = true
	return true
