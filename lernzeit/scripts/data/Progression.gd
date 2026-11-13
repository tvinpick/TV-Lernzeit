class_name Progression
extends RefCounted
## Experience points (XP) and levels ("Stufe"). Computed from the saved progress
## (like the achievements), so "Fortschritt zurücksetzen" also resets them.
##   right at the first try 10 XP, right later 3 XP, finished exercise +20 XP,
##   finished Lernkontrolle +30 XP.
## Level n → n+1 needs 100 + 40·(n−1) XP; every new level brings a sticker.

const XP_FIRST_TRY := 10
const XP_LATER := 3
const XP_COMPLETE := 20
const XP_TEST := 30


static func record_xp(r: ProgressRecord) -> int:
	return r.correct_count * XP_FIRST_TRY + (r.total_count - r.correct_count) * XP_LATER + (XP_COMPLETE if r.complete else 0)


static func xp_total() -> int:
	var xp := 0
	for r in ProgressRepository.get_records():
		xp += record_xp(r)
	for t in ProgressRepository.get_tests():
		xp += int(t.get("correct", 0)) * XP_FIRST_TRY + XP_TEST
	return xp


## XP needed to go from level n to n+1.
static func step(n: int) -> int:
	return 100 + 40 * (n - 1)


## [level, xp inside this level, xp needed for the next level]
static func level_info(xp: int) -> Array:
	var level := 1
	var rest := xp
	while rest >= step(level):
		rest -= step(level)
		level += 1
	return [level, rest, step(level)]


static func level() -> int:
	return level_info(xp_total())[0]
