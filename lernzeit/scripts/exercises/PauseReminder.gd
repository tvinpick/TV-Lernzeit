class_name PauseReminder
extends RefCounted
## Friendly break reminder: once the practice time of today reaches the
## "Sitzungsdauer" from the parents area (15/30/45 min), the results screen
## suggests a pause – once per day, never forced.

static func local_day(ts: int) -> int:
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	return int(floor((ts + bias * 60) / 86400.0))


## Finished exercises today (daily goal stars on Home).
static func done_today() -> int:
	var today := local_day(int(Time.get_unix_time_from_system()))
	var n := 0
	for r in ProgressRepository.get_records():
		if r.complete and local_day(r.timestamp) == today:
			n += 1
	return n


## Parents chose "stop" and today's practice time reached the session length.
static func locked() -> bool:
	var p := SettingsRepository.get_parent_settings()
	return p.get("after_limit", "remind") == "stop" and today_seconds() >= int(p["session_minutes"]) * 60


static func today_seconds() -> int:
	var today := local_day(int(Time.get_unix_time_from_system()))
	var sum := 0
	for r in ProgressRepository.get_records():
		if local_day(r.timestamp) == today:
			sum += r.duration_seconds
	return sum


static func due() -> bool:
	var minutes: int = SettingsRepository.get_parent_settings()["session_minutes"]
	var today := local_day(int(Time.get_unix_time_from_system()))
	return int(SettingsRepository.get_value("pause_day")) != today and today_seconds() >= minutes * 60


static func maybe_show(screen: Node, main: Node, delay: float) -> void:
	if not due():
		return
	SettingsRepository.set_value("pause_day", local_day(int(Time.get_unix_time_from_system())))   # once a day, also after a restart
	await screen.get_tree().create_timer(delay).timeout
	if not is_instance_valid(screen) or not screen.is_inside_tree():
		return
	Sfx.play("pause")
	if Localization.current == "de":
		Voice.say(["pause"])
	var d := ConfirmDialog.make("pause_title",
		Localization.t("pause_message", {"n": int(today_seconds() / 60)}), "pause_home", "green", "pause_continue")
	d.image = preload("res://assets/mascot/owl/Mascot_Owl_Sleep.png")
	d.confirmed.connect(func(): main.pop_to_home())
	main.show_dialog(d)
