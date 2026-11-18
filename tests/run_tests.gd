## Headless test runner. Exit code 0 = all green (CI gate).
##
##   godot --headless --path . -s tests/run_tests.gd
##
## Runs every tests/unit/test_*.gd; each test_* method is one case.
## TEST_FILTER=hero_combat,fx runs only files whose name contains one of those.
extends SceneTree

const TEST_DIR := "res://tests/unit"


func _init() -> void:
	# Defer so autoloads/root are ready before tests instantiate scenes.
	_run.call_deferred()


func _run() -> void:
	root.get_node(^"Fx").sfx_enabled = false
	root.get_node(^"SaveSystem").enabled = false  # never touch the player's save
	var total := 0
	var failed: PackedStringArray = []
	var files := DirAccess.get_files_at(TEST_DIR)
	files.sort()
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var only := OS.get_environment("TEST_FILTER")
		if only != "" and not Array(only.split(",")).any(func(part: String) -> bool: return part in file):
			continue
		var suite: Object = load(TEST_DIR.path_join(file)).new()
		suite.tree = self
		for method in suite.get_method_list():
			var test_name: String = method.name
			if not test_name.begins_with("test_"):
				continue
			total += 1
			suite.current_test = "%s::%s" % [file.get_basename(), test_name]
			var before: int = suite.failures.size()
			await suite.call(test_name)
			var ok: bool = suite.failures.size() == before
			print("  %s %s" % ["PASS" if ok else "FAIL", suite.current_test])
		failed.append_array(suite.failures)
	print("")
	for failure in failed:
		printerr("FAILED ", failure)
	print("%d tests, %d assertion failures" % [total, failed.size()])
	# Let in-flight tweens/particles end so exit is leak-free (clean CI logs).
	for i in 3:
		await process_frame
	quit(0 if failed.is_empty() and total > 0 else 1)
