class_name ZahlenreihenGenerator
extends MathGenerator
## "Zahlenreihen" (number sequences, up to 20): a row of 5–6 numbers with a constant
## step, one number is missing.
##   easy: steps 1 and 2, forwards        auto: steps 1, 2, 5, also backwards
##   hard: steps 2, 3, 4, 5, forwards and backwards, rows of 6
## Shown with the same number tiles as "Zähle weiter" (mode zr_step, stage cnt-style).

const ALL_MODES: Array[String] = ["zr_step"]


func modes() -> Array:
	return ALL_MODES


func make_task(_mode: String) -> Dictionary:
	var count := 6 if difficulty == "hard" else 5
	var steps: Array = ({"easy": [1, 2], "hard": [2, 3, 4, 5]}.get(difficulty, [1, 2, 2, 5]) as Array).filter(
		func(s): return s * (count - 1) <= max_value)       # the whole row fits into 0..max
	var step: int = steps[rng.randi_range(0, steps.size() - 1)]
	var backwards := difficulty != "easy" and rng.randf() < 0.4
	var top := max_value
	# all numbers of the row inside 0..top
	var span := step * (count - 1)
	var start := rng.randi_range(0, top - span)
	if step == 5 or (step == 2 and rng.randf() < 0.5):
		start -= start % step                      # 0, 5, 10 … / even numbers
	var seq: Array = []
	for i in count:
		seq.append(start + i * step)
	if backwards:
		seq.reverse()
	var hole := rng.randi_range(1 if difficulty == "easy" else 0, count - 1)
	if difficulty == "easy":
		hole = rng.randi_range(2, count - 1)       # two numbers before the gap show the step
	var answer: int = seq[hole]
	var d := -step if backwards else step
	var t := {"mode": "zr_step", "prompt": "add_prompt_missing", "option_style": "number", "max": max_value,
		"sequence": seq, "hole": hole, "step": step, "backwards": backwards, "answer": answer}
	# typical mistakes: counted by one instead of the step, or the step in the wrong direction
	t["options"] = number_options(answer, [answer + 1, answer - 1, answer + d, answer - d], 0, top)
	t["key"] = "zr:%d:%d:%d:%s" % [seq[0], step, hole, backwards]
	return t


func is_valid(t: Dictionary) -> bool:
	var seq: Array = t["sequence"]
	var d: int = -t["step"] if t["backwards"] else t["step"]
	for i in range(1, seq.size()):
		if seq[i] - seq[i - 1] != d:
			return false
	if seq.min() < 0 or seq.max() > max_value or t["answer"] != seq[t["hole"]]:
		return false
	return MathGenerator.options_ok(t, 4)
