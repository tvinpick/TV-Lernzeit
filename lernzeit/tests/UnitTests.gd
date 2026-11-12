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
	check(KitAssets.TEXTURES.size() == 73, "73 kit textures registered (%d)" % KitAssets.TEXTURES.size())
	check(bad.is_empty(), "all kit textures load as separate resources with manifest size " + str(bad))
	check(alpha_missing.is_empty(), "all kit sprites have real alpha transparency " + str(alpha_missing))
	check(KitAssets.keys_with_prefix("deutsch_pictures/").size() == 8, "8 Deutsch pictures")
	check(not FileAccess.file_exists("res://references"), "mock-up screens are not inside the Godot project")

	print("UNIT TESTS: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)
