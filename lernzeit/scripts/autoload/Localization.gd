extends Node
## Two interface languages: Deutsch (default) and Russian.
## All UI strings are looked up by key (localization/de.json, ru.json).
## Controls that show a key as text are translated automatically by Godot;
## formatted strings use Localization.t(key, {"n": 3}).

signal language_changed(lang: String)

const LANGUAGES: Array[String] = ["de", "ru"]
const FILES := {"de": "res://localization/de.json", "ru": "res://localization/ru.json"}

var current := "de"


func _ready() -> void:
	for lang in LANGUAGES:
		var tr_res := Translation.new()
		tr_res.locale = lang
		var data = JSON.parse_string(FileAccess.get_file_as_string(FILES[lang]))
		if data is Dictionary:
			for key in data:
				tr_res.add_message(key, str(data[key]))
		else:
			push_error("Localization: cannot parse " + FILES[lang])
		TranslationServer.add_translation(tr_res)
	_apply(SettingsRepository.get_value("language"))
	SettingsRepository.setting_changed.connect(_on_setting_changed)


func _on_setting_changed(key: String, value: Variant) -> void:
	if key == "language":
		_apply(value)


func _apply(lang: String) -> void:
	if not lang in LANGUAGES:
		lang = "de"
	current = lang
	TranslationServer.set_locale(lang)
	language_changed.emit(lang)


func set_language(lang: String) -> void:
	SettingsRepository.set_value("language", lang)


func t(key: String, args: Dictionary = {}) -> String:
	var s := String(TranslationServer.translate(key))
	return s.format(args) if not args.is_empty() else s


func keys_for(lang: String) -> Array:
	var data = JSON.parse_string(FileAccess.get_file_as_string(FILES[lang]))
	return (data as Dictionary).keys() if data is Dictionary else []


## Text in the parents' "Hilfesprache" (tips after mistakes), independent of the menu language.
## Language of the parents' help texts (tips), "de" or "ru".
func help_language() -> String:
	return str(SettingsRepository.get_parent_settings().get("help_language", current))


func help(key: String, args: Dictionary = {}) -> String:
	var lang: String = SettingsRepository.get_parent_settings().get("help_language", current)
	var tro := TranslationServer.get_translation_object(lang)
	var s := String(tro.get_message(key)) if tro and tro.locale == lang else ""
	if s == "":
		s = String(TranslationServer.translate(key))
	return s.format(args) if not args.is_empty() else s
