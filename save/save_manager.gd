class_name SaveManager
## Local save data (records, settings) in a versioned ConfigFile under user://.
## Static so menus, the match and the HUD share it without an autoload.

const VERSION := 1

## Tests point this somewhere else so they never touch the player's save.
static var path: String = "user://thanhtri_save.cfg"

static var _file: ConfigFile


static func best_distance() -> float:
	return _data().get_value("records", "best_distance", 0.0)


static func best_daily(date: String) -> float:
	return _data().get_value("daily", date, 0.0)


static func runs_played() -> int:
	return _data().get_value("records", "runs_played", 0)


static func get_setting(key: String, default: Variant) -> Variant:
	return _data().get_value("settings", key, default)


static func set_setting(key: String, value: Variant) -> void:
	_data().set_value("settings", key, value)
	_save()


## Records a finished run. Returns true if it beat the record for its mode
## (the overall best, or that day's best for a daily run).
static func record_run(distance: float, daily_date: String = "") -> bool:
	var data := _data()
	data.set_value("records", "runs_played", runs_played() + 1)
	var beaten := false
	if daily_date != "":
		beaten = distance > best_daily(daily_date)
		if beaten:
			data.set_value("daily", daily_date, distance)
	if distance > best_distance():
		data.set_value("records", "best_distance", distance)
		beaten = beaten or daily_date == ""
	_save()
	return beaten


## Forgets the cached file (tests switch `path` between runs).
static func reload() -> void:
	_file = null


static func _data() -> ConfigFile:
	if _file == null:
		_file = ConfigFile.new()
		if _file.load(path) != OK:
			_file = ConfigFile.new()
		_migrate(_file)
	return _file


# Version 1 is the first format; later versions add steps here, oldest first.
static func _migrate(file: ConfigFile) -> void:
	if file.get_value("meta", "version", 0) < VERSION:
		file.set_value("meta", "version", VERSION)


static func _save() -> void:
	var error := _data().save(path)
	if error != OK:
		push_warning("SaveManager: could not save to %s (error %d)" % [path, error])
