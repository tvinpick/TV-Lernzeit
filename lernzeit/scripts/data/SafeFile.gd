class_name SafeFile
extends RefCounted
## Crash-safe file helpers: write to "<path>.tmp", keep the previous version as
## "<path>.bak", then move the new file into place. Readers fall back to .bak
## when the main file is missing or corrupt.

static func write_text(path: String, text: String) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SafeFile: cannot open %s (%s)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(text)
	f.flush()
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
		DirAccess.remove_absolute(path)
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:
		push_error("SafeFile: rename failed for %s (%s)" % [path, err])
		return false
	return true


static func read_text(path: String) -> String:
	for p in [path, path + ".bak"]:
		if FileAccess.file_exists(p):
			var t := FileAccess.get_file_as_string(p)
			if t != "":
				return t
	return ""


static func read_json_dict(path: String) -> Dictionary:
	for p in [path, path + ".bak"]:
		if not FileAccess.file_exists(p):
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(p))
		if parsed is Dictionary:
			return parsed
		push_warning("SafeFile: %s is corrupt, trying fallback" % p)
	return {}


static func save_config(cfg: ConfigFile, path: String) -> bool:
	return write_text(path, cfg.encode_to_text())


## Loads a ConfigFile; on a corrupt main file it falls back to the .bak copy.
## Returns an empty ConfigFile when nothing usable exists (caller applies defaults).
static func load_config(path: String) -> ConfigFile:
	for p in [path, path + ".bak"]:
		if not FileAccess.file_exists(p):
			continue
		var cfg := ConfigFile.new()
		if cfg.load(p) == OK:
			return cfg
		push_warning("SafeFile: %s is corrupt, trying fallback" % p)
	return ConfigFile.new()
