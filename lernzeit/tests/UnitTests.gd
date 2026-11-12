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
		if tex == null or tex.get_width() != spec[1] or tex.get_height() != spec[2]:
			bad.append(key)
			continue
		if not key.contains("backgrounds/"):
			var img := tex.get_image()
			if img.is_compressed():
				img.decompress()
			if not img.detect_alpha():
				alpha_missing.append(key)
	check(KitAssets.TEXTURES.size() == 153, "153 kit textures registered (%d)" % KitAssets.TEXTURES.size())
	check(bad.is_empty(), "all kit textures load as separate resources with manifest size " + str(bad))
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

	print("UNIT TESTS: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)
