class_name LogikGenerator
extends MathGenerator
## "Logik" tasks with the Logik kit pictures (assets/logik/objects) and the drawn
## shapes (assets/logik/shapes, tools/make_logik_shapes.py). Every task: 4 picture answers.
##   lg_muster      – continue the pattern (AB, AAB, ABB, ABC, AABB) of shapes / colours / objects
##   lg_formen      – shape → which thing has this shape? / thing → which shape is it?
##   lg_reihenfolge – picture stories: what comes next / what was first / what is in between
## Option values are picture paths (unique), so session.submit() compares paths.

const ALL_MODES: Array[String] = ["lg_muster", "lg_formen", "lg_reihenfolge"]
const SHAPES := ["Kreis", "Quadrat", "Rechteck", "Dreieck", "Stern", "Herz", "Raute"]
const BASIC_SHAPES := ["Kreis", "Quadrat", "Rechteck", "Dreieck"]
const COLORS := ["Rot", "Blau", "Gelb", "Gruen"]
## things for "Formen erkennen" (file name part after "Logik_Form_")
const FORM_OBJECTS := {
	"Kreis": ["Ball", "Uhr", "Pizza"],
	"Quadrat": ["Fenster", "Wuerfel", "Kissen"],
	"Dreieck": ["Zelt", "Pizzastueck"],
	"Rechteck": ["Tuer"],
}
## objects for object patterns
const PATTERN_OBJECTS := ["Muster_Fisch", "Muster_Birne", "Form_Ball", "Story_Blume", "Story_Kueken", "Form_Uhr"]
## picture stories in the right order
const STORIES := [
	["Story_Samen", "Story_Keimling", "Story_Blume"],
	["Story_Ei", "Story_Kueken", "Story_Huhn"],
	["Tag_Morgen", "Tag_Mittag", "Tag_Abend"],
]

var allowed_modes: Array = ALL_MODES


static func shape(s: String, c: String) -> String:
	return "res://assets/logik/shapes/Shape_%s_%s.png" % [s, c]


static func obj(name: String) -> String:
	return "res://assets/logik/objects/Logik_%s.png" % name


func modes() -> Array:
	return allowed_modes


## Few picture stories / things yet: shorter sessions (at least 6) without repeats.
func session_size(default_count: int = 10) -> int:
	var n := 0
	for m in allowed_modes:
		match m:
			"lg_muster":
				return default_count
			"lg_formen":
				var things := 0
				for s in FORM_OBJECTS:
					things += (FORM_OBJECTS[s] as Array).size()
				n += things * (1 if difficulty == "easy" else 2)
			"lg_reihenfolge":
				n += STORIES.size() * (2 if difficulty == "easy" else 3)
	return clampi(n, 6, default_count)


func _pick(arr: Array) -> Variant:
	return arr[rng.randi_range(0, arr.size() - 1)]


func _shuffled(arr: Array) -> Array:
	var a := arr.duplicate()
	shuffle(a)
	return a


func make_task(mode: String) -> Dictionary:
	match mode:
		"lg_muster": return _muster()
		"lg_formen": return _formen()
		"lg_reihenfolge": return _reihenfolge()
	return {}


## Options = answer + 3 distractors (preferring `near`, then `far`), shuffled.
func _options(answer: String, near: Array, far: Array) -> Array:
	var out: Array = [answer]
	for src in [_shuffled(near), _shuffled(far)]:
		for p in src:
			if out.size() < 4 and not p in out:
				out.append(p)
	shuffle(out)
	return out


# ------------------------------------------------------------------ Muster ---

func _muster() -> Dictionary:
	var kinds: Array = ["AB", "AAB", "ABB"]
	if difficulty != "easy":
		kinds += ["ABC", "AABB"]
	if difficulty == "hard":
		kinds += ["ABC", "AABB", "ABBC"]
	var kind: String = _pick(kinds)
	var letters := {}
	for ch in kind:
		letters[ch] = true
	var n := letters.size()
	# what changes along the row: colour (same shape), shape (same colour) or objects
	var variant: String = _pick(["color", "shape", "object"] if difficulty != "easy" else ["color", "object"])
	var units: Array = []          # picture per letter A, B, C
	var pool: Array = []           # similar pictures for distractors
	match variant:
		"color":
			var s: String = _pick(SHAPES)
			var cs := _shuffled(COLORS)
			for i in n:
				units.append(shape(s, cs[i]))
			for c in COLORS:
				pool.append(shape(s, c))
		"shape":
			var c: String = _pick(COLORS)
			var ss := _shuffled(SHAPES)
			for i in n:
				units.append(shape(ss[i], c))
			for s2 in SHAPES:
				pool.append(shape(s2, c))
		"object":
			var os := _shuffled(PATTERN_OBJECTS)
			for i in n:
				units.append(obj(os[i]))
			for o in PATTERN_OBJECTS:
				pool.append(obj(o))
	var seq: Array = []
	var shown := 7 if kind.length() >= 3 else 6
	if kind == "AABB" or kind == "ABBC":
		shown = 6 if rng.randf() < 0.5 else 7
	for i in shown + 1:
		seq.append(units["ABC".find(kind[i % kind.length()])])
	var answer: String = seq[shown]
	var t := {"mode": "lg_muster", "prompt": "lg_prompt_muster", "kind": kind, "variant": variant,
		"sequence": seq.slice(0, shown), "answer": answer, "option_style": "pictures"}
	t["options"] = _options(answer, units, pool)
	t["pictures"] = t["options"]
	t["key"] = "muster:%s:%s" % [kind, ",".join(PackedStringArray(units))]
	return t


