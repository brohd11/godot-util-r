extends RefCounted
## Options shown by a Placer: an escaped slash stays in its item, a disabled item is greyed out.

const Placer = preload("res://addons/_lib/util_r/src/node/popup/placer.gd")
const Options = preload("res://addons/_lib/util_r/src/node/popup/options.gd")
const Params = preload("res://addons/_lib/util_r/src/node/popup/path_helper.gd").ParamKeys


static func run_tests() -> Dictionary:
	var failures:Array[String] = []
	var root:Window = Engine.get_main_loop().root
	var placer = Placer.new()
	root.add_child(placer)
	var chosen := []

	var options = Options.new()
	options.add_option("Recent/" + Options.escape("qwen/qwen3-8b"), func(): chosen.append("qwen"))
	options.add_option("Recent/" + Options.escape("a/b/"), func(): chosen.append("ab"))
	options.add_option("Remove", func(): chosen.append("remove"))[Params.DISABLED] = true
	var popup:PopupMenu = placer.display_popup(options)

	_expect(failures, "two top items, got %s" % [popup.item_count], popup.item_count == 2)
	var recent:PopupMenu = popup.get_item_submenu_node(0)
	var texts = []
	if recent != null:
		for i in range(recent.item_count):
			texts.append(recent.get_item_text(i))
	_expect(failures, "a slash stays in its item, got %s" % [texts], texts == ["qwen/qwen3-8b", "a/b/"])
	if recent != null:
		recent.id_pressed.emit(recent.get_item_id(0))
	_expect(failures, "the escaped item runs its callable, got %s" % [chosen], chosen == ["qwen"])
	_expect(failures, "a disabled item", popup.item_count == 2 and popup.is_item_disabled(1) and not popup.is_item_disabled(0))
	_expect(failures, "split_path undoes join_path", Placer.PathHelper.split_path(Placer.PathHelper.join_path("A", "x/y")) == PackedStringArray(["A", "x/y"]))

	placer.free()
	return {"result": failures.size(), "output": failures}


static func _expect(failures:Array[String], what:String, ok:bool) -> void:
	if not ok:
		failures.append(what)
