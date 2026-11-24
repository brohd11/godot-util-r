extends RefCounted
## TestFrameworks: GUT vs GdUnit4 told apart from text alone, custom bases followed, and native
## `*_test.gd` suites kept separate. Fixtures go to user:// so no repo file needs a framework.

const TestFrameworks = preload("res://addons/_lib/util_r/src/test/test_frameworks.gd")
const ROOT = "user://util_r_test_frameworks"

const GUT = TestFrameworks.GUT
const GDUNIT4 = TestFrameworks.GDUNIT4

## name -> [source, expected framework]
const CASES = {
	"test_gut.gd": ["extends GutTest\n", GUT],
	"gut_path.gd": ['extends "res://addons/gut/test.gd"\n', GUT],
	"unit.gd": ["class_name Unit extends GdUnitTestSuite\n", GDUNIT4],
	"gdunit_path.gd": ["extends 'res://addons/gdUnit4/src/GdUnitTestSuite.gd'\n", GDUNIT4],
	"labels_test.gd": ["extends GdUnitTestSuite\n", GDUNIT4],
	"custom_base.gd": ["class_name SharedGut extends GutTest\n", GUT],
	"child.gd": ["extends SharedGut\n", GUT],
	"relative.gd": ['extends "./unit.gd"\n', GDUNIT4],
	"native_test.gd": ["extends RefCounted\nstatic func run_tests(): return {}\n", ""],
	"plain.gd": ["extends RefCounted\n", ""],
	"nested.gd": ["extends RefCounted\nclass Inner:\n\textends GutTest\n", ""],
	"comment.gd": ["# extends GutTest\nextends RefCounted # GdUnitTestSuite\n", ""],
	"string.gd": ['const TEXT = """\nextends GutTest\n"""\n', ""],
	"cycle_a.gd": ['extends "cycle_b.gd"\n', ""],
	"cycle_b.gd": ['extends "cycle_a.gd"\n', ""],
}


static func run_tests() -> Dictionary:
	var failures:Array[String] = []
	var paths = []
	for name:String in CASES:
		paths.append(_write(name, CASES[name][0]))
	var classifier = TestFrameworks.new()
	classifier.index_classes(paths)
	for name:String in CASES:
		var got = classifier.framework(ROOT.path_join(name))
		_expect(failures, "%s -> '%s' (got '%s')" % [name, CASES[name][1], got], got == CASES[name][1])

	var split = classifier.split(paths)
	var names = func(kind): return split[kind].map(func(p): return p.get_file())
	_expect(failures, "split native: %s" % [names.call(TestFrameworks.NATIVE)], names.call(TestFrameworks.NATIVE) == ["native_test.gd"])
	_expect(failures, "split gut: %s" % [names.call(GUT)], names.call(GUT) == ["test_gut.gd", "gut_path.gd", "custom_base.gd", "child.gd"])
	_expect(failures, "split gdunit4 takes a *_test.gd: %s" % [names.call(GDUNIT4)], names.call(GDUNIT4) == ["unit.gd", "gdunit_path.gd", "labels_test.gd", "relative.gd"])

	# A base known only as a project global class.
	var global = TestFrameworks.new()
	global.class_paths["SharedGut"] = ROOT.path_join("custom_base.gd")
	_expect(failures, "preset class_paths resolve a custom base", global.framework(ROOT.path_join("child.gd")) == GUT)

	for path:String in paths:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ROOT))
	var output:Array[String] = ["test_frameworks: %d failed" % failures.size()]
	output.append_array(failures)
	return {"result": failures.size(), "output": output}


static func _write(name:String, text:String) -> String:
	var path = ROOT.path_join(name)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	return path


static func _expect(failures:Array[String], label:String, ok:bool) -> void:
	if not ok:
		failures.append("FAIL " + label)