# ------------------------------------------------------------------ Formen ---

func _formen() -> Dictionary:
	var to_object := difficulty == "easy" or rng.randf() < 0.6
	var shapes_with_things: Array = FORM_OBJECTS.keys()
	var s: String = _pick(shapes_with_things)
	var thing: String = _pick(FORM_OBJECTS[s])
	var color: String = _pick(COLORS)
	var t := {"mode": "lg_formen", "shape": s, "thing": thing, "option_style": "pictures"}
	if to_object:
		t["prompt"] = "lg_prompt_form_thing"
		t["show"] = shape(s, color)
		t["answer"] = obj("Form_" + thing)
		var others: Array = []
		for s2 in shapes_with_things:          # one thing of every other shape first
			if s2 != s:
				others.append(obj("Form_" + _pick(FORM_OBJECTS[s2])))
		var rest: Array = []
		for s2 in shapes_with_things:
			if s2 != s:
				for th in FORM_OBJECTS[s2]:
					rest.append(obj("Form_" + th))
		t["options"] = _options(t["answer"], others, rest)
		t["key"] = "formen:thing:%s" % thing
	else:
		t["prompt"] = "lg_prompt_thing_form"
		t["show"] = obj("Form_" + thing)
		t["answer"] = shape(s, color)
		var near: Array = []
		for s2 in BASIC_SHAPES:
			if s2 != s:
				near.append(shape(s2, color))
		t["options"] = _options(t["answer"], near, [])
		t["key"] = "formen:form:%s" % thing
	t["pictures"] = t["options"]
	return t


# ------------------------------------------------------------- Reihenfolge ---

func _reihenfolge() -> Dictionary:
	var story: Array = _pick(STORIES)
	var kinds: Array = ["next", "first"]
	if difficulty != "easy":
		kinds.append("middle")
	var kind: String = _pick(kinds)
	var hole: int = {"next": 2, "first": 0, "middle": 1}[kind]
	var frames: Array = story.map(func(x): return obj(x))
	var others: Array = []
	for st in STORIES:
		if st != story:
			for x in st:
				others.append(obj(x))
	var t := {"mode": "lg_reihenfolge", "prompt": "lg_prompt_" + kind, "kind": kind, "frames": frames,
		"hole": hole, "answer": frames[hole], "option_style": "pictures"}
	var same: Array = frames.filter(func(p): return p != frames[hole])
	t["options"] = _options(t["answer"], same, others)
	t["pictures"] = t["options"]
	t["key"] = "reihe:%s:%s" % [story[0], kind]
	return t


# -------------------------------------------------------------- validation ---

func is_valid(t: Dictionary) -> bool:
	return validate(t)


static func validate(t: Dictionary) -> bool:
	var opts: Array = t.get("options", [])
	if opts.size() != 4 or opts.count(t["answer"]) != 1:
		return false
	var u := {}
	for o in opts:
		if u.has(o) or not ResourceLoader.exists(o):
			return false
		u[o] = true
	match t["mode"]:
		"lg_muster":
			var seq: Array = t["sequence"]
			var k: String = t["kind"]
			# the pattern really repeats and the answer continues it
			var full: Array = seq + [t["answer"]]
			for i in full.size():
				var j := i - k.length()
				if j >= 0 and full[i] != full[j]:
					return false
			return seq.size() >= k.length() + 2 and seq.all(func(p): return ResourceLoader.exists(p))
		"lg_formen":
			if not ResourceLoader.exists(t["show"]):
				return false
			if t["prompt"] == "lg_prompt_form_thing":
				# exactly one option is a thing of the shown shape
				var good := 0
				for o in opts:
					for th in FORM_OBJECTS[t["shape"]]:
						if o == obj("Form_" + th):
							good += 1
				return good == 1
			return t["answer"].contains("Shape_" + t["shape"] + "_")
		"lg_reihenfolge":
			var frames: Array = t["frames"]
			return frames.size() == 3 and t["answer"] == frames[t["hole"]]
	return false
