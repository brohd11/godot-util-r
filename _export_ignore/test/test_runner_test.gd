extends RefCounted
## TestRunner: entry funcs found static or not, results normalised, bad suites fail without stopping.

const TestRunner = preload("res://addons/_lib/util_r/src/test/test_runner.gd")
const ROOT = "user://util_r_test_runner"

const SUITES = {
	"a_static_pass_test.gd": "extends RefCounted\nstatic func run_tests():\n\treturn {\"result\": 0, \"output\": [\"ok\"]}\n",
	"b_instance_fail_test.gd": "extends RefCounted\nfunc run():\n\treturn {\"success\": false, \"output\": [\"bad\"]}\n",
	"c_awaits_test.gd": "extends RefCounted\nstatic func run_test():\n\tawait Engine.get_main_loop().process_frame\n\treturn {\"result\": 0}\n",
	"d_counts_test.gd": "extends RefCounted\nstatic func run_tests():\n\treturn {\"result\": 2}\n",
	"e_no_entry_test.gd": "extends RefCounted\nstatic func helper():\n\tpass\n",
	"f_not_dict_test.gd": "extends RefCounted\nstatic func run_tests():\n\treturn 0\n",
	"sub/g_nested_test.gd": "extends RefCounted\nstatic func run_tests():\n\treturn {\"result\": 0}\n",
	"fixture.gd": "extends RefCounted\n",
}


static func run_tests() -> Dictionary:
	var failures:Array[String] = []
	var root = ProjectSettings.globalize_path(ROOT)
	for rel in SUITES:
		var path = root.path_join(rel)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var f = FileAccess.open(path, FileAccess.WRITE)
		f.store_string(SUITES[rel])
		f.close()

	var found = TestRunner.find_suites(root)
	_expect(failures, "recursive finds 7 suites, sorted: %s" % [found], found.size() == 7 and found[0].ends_with("a_static_pass_test.gd") and found[-1].ends_with("sub/g_nested_test.gd"))
	_expect(failures, "flat skips sub dirs", TestRunner.find_suites(root, false).size() == 6)

	var report = await TestRunner.run_files(found + [root.path_join("fixture.gd")])
	var by_name = {}
	for s in report.suites:
		by_name[s.path.get_file()] = s
	_expect(failures, "static pass", by_name.get("a_static_pass_test.gd", {}).get("passed") == true)
	_expect(failures, "output kept", by_name.get("a_static_pass_test.gd", {}).get("output") == ["ok"])
	_expect(failures, "instance success=false fails", by_name.get("b_instance_fail_test.gd", {}).get("passed") == false)
	_expect(failures, "awaited suite passes", by_name.get("c_awaits_test.gd", {}).get("passed") == true)
	_expect(failures, "failure count fails", by_name.get("d_counts_test.gd", {}).get("passed") == false)
	_expect(failures, "no entry is invalid, not run", report.invalid.size() == 1 and report.invalid[0].ends_with("e_no_entry_test.gd") and not by_name.has("e_no_entry_test.gd"))
	_expect(failures, "non-Dictionary result fails", by_name.get("f_not_dict_test.gd", {}).get("passed") == false)
	_expect(failures, "non-suites skipped", not by_name.has("fixture.gd"))
	_expect(failures, "failed count: %d" % report.failed, report.failed == 3)

	_remove(root)
	var output:Array[String] = ["test_runner: %d failed" % failures.size()]
	output.append_array(failures)
	return {"result": failures.size(), "output": output}


static func _expect(failures:Array[String], label:String, ok:bool) -> void:
	if not ok:
		failures.append("FAIL " + label)


static func _remove(dir:String) -> void:
	for d in DirAccess.get_directories_at(dir):
		_remove(dir.path_join(d))
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)
