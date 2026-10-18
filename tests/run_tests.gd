extends SceneTree
## Headless test runner: runs every `test_*` method of every tests/test_*.gd script.
## A test fails on a failed check or on any engine/script error while it runs.
## Exits with code 1 if any test fails. Usage: tests/run.sh [filter]

const TEST_DIR := "res://tests/"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var filter: String = args[0] if args.size() > 0 else ""
	var passed := 0
	var failed := 0
	var errors := ErrorCatcher.new()
	OS.add_logger(errors)

	for file in DirAccess.get_files_at(TEST_DIR):
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script: GDScript = load(TEST_DIR + file)
		for method in script.get_script_method_list():
			var test_name: String = method.name
			var full_name := "%s::%s" % [file.get_basename(), test_name]
			if not test_name.begins_with("test_") or (filter != "" and not full_name.contains(filter)):
				continue
			errors.take_errors()
			var test: GameTest = script.new()
			test.tree = self
			await test.call(test_name)
			test.cleanup()
			await physics_frame
			for error in errors.take_errors():
				test.failures.append("engine error: " + error)
			if test.failures.is_empty():
				passed += 1
				print("  PASS  ", full_name)
			else:
				failed += 1
				print("  FAIL  ", full_name)
				for failure in test.failures:
					print("        - ", failure)

	OS.remove_logger(errors)
	if errors.ignored_count > 0:
		print("\n(note: %d known engine warning(s) ignored, see ErrorCatcher.IGNORED)" % errors.ignored_count)
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 or passed == 0 else 0)
