class_name Locales
## Languages the game ships with and the player's choice (saved in SaveManager).
## The first launch follows the system language until the player picks one on the start menu.

## Locale code -> name shown in that language (never translated).
const SUPPORTED := {"vi": "Tiếng Việt", "en": "English"}


static func system_default() -> String:
	return "vi" if OS.get_locale_language() == "vi" else "en"


static func has_chosen() -> bool:
	return SaveManager.get_setting("language", "") != ""


static func current() -> String:
	var code: String = SaveManager.get_setting("language", "")
	return code if SUPPORTED.has(code) else system_default()


static func apply_saved() -> void:
	TranslationServer.set_locale(current())


static func choose(code: String) -> void:
	SaveManager.set_setting("language", code)
	TranslationServer.set_locale(code)
