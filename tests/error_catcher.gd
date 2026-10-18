class_name ErrorCatcher
extends Logger
## Collects engine and script errors so the runner can fail a test that crashed midway
## (a script error aborts the test function without recording a failed check).

## Known engine noise that is reported but does not fail a test.
## Jolt sometimes runs out of job slots when --fixed-fps runs frames back to back; it waits and
## carries on, so results are unaffected. Seen ~1 in 5 suite runs on the M1.
const IGNORED: PackedStringArray = ["Jolt Physics job system exceeded the maximum number of jobs"]

var ignored_count: int = 0

var _mutex := Mutex.new()
var _errors: PackedStringArray = []


func take_errors() -> PackedStringArray:
	_mutex.lock()
	var errors := _errors
	_errors = PackedStringArray()
	_mutex.unlock()
	return errors


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	for pattern in IGNORED:
		if rationale.contains(pattern):
			_mutex.lock()
			ignored_count += 1
			_mutex.unlock()
			return
	_mutex.lock()
	_errors.append("%s (%s:%d %s)" % [rationale if rationale != "" else code, file.get_file(), line, function])
	_mutex.unlock()


func _log_message(_message: String, _error: bool) -> void:
	pass
