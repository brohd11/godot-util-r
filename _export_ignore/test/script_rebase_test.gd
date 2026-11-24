extends RefCounted
## ScriptRebase puts a script onto a base chosen at runtime, and a relative preload in it still
## resolves against the original file.

const ScriptRebase = preload("res://addons/_lib/util_r/src/object/script_rebase.gd")

const DIR = "res://addons/_lib/util_r/_export_ignore/test/script_rebase/"


static func run_tests() -> Dictionary:
	var failures:Array[String] = []
	var base:Script = load(DIR + "base.gd")
	var path := DIR + "cmd/cmd.gd"

	var script := ScriptRebase.build(path, base)
	_expect(failures, "builds, errors: %s" % [ScriptRebase.last_errors], script != null)
	if script != null:
		_expect(failures, "extends the base", script.get_base_script() == base)
		_expect(failures, "keeps the file's path, got %s" % script.resource_path, script.resource_path == path)
		var inst = script.new()
		_expect(failures, "the relative preload resolves", inst.value() == 7)
		_expect(failures, "the base's members are inherited", inst.BASE == true)

	# Only relative paths change; the rewrite keeps the line count.
	var src := "const A = preload(\"../a.gd\")\nconst B = preload('./b.gd')\nconst C = preload(\"res://c.gd\")\n"
	var out := ScriptRebase._absolute_preloads(src, "res://x/y")
	_expect(failures, "rewrite, got %s" % out,
		out == "const A = preload(\"res://x/a.gd\")\nconst B = preload('res://x/y/b.gd')\nconst C = preload(\"res://c.gd\")\n")
	_expect(failures, "an absolute folder", ScriptRebase._absolute_preloads("preload(\"../a.gd\")", "/home/u/cli/cmd") == "preload(\"/home/u/cli/a.gd\")")
	return {"result": failures.size(), "output": failures}


static func _expect(failures:Array[String], what:String, ok:bool) -> void:
	if not ok:
		failures.append(what)
