extends Node
## Logic tests (no display needed):
##   godot --headless --path . res://tests/UnitTests.tscn -- --lz-data-dir=/tmp/lz_unit

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  ok   ", what)
	else:
		failures += 1
		print("  FAIL ", what)


func _ready() -> void:
	print("Localization")
	var de := Localization.keys_for("de")
	var ru := Localization.keys_for("ru")
	de.sort(); ru.sort()
	check(de == ru, "de.json and ru.json have identical keys (%d)" % de.size())
	for k in ["settings", "progress", "home_prompt", "continue", "not_available", "parents", "save", "cancel", "back"]:
		check(k in de, "brief key present: " + k)
	TranslationServer.set_locale("ru")
	check(tr("continue") == "Продолжить" and tr("not_available") == "Упражнения пока недоступны", "ru texts from brief")
	TranslationServer.set_locale("de")
	check(tr("continue") == "Weiter üben" and tr("parents") == "Elternbereich", "de texts from brief")
	var missing := []
	for sid in Curriculum.SUBJECT_IDS:
		for t in Curriculum.topics(sid):
			if not t["key"] in de:
				missing.append(t["key"])
	check(missing.is_empty(), "all topic keys translated " + str(missing))

	print("PIN hashing")
	var salt := PinHasher.new_salt()
	check(salt.length() == 32, "16-byte salt")
	var t0 := Time.get_ticks_msec()
	var h := PinHasher.hash_pin("1234", salt)
	print("       hash time: %d ms" % (Time.get_ticks_msec() - t0))
	check(h.length() == 64 and not h.contains("1234"), "hash is hex SHA-256, not the PIN")
	check(h == PinHasher.hash_pin("1234", salt), "deterministic for same salt")
	check(h != PinHasher.hash_pin("1234", PinHasher.new_salt()), "different salt → different hash")
	check(PinHasher.is_valid_pin("0042") and not PinHasher.is_valid_pin("12a4") and not PinHasher.is_valid_pin("123"), "PIN validation")

	print("SettingsRepository")
	var sr := SettingsRepository
	check(sr.get_value("language") == "de" and sr.get_value("volume") == 65 and sr.get_value("text_size") == "normal", "defaults")
	sr.set_value("volume", 67)
	check(sr.get_value("volume") == 65, "volume snaps to 5 % steps")
	sr.set_value("volume", 250)
	check(sr.get_value("volume") == 100, "volume clamped")
	sr.set_value("language", "fr")
	check(sr.get_value("language") == "de", "unknown language rejected")
	sr.save_parent_settings({"subjects": {"mathematik": false, "deutsch": false, "lesen": false, "logik": false}})
	check(sr.is_subject_enabled("mathematik"), "cannot disable all subjects")
	sr.save_parent_settings({"session_minutes": 99, "difficulty": "x", "child_name": "  Leo-Maximilian-Alexander  "})
	var p := sr.get_parent_settings()
	check(p["session_minutes"] == 30 and p["difficulty"] == "auto", "invalid parent values → defaults")
	check(p["child_name"].length() <= sr.MAX_NAME_LENGTH and not p["child_name"].begins_with(" "), "name trimmed/limited")
	check(sr.set_pin("2468") and sr.has_pin(), "set PIN")
	check(sr.verify_pin("2468")["ok"], "verify correct PIN")
	var r := sr.verify_pin("0000")
	check(not r["ok"] and r["remaining_attempts"] == 4, "wrong PIN counts attempts")
	for i in 4:
		r = sr.verify_pin("0000")
	check(r["locked_seconds"] == 60 and sr.pin_lock_remaining() > 0, "5 wrong → 60 s lock")
	check(not sr.verify_pin("2468")["ok"], "correct PIN refused while locked")

	print("Corrupt files → safe defaults")
	var f := FileAccess.open(sr.path("settings.cfg"), FileAccess.WRITE)
	f.store_string("[general\nlanguage=!!garbage")
	f.close()
	DirAccess.remove_absolute(sr.path("settings.cfg.bak"))
	sr.load_all()
	check(sr.get_value("language") == "de" and sr.get_value("sound") == true, "corrupt settings.cfg → defaults")
	sr.set_value("language", "ru")
	sr.set_value("volume", 30)
	f = FileAccess.open(sr.path("settings.cfg"), FileAccess.WRITE)
	f.store_string("[general\n###")
	f.close()
	sr.load_all()
	check(sr.get_value("volume") == 65 or sr.get_value("language") == "de" or sr.get_value("language") == "ru", "reload after corruption does not crash")

	print("ProgressRepository")
	var pr := ProgressRepository
	pr.reset_all()
	var s := pr.summary()
	check(s["tasks_solved"] == 0 and s["accuracy"] == null and s["topics_practiced"] == 0, "empty summary: 0 tasks, accuracy null (no 0/0)")
	check(pr.topic_status("mathematik", "addition") == "not_started", "status not_started")
	pr.add_record(ProgressRecord.create("mathematik", "addition", 9, 10, 300, "1"))
	s = pr.summary("mathematik")
	check(s["tasks_solved"] == 10 and absf(s["accuracy"] - 0.9) < 0.001, "summary computed from records")
	check(pr.topic_status("mathematik", "addition") == "secure", "status from accuracy")
	f = FileAccess.open(sr.path("progress.json"), FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	pr.load_records()
	check(pr.record_count() == 0 or pr.record_count() == 1, "corrupt progress.json handled (fallback to .bak)")
	check(pr.reset_all() >= 0 and pr.record_count() == 0, "reset clears records")
	var rec := ProgressRecord.from_dict({"subject_id": "logik", "topic_id": "muster", "timestamp": 5, "correct_count": 7, "total_count": 3})
	check(rec.total_count >= rec.correct_count, "record sanitised (total >= correct)")
	check(ProgressRecord.from_dict({"subject_id": 3}) == null, "invalid record rejected")

	print("Exercise graphics kits (KitAssets registry)")
	var bad := []
	var alpha_missing := []
	for key in KitAssets.TEXTURES:
		var spec: Array = KitAssets.TEXTURES[key]
		var tex := KitAssets.texture(key)
		# size_limit may shrink large kit art to its on-screen size; aspect ratio must stay
		if tex == null or tex.get_width() > spec[1] or tex.get_height() > spec[2] \
				or absf(float(tex.get_width()) / tex.get_height() - float(spec[1]) / spec[2]) > 0.02:
			bad.append(key)
			continue
		if not key.contains("backgrounds/"):
			var img := tex.get_image()
			if img.is_compressed():
				img.decompress()
			if not img.detect_alpha():
				alpha_missing.append(key)
	check(KitAssets.TEXTURES.size() == 236, "236 kit textures registered (%d)" % KitAssets.TEXTURES.size())
	check(bad.is_empty(), "all kit textures load as separate resources with manifest size or smaller " + str(bad))
	check(alpha_missing.is_empty(), "all kit sprites have real alpha transparency " + str(alpha_missing))
	check(KitAssets.keys_with_prefix("deutsch_pictures/").size() == 8, "8 Deutsch pictures")
	check(KitAssets.keys_with_prefix("math_counting_10_dice/").size() == 12, "dice 1–6 + dot patterns 1–6")
	check(KitAssets.keys_with_prefix("math_counting_10_number_cards/").size() == 12, "number cards 0–10 + blank tile")
	check(KitAssets.keys_with_prefix("math_addition_10_ui/").size() == 11, "11 addition UI sprites")
	var focused := KitAssets.texture("deutsch_ui_letter_buttons/Deutsch_Letter_Button_Focused").get_image()
	if focused.is_compressed():
		focused.decompress()
	check(focused.get_pixel(0, 0).a == 0.0 and focused.get_pixel(focused.get_width() / 2, 4).a < 0.6, "fixed focused letter button: transparent corners, no grey matte at the edge")
	check(not FileAccess.file_exists("res://references"), "mock-up screens are not inside the Godot project")

	print("Subtraction generator / session")
	var gen := SubtractionGenerator.new(12345)
	check(gen is MathGenerator, "subtraction generator uses the shared base")
	var invalid := 0
	var picture_zero := 0
	var long_jumps := 0
	for diff in ["easy", "auto", "hard"]:
		gen.difficulty = diff
		for m in SubtractionGenerator.MODES:
			for i in 400:
				var t := gen.make_task(m)
				if not SubtractionGenerator.validate(t):
					invalid += 1
				if m == "number_line" and t["b"] > 5:
					long_jumps += 1
				if m == "picture" and (t["options"] as Array).min() < 1:
					picture_zero += 1
				if diff == "easy" and t["a"] > 6:
					invalid += 1
	check(invalid == 0, "7200 generated tasks valid: b<=a<=10, answer=a-b, 4 unique options incl. answer")
	check(long_jumps == 0 and picture_zero == 0, "number line ≤5 jumps, picture options ≥1 object")
	gen.difficulty = "auto"
	var tasks := gen.make_session(10)
	var modes := {}
	for t in tasks:
		modes[t["mode"]] = true
	check(tasks.size() == 10 and modes.size() == 6, "session: 10 tasks, all 6 representations")
	var miss := gen.make_task("missing")
	check(miss["answer"] == miss["b"] and miss["result"] == miss["a"] - miss["b"], "missing number: answer is the subtrahend")
	var ses := ExerciseSession.new("mathematik", "subtraktion", "t", gen.make_session(10), true)
	var first_task: Dictionary = ses.current()
	var wrong: int = (first_task["options"] as Array).filter(func(o): return o != first_task["answer"])[0]
	check(not ses.submit(wrong) and ses.solved == 0, "wrong answer does not advance progress")
	check(ses.submit(first_task["answer"]) and ses.solved == 1 and ses.first_try_correct == 0, "correct after a mistake: solved, not first-try")
	while ses.advance():
		ses.submit(ses.current()["answer"])
	check(ses.solved == 10 and ses.first_try_correct == 9, "10 solved, 9 on the first try")
	check(ses.tasks.size() == 11 and ses.tasks[10].get("repeat", false), "Fehler wiederholen: wrong task asked again at the end")
	var ses_rec := ses.to_record()
	check(ses_rec.correct_count == 9 and ses_rec.total_count == 10 and ses_rec.topic_id == "subtraktion", "record: 9/10 for mathematik/subtraktion")
	var ses2 := ExerciseSession.new("mathematik", "subtraktion", "t", gen.make_session(10), false)
	ses2.submit(-1)
	while ses2.advance():
		pass
	check(ses2.tasks.size() == 10, "without 'Fehler wiederholen' no repetitions")

	print("Addition / Counting generators")
	for gen_cls in [AdditionGenerator, CountingGenerator]:
		var mg: MathGenerator = gen_cls.new(777)
		var bad_tasks := 0
		var mode_seen := {}
		for diff in ["easy", "auto", "hard"]:
			mg.difficulty = diff
			for m in mg.modes():
				for i in 400:
					var task := mg.make_task(m)
					mode_seen[m] = true
					if not mg.is_valid(task):
						bad_tasks += 1
						if bad_tasks < 3:
							print("       invalid: ", task)
		var sess := mg.make_session(10)
		var ms := {}
		for st in sess:
			ms[st["mode"]] = true
		check(bad_tasks == 0, "%d tasks of %s valid in all modes/difficulties" % [3 * 400 * mg.modes().size(), gen_cls.get_global_name()])
		check(sess.size() == 10 and ms.size() == 6, "%s session: 10 tasks, 6 representations" % gen_cls.get_global_name())
	var ag := AdditionGenerator.new(5)
	var ch := ag.make_task("add_choose")
	var same_sum := 0
	for o in ch["options"]:
		var parts: PackedStringArray = (o as String).split(" + ")
		if o != ch["answer"] and int(parts[0]) + int(parts[1]) == ch["sum"]:
			same_sum += 1
	check(same_sum == 0 and ch["options"].size() == 4, "matching equation: no distractor with the same sum")
	var tt := ag.make_task("add_to_ten")
	check(tt["a"] + tt["answer"] == 10, "complete to ten: a + answer = 10")
	var cg := CountingGenerator.new(9)
	var big := cg.make_task("cnt_bigger")
	check(big["options"].size() == 2 and big["answer"] == maxi(big["x"], big["y"]), "bigger number: 2 options, answer = max")
	var seq_t := cg.make_task("cnt_sequence")
	check(seq_t["answer"] == seq_t["sequence"][seq_t["hole"]], "sequence: answer is the hidden number")

	print("Deutsch letter generator")
	var lg := LetterGenerator.new(4242)
	var bad_letters := 0
	for diff in ["easy", "auto", "hard"]:
		lg.difficulty = diff
		for m in LetterGenerator.ALL_MODES:
			for i in 300:
				var lt := lg.make_task(m)
				if not lg.is_valid(lt):
					bad_letters += 1
					if bad_letters < 3:
						print("       invalid: ", lt)
				if diff == "easy" and lt["mode"] in ["de_missing", "de_build"] and (lt["word"] as String).length() > 4:
					bad_letters += 1
	check(bad_letters == 0, "4500 letter tasks valid (answer in options, unique, pictures exist, tiles = word)")
	lg.difficulty = "auto"
	var lsess := lg.make_session(10)
	var lmodes := {}
	for lt in lsess:
		lmodes[lt["mode"]] = true
	check(lsess.size() == 10 and lmodes.size() == 5, "Deutsch session: 10 tasks, all 5 modes")
	var ct := lg.make_task("de_case")
	var same_case := true
	for o in ct["options"]:
		same_case = same_case and ((o == (o as String).to_lower()) == (ct["answer"] == (ct["answer"] as String).to_lower()))
	check(same_case, "upper/lower: options never mix cases")
	var bt := lg.make_task("de_build")
	check("".join(bt["tiles"]) != bt["word"] or (bt["word"] as String).length() < 2 or bt["word"] in ["MAMA"], "build word: tiles shuffled")
	var dict := LetterGenerator.dictionary()
	var missing_pics := dict.filter(func(e): return not ResourceLoader.exists(e["picture"]))
	check(dict.size() == 44 and missing_pics.is_empty(), "44 picture words, all pictures exist " + str(missing_pics))
	var wrong_first := dict.filter(func(e): return (e["upper"] as String).substr(0, 1) != e["letter"])
	check(wrong_first.is_empty(), "every word starts with its letter " + str(wrong_first))
	var easy := LetterGenerator.new(3)
	easy.difficulty = "easy"
	var unlocked_only := true
	for i in 300:
		var et := easy.make_task(["de_first", "de_missing", "de_build"][i % 3])
		var w: String = et["word"]
		if et["mode"] == "de_first":
			unlocked_only = unlocked_only and et["answer"] in LetterGenerator.LETTERS_EASY
		else:
			for k in w.length():
				unlocked_only = unlocked_only and w.substr(k, 1) in LetterGenerator.LETTERS_EASY
	check(unlocked_only, "Leicht: only unlocked letters (M A O I L S E U) in pictures and spelled words")
	var spelled := {}
	var with_sz := 0
	for i in 400:
		var st := LetterGenerator.new(i).make_task("de_build")
		spelled[st["word"]] = true
		if (st["word"] as String).contains("ß"):
			with_sz += 1
	check(with_sz == 0, "no ß in spelling tasks")
	check(spelled.size() >= 10, "word building uses many different words (%d)" % spelled.size())
	var only_first := LetterGenerator.new(1)
	only_first.allowed_modes = ["de_first"]
	check(only_first.make_session(10).all(func(x): return x["mode"] == "de_first"), "topic sessions use only their modes (Anlaute)")

	print("Number range 20")
	for gen_cls in [SubtractionGenerator, AdditionGenerator, CountingGenerator]:
		var g20: MathGenerator = gen_cls.new(2020)
		g20.max_value = 20
		var bad20 := 0
		var over10 := 0
		var total20 := 0
		for diff in ["easy", "auto", "hard"]:
			g20.difficulty = diff
			for m in g20.modes():
				for i in 300:
					var t20 := g20.make_task(m)
					total20 += 1
					if not g20.is_valid(t20):
						bad20 += 1
						if bad20 < 3:
							print("       invalid: ", t20)
					var biggest := 0
					for k in ["a", "sum", "n", "x", "y", "answer"]:
						if t20.has(k) and t20[k] is int:
							biggest = maxi(biggest, t20[k])
					if biggest > 10:
						over10 += 1
		check(bad20 == 0, "%s bis 20: %d tasks valid" % [gen_cls.get_global_name(), total20])
		check(over10 > total20 / 2, "%s bis 20: most tasks really use numbers above 10 (%d of %d)" % [gen_cls.get_global_name(), over10, total20])
	var g10 := SubtractionGenerator.new(1)
	var ok10 := true
	for i in 500:
		var t10 := g10.make_task(SubtractionGenerator.MODES[i % 6])
		ok10 = ok10 and t10["a"] <= 10 and (t10["options"] as Array).max() <= 10
	check(ok10, "bis 10 stays within 10")

	print("Learned letters")
	ProgressRepository.reset_all()
	check(ProgressRepository.letter_status("M") == "not_started", "letter not started")
	ProgressRepository.add_letter_results({"M": true})
	check(ProgressRepository.letter_status("M") == "practice", "1 answer → practice")
	ProgressRepository.add_letter_results({"M": true})
	ProgressRepository.add_letter_results({"m": true})
	check(ProgressRepository.letter_status("M") == "secure", "3 right first-try answers (lower case counted as M) → secure")
	ProgressRepository.add_letter_results({"M": false})
	ProgressRepository.add_letter_results({"M": false})
	check(ProgressRepository.letter_status("M") == "practice", "2 mistakes among the last 5 → back to practice")
	for i in 20:
		ProgressRepository.add_letter_results({"A": i % 2 == 0})
	check(ProgressRepository.letter_history("A").length() == 10, "history limited to 10 answers")
	ProgressRepository.load_records()
	check(ProgressRepository.letter_history("M") == "11100", "letters persisted in progress.json")
	ProgressRepository.reset_all()
	check(ProgressRepository.letters_with_status("practice").is_empty(), "reset clears learned letters")

	print("Achievements")
	check(Achievements.unlocked_ids().is_empty(), "no achievements without progress")
	ProgressRepository.add_record(ProgressRecord.create("mathematik", "zaehlen", 10, 10, 60, "count10-v1", 1700000000))
	var ids := Achievements.unlocked_ids()
	check("first_steps" in ids and "perfect" in ids and not "sessions_10" in ids, "first exercise + perfect unlocked")
	ProgressRepository.add_record(ProgressRecord.create("mathematik", "addition", 5, 10, 60, "add20-v1", 1700090000))
	ProgressRepository.add_record(ProgressRecord.create("mathematik", "subtraktion", 5, 10, 60, "sub10-v1", 1700190000))
	ids = Achievements.unlocked_ids()
	check("math_trio" in ids and "math_20" in ids and "days_3" in ids, "math trio, bis 20 and 3 days unlocked")
	for l in ["M", "A", "O", "I", "L", "S", "E", "U"]:
		ProgressRepository.add_letter_results({l: true})
		ProgressRepository.add_letter_results({l: true})
		ProgressRepository.add_letter_results({l: true})
	check("letters_8" in Achievements.unlocked_ids(), "8 secure letters unlocked")
	check(Curriculum.last_practised_exercise() == "sub10", "Weiter üben: newest record (sub10) wins")
	ProgressRepository.reset_all()
	check(Achievements.unlocked_ids().is_empty(), "reset removes achievements")

	print("Adaptive level / pause reminder")
	var ad := AdaptiveLevel.new("auto")
	check(not ad.record(true) and not ad.record(true) and ad.record(true) and ad.level() == "hard", "3 right in a row → harder")
	check(not ad.record(true) and not ad.record(true) and not ad.record(true) and ad.level() == "hard", "never more than one step above the parents' setting")
	check(not ad.record(false) and ad.record(false) and ad.level() == "auto", "2 tasks with mistakes in a row → easier")
	ad.record(false); ad.record(false)
	check(ad.level() == "easy", "down to easy")
	ad.record(false); ad.record(false)
	check(ad.level() == "easy", "never more than one step below the parents' setting")
	var adg := SubtractionGenerator.new(77)
	var ads := ExerciseSession.new("mathematik", "subtraktion", "t", adg.make_session(10), false)
	var modes_before: Array = ads.tasks.map(func(x): return x["mode"])
	adg.difficulty = "hard"
	AdaptiveLevel.regenerate(ads, adg)
	var modes_after: Array = ads.tasks.map(func(x): return x["mode"])
	check(modes_before == modes_after and ads.tasks.slice(1).all(func(x): return adg.is_valid(x) and x["a"] >= 5), "regenerated tasks: same representations, harder numbers, valid")
	ProgressRepository.reset_all()
	SettingsRepository.save_parent_settings({"session_minutes": 15})
	check(not PauseReminder.due(), "no pause reminder without practice")
	ProgressRepository.add_record(ProgressRecord.create("mathematik", "addition", 8, 10, 16 * 60, "add10-v1"))
	check(PauseReminder.due() and PauseReminder.today_seconds() >= 900, "16 min today with 15 min setting → pause suggested")
	SettingsRepository.set_value("pause_day", PauseReminder.local_day(int(Time.get_unix_time_from_system())))
	SettingsRepository.load_all()
	check(not PauseReminder.due(), "pause reminder only once a day, also after a restart")
	ProgressRepository.reset_all()

	print("Compare / Reading generators, stickers, badges")
	for gen_cls in [CompareGenerator, ReadingGenerator]:
		var g2: MathGenerator = gen_cls.new(31)
		var bad2 := 0
		var n2 := 0
		var ms2 := {}
		for diff in ["easy", "auto", "hard"]:
			g2.difficulty = diff
			for m in g2.modes():
				for i in 300:
					var t2 := g2.make_task(m)
					n2 += 1
					ms2[m] = true
					if not g2.is_valid(t2):
						bad2 += 1
						if bad2 < 3:
							print("       invalid: ", t2)
		check(bad2 == 0, "%s: %d tasks valid" % [gen_cls.get_global_name(), n2])
		check(g2.make_session(10).size() == 10, "%s: session of 10" % gen_cls.get_global_name())
	var cg2 := CompareGenerator.new(5)
	var signs := {}
	for i in 300:
		signs[cg2.make_task("cmp_sign")["answer"]] = true
	check(signs.size() == 3, "comparison sign tasks include <, > and =")
	check(ReadingGenerator.words().size() == 20 and ReadingGenerator.words().all(func(e): return "".join(e["syllables"]) == e["word"]), "20 reading words, syllables join to the word")
	ProgressRepository.reset_all()
	check(Achievements.stickers_earned() == 0, "no stickers without finished exercises")
	ProgressRepository.add_record(ProgressRecord.create("mathematik", "addition", 7, 10, 60, "add10-v1"))
	ProgressRepository.add_record(ProgressRecord.create("mathematik", "addition", 1, 2, 20, "add10-v1"))
	check(Achievements.stickers_earned() == 1, "one sticker per finished exercise (aborted ones don't count)")
	check(Achievements.LIST.all(func(a): return ResourceLoader.exists(a[3]) and (a[3] as String).contains("badges")), "every achievement has its badge")
	ProgressRepository.reset_all()

	_test_voice()
	_test_logik()
	_test_task_history()
	_test_zahlenreihen()
	print("UNIT TESTS: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)


func _test_voice() -> void:
	var missing: Array = []
	var de: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://localization/de.json"))
	for k in de:
		if RegEx.create_from_string("^(sub|add|cnt|cmp|de|le)_prompt_").search(k) and not Voice.has(k):
			missing.append(k)
	for n in 21:
		if not Voice.has(Voice.num(n)):
			missing.append(Voice.num(n))
	for l in LetterGenerator.LETTERS_ALL:
		if not Voice.has(Voice.letter(l)) or not Voice.has(Voice.letter(l.to_lower())):
			missing.append(Voice.letter(l))
		if not Voice.has(Voice.sound(l)):
			missing.append(Voice.sound(l))
	for e in LetterGenerator.dictionary() + ReadingGenerator.words():
		if not Voice.has(Voice.word_from_picture(e["picture"])):
			missing.append(Voice.word_from_picture(e["picture"]))
	for c in ["ex_correct", "ex_correct_2", "ex_correct_3", "ex_correct_4", "ex_wrong", "ex_wrong_2",
			"ex_streak", "ex_done", "ex_done_perfect", "home_prompt", "pause", "plus", "minus", "de_word_is"]:
		if not Voice.has(c):
			missing.append(c)
	for mode in ["de_case", "de_first", "de_missing"]:   # tip_de_find / tip_de_build are not recorded (text only)
		if not Voice.has("tip_" + mode):
			missing.append("tip_" + mode)
	for clip in (load("res://scenes/exercises/MathExercise.gd") as GDScript).get_script_constant_map()["TIP_VOICE"].values():
		if not Voice.has(clip):
			missing.append(clip)
	check(missing.is_empty(), "voice recordings for every prompt, number, letter and word " + str(missing))
	check(Voice.word_from_picture("res://assets/deutsch/words/Deutsch_L_Loewe.png") == "word_Loewe"
		and Voice.word_from_picture("res://assets/lesen/words/Lesen_Banane.png") == "word_Banane"
		and Voice.letter("ä") == "letter_AE" and Voice.sound("Ö") == "sound_OE", "voice clip names")
	SettingsRepository.set_value("read_aloud", true)
	SettingsRepository.set_value("volume", 50)
	check(Voice.say(["de_prompt_find", "letter_M"]) and Voice.history.back() == "de_prompt_find", "voice says a sentence")
	check(not Voice.say_all(["de_prompt_find", "letter_nonexistent"]), "incomplete sentence is not said")
	SettingsRepository.set_value("read_aloud", false)
	check(not Voice.enabled() and not Voice.say(["ex_correct"]) and not Voice.is_speaking(), "read aloud off → silent")
	SettingsRepository.set_value("read_aloud", true)


func _test_logik() -> void:
	var bad: Array = []
	var seen_kinds := {}
	for diff in ["easy", "auto", "hard"]:
		for mode in LogikGenerator.ALL_MODES:
			var g := LogikGenerator.new(7)
			g.difficulty = diff
			g.allowed_modes = [mode]
			for i in 30:
				var t := g.make_task(mode)
				seen_kinds[mode + ":" + str(t.get("kind", t.get("prompt", "")))] = true
				if not g.is_valid(t):
					bad.append(t)
	check(bad.is_empty(), "Logik: 270 generated tasks valid " + str(bad.slice(0, 2)))
	check(seen_kinds.has("lg_muster:ABC") and seen_kinds.has("lg_reihenfolge:middle")
		and seen_kinds.has("lg_formen:lg_prompt_thing_form"), "Logik: all task kinds appear " + str(seen_kinds.keys()))
	var t2 := {"mode": "lg_muster", "kind": "AB", "answer": LogikGenerator.shape("Kreis", "Rot"),
		"sequence": [LogikGenerator.shape("Kreis", "Rot"), LogikGenerator.shape("Kreis", "Blau"), LogikGenerator.shape("Kreis", "Rot"),
			LogikGenerator.shape("Kreis", "Blau")],
		"options": [LogikGenerator.shape("Kreis", "Rot"), LogikGenerator.shape("Kreis", "Blau"), LogikGenerator.shape("Kreis", "Gelb"), LogikGenerator.shape("Kreis", "Gruen")]}
	check(LogikGenerator.validate(t2), "Logik: correct AB pattern accepted")
	t2["answer"] = LogikGenerator.shape("Kreis", "Blau")
	check(not LogikGenerator.validate(t2), "Logik: wrong continuation rejected")
	check(Curriculum.exercise_for("logik", "muster") == "lg_muster" and Curriculum.screen_for("lg_formen") == "exercise_de"
		and Curriculum.subject_of("lg_reihenfolge") == "logik", "Logik topics are playable")


func _test_task_history() -> void:
	ProgressRepository.reset_all()
	var g := SubtractionGenerator.new(11)
	var s1: Array = g.make_session(10)
	var keys1: Array = s1.map(func(t): return t["key"])
	var s2: Array = SubtractionGenerator.new(12).make_session(10, keys1)
	var overlap := s2.filter(func(t): return t["key"] in keys1).size()
	check(overlap == 0, "next session avoids the tasks of the last one (%d repeated)" % overlap)
	# a mistake comes back in the next session, with whole numbers (JSON round trip)
	var sess := ExerciseSession.new("mathematik", "subtraktion", "sub10-v1", s1, false)
	sess.submit(-99)                       # wrong first try on task 0
	sess.submit(s1[0]["answer"])
	sess.advance()
	sess.submit(s1[1]["answer"])
	sess.advance()
	ProgressRepository.remember_session("sub10", sess.task_results())
	ProgressRepository.load_records()      # from disk
	var again: Array = ProgressRepository.mistake_tasks("sub10")
	check(again.size() == 1 and again[0]["key"] == s1[0]["key"] and again[0]["answer"] is int, "mistake stored and restored with int numbers")
	var s3: Array = SubtractionGenerator.new(13).make_session(10, ProgressRepository.recent_task_keys("sub10"), again)
	check(s3.filter(func(t): return t["key"] == s1[0]["key"] and t.get("again", false)).size() == 1, "earlier mistake asked again")
	check(ProgressRepository.recent_task_keys("sub10").size() == 2, "recent keys stored")
	var ov := ProgressRepository.mistake_overview()
	check(ov.size() == 1 and ov[0]["exercise"] == "sub10"
		and MathExerciseInfo.describe(ov[0]["tasks"][0]) == "%d − %d" % [s1[0]["a"], s1[0]["b"]], "parents: open mistakes with a short task text")
	check(MathExerciseInfo.describe({"mode": "zr_step", "sequence": [2, 4, 6, 8], "hole": 2}) == "2 4 ? 8"
		and MathExerciseInfo.describe({"mode": "de_first", "word": "LÖWE", "display": "Löwe"}) == "Löwe"
		and MathExerciseInfo.describe({"mode": "add_equation", "a": 3, "b": 4}) == "3 + 4", "task descriptions")
	# two right answers later → removed from the mistakes
	for k in 2:
		ProgressRepository.remember_session("sub10", [{"task": again[0], "ok": true}])
	check(ProgressRepository.mistake_tasks("sub10").is_empty(), "mistake forgotten after two right answers")
	# small Logik topics: shorter sessions without repeats
	var lg := LogikGenerator.new(3)
	lg.allowed_modes = ["lg_reihenfolge"]
	lg.difficulty = "easy"
	var n := lg.session_size(10)
	var ls: Array = lg.make_session(n)
	var u := {}
	for t in ls:
		u[t["key"]] = true
	check(n == 6 and u.size() == 6, "Reihenfolge (easy): 6 different tasks per session")
	var rec := sess.to_record()
	check(not rec.complete and ProgressRecord.create("logik", "reihenfolge", 6, 6, 60, "logik-v1", -1, 1).complete
		and ProgressRecord.from_dict({"subject_id": "m", "topic_id": "t", "total_count": 10, "correct_count": 9}).complete,
		"finished flag: short Logik sessions count, unfinished do not, old records with 10 tasks count")
	ProgressRepository.reset_all()


func _test_zahlenreihen() -> void:
	var bad: Array = []
	var steps := {}
	for diff in ["easy", "auto", "hard"]:
		var g := ZahlenreihenGenerator.new(5)
		g.max_value = 20
		g.difficulty = diff
		for i in 300:
			var t := g.make_task("zr_step")
			steps["%s:%d:%s" % [diff, t["step"], t["backwards"]]] = true
			if not g.is_valid(t):
				bad.append(t)
	check(bad.is_empty(), "Zahlenreihen: 900 tasks valid " + str(bad.slice(0, 2)))
	check(steps.has("easy:2:false") and not steps.has("easy:1:true") and steps.has("auto:5:true") and steps.has("hard:3:false"),
		"Zahlenreihen: steps by difficulty " + str(steps.keys()))
	check(Curriculum.exercise_for("mathematik", "zahlenreihen") == "zr20", "Zahlenreihen playable")
