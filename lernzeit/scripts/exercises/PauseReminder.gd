class_name PauseReminder
extends RefCounted
## Friendly break reminder: once the practice time of today reaches the
## "Sitzungsdauer" from the parents area (15/30/45 min), the results screen
## suggests a pause – once per day, never forced.

static var _shown_day := -1


static func local_day(ts: int) -> int:
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	return int(floor((ts + bias * 60) / 86400.0))


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
	return _shown_day != today and today_seconds() >= minutes * 60


static func maybe_show(screen: Node, main: Node, delay: float) -> void:
	if not due():
		return
	_shown_day = local_day(int(Time.get_unix_time_from_system()))
	await screen.get_tree().create_timer(delay).timeout
	if not is_instance_valid(screen) or not screen.is_inside_tree():
		return
	Sfx.play("pause")
	var d := ConfirmDialog.make("pause_title",
		Localization.t("pause_message", {"n": int(today_seconds() / 60)}), "pause_home", "green", "pause_continue")
	d.confirmed.connect(func(): main.pop_to_home())
	main.show_dialog(d)
