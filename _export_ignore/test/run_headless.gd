extends SceneTree
## Headless entry for util_r's suites, exiting with a CI code.
##     godot --headless --path . --script res://addons/_lib/util_r/_export_ignore/test/run_headless.gd

const TestRunner = preload("res://addons/_lib/util_r/src/test/test_runner.gd")


# Deferred: root enters the tree only after _initialize returns, and suites that add nodes need it
# there. Suites may also await frames, which needs this tree to be the main loop.
func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var report = await TestRunner.run_files(TestRunner.find_suites("res://addons/_lib/util_r/_export_ignore/test"))
	for s in report.suites:
		print("[%s] %s" % ["PASS" if s.passed else "FAIL", s.path])
		for line in s.output:
			print("\t" + str(line))
	quit(0 if report.failed == 0 and report.invalid.is_empty() else 1)
