class_name ProgressRecord
extends RefCounted
## One finished exercise block. Prepared for future versions – v0.1 has no
## exercises, so no records are ever created by the app itself.

var subject_id: String = ""
var topic_id: String = ""
var timestamp: int = 0            ## unix time (seconds)
var correct_count: int = 0
var total_count: int = 0
var duration_seconds: int = 0
var exercise_version: String = ""


static func create(p_subject: String, p_topic: String, p_correct: int, p_total: int,
		p_duration: int, p_version: String, p_timestamp: int = -1) -> ProgressRecord:
	var r := ProgressRecord.new()
	r.subject_id = p_subject
	r.topic_id = p_topic
	r.correct_count = maxi(0, p_correct)
	r.total_count = maxi(r.correct_count, p_total)
	r.duration_seconds = maxi(0, p_duration)
	r.exercise_version = p_version
	r.timestamp = p_timestamp if p_timestamp >= 0 else int(Time.get_unix_time_from_system())
	return r


func to_dict() -> Dictionary:
	return {
		"subject_id": subject_id, "topic_id": topic_id, "timestamp": timestamp,
		"correct_count": correct_count, "total_count": total_count,
		"duration_seconds": duration_seconds, "exercise_version": exercise_version,
	}


static func from_dict(d: Dictionary) -> ProgressRecord:
	if not (d.get("subject_id") is String) or not (d.get("topic_id") is String):
		return null
	var r := ProgressRecord.new()
	r.subject_id = d["subject_id"]
	r.topic_id = d["topic_id"]
	r.timestamp = int(d.get("timestamp", 0))
	r.correct_count = maxi(0, int(d.get("correct_count", 0)))
	r.total_count = maxi(r.correct_count, int(d.get("total_count", 0)))
	r.duration_seconds = maxi(0, int(d.get("duration_seconds", 0)))
	r.exercise_version = str(d.get("exercise_version", ""))
	return r
