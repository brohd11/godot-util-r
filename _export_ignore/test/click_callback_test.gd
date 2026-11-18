extends RefCounted
## ClickCallback: slot validation, the input-to-slot mapping, and set_node's built-in wiring.

const ClickCallback = preload("res://addons/_lib/util_r/src/input/click_callback.gd")
const State = ClickCallback.State


static func run_tests() -> Dictionary:
	var failures:Array[String] = []
	_test_assignment(failures)
	_test_fire(failures)
	_test_handle_input(failures)
	_test_tree(failures)
	_test_item_list(failures)
	_test_control(failures)
	_test_set_node_errors(failures)
	return {"result": failures.size(), "output": failures}


static func _test_assignment(failures:Array[String]) -> void:
	var clicks = ClickCallback.new(2)
	clicks.left_click_pressed = func(): pass
	_expect(failures, "a 0-arg callable is accepted", clicks.has_slot(State.LMB_PRESSED))
	clicks.right_click_pressed = func(_a, _b): pass
	_expect(failures, "an arg_count callable is accepted", clicks.has_slot(State.RMB_PRESSED))
	clicks.middle_click_pressed = func(_a): pass
	_expect(failures, "a near-miss callable is refused", not clicks.has_slot(State.MMB_PRESSED))
	var kept = clicks.right_click_pressed
	clicks.right_click_pressed = func(_a, _b, _c): pass
	_expect(failures, "a refused callable keeps the old one", clicks.right_click_pressed == kept)
	clicks.left_click_double = (func(_a, _b, _c): pass).bind("bound")
	_expect(failures, "a bound callable is counted after its binds", clicks.has_slot(State.LMB_DOUBLE_CLICK))
	clicks.left_click_pressed = Callable()
	_expect(failures, "an empty callable clears the slot", not clicks.has_slot(State.LMB_PRESSED))


static func _test_fire(failures:Array[String]) -> void:
	var got = []
	var clicks = ClickCallback.new()
	_expect(failures, "an unset slot is not handled", not clicks.fire(State.LMB_PRESSED, ["x"]))
	clicks.left_click_pressed = func(path): got.append(path)
	clicks.right_click_pressed = func(): got.append("none")
	_expect(failures, "a set slot is handled", clicks.fire(State.LMB_PRESSED, ["a"]))
	clicks.fire(State.RMB_PRESSED, ["b"])
	_expect(failures, "args reach the callback, a 0-arg one gets none, got %s" % [got], got == ["a", "none"])
	_expect(failures, "wheel has no slot", not clicks.fire(State.WHEEL_UP, ["c"]))

	var relay = Relay.new()
	relay.relayed.connect(func(path): got.append("relayed:" + path))
	clicks.left_click_double = relay.relayed.emit
	clicks.fire(State.LMB_DOUBLE_CLICK, ["e"])
	_expect(failures, "Signal.emit reports 0 args but still gets them, got %s" % [got], got.back() == "relayed:e")


static func _test_handle_input(failures:Array[String]) -> void:
	var got = []
	var clicks = ClickCallback.new()
	for slot in ClickCallback.SLOT_OF.values():
		clicks.set(slot, func(tag): got.append("%s:%s" % [slot, tag]))
	for button in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		clicks.handle_input(_mouse(button, true, false), ["p"])
		clicks.handle_input(_mouse(button, false, false), ["r"])
		clicks.handle_input(_mouse(button, true, true), ["d"])
	var expected = []
	for side in ["left", "right", "middle"]:
		expected.append_array(["%s_click_pressed:p" % side, "%s_click_released:r" % side, "%s_click_double:d" % side])
	_expect(failures, "press/release/double route per button, got %s" % [got], got == expected)
	_expect(failures, "wheel is not handled", not clicks.handle_input(_mouse(MOUSE_BUTTON_WHEEL_UP, true, false)))
	_expect(failures, "motion is not handled", not clicks.handle_input(InputEventMouseMotion.new()))


static func _test_tree(failures:Array[String]) -> void:
	var tree = Tree.new()
	var root = tree.create_item()
	var item = tree.create_item(root)
	item.set_metadata(0, "res://a.gd")
	var got = []
	var clicks = ClickCallback.new()
	clicks.resolve = func(it:TreeItem): return it.get_metadata(0) if it != null else ""
	clicks.left_click_double = func(path): got.append("double:" + path)
	clicks.set_node(tree)
	_expect(failures, "set_node turns on right-click select", tree.allow_rmb_select)
	tree.set_selected(item, 0)
	tree.item_activated.emit()
	_expect(failures, "item_activated fires left_click_double with the resolved payload, got %s" % [got], got == ["double:res://a.gd"])

	var other = Tree.new()
	clicks.set_node(other)
	got.clear()
	tree.item_activated.emit()
	_expect(failures, "set_node on another node disconnects the first", got.is_empty())
	tree.free()
	other.free()


static func _test_item_list(failures:Array[String]) -> void:
	var list = ItemList.new()
	var got = []
	var clicks = ClickCallback.new()
	clicks.right_click_pressed = func(i): got.append("right:%d" % i)
	clicks.left_click_double = func(i): got.append("double:%d" % i)
	clicks.set_node(list)
	list.item_clicked.emit(2, Vector2.ZERO, MOUSE_BUTTON_RIGHT)
	list.item_activated.emit(3)
	_expect(failures, "ItemList routes item_clicked and item_activated, got %s" % [got], got == ["right:2", "double:3"])
	list.free()


static func _test_control(failures:Array[String]) -> void:
	var control = Control.new()
	control.name = "C"
	var got = []
	var clicks = ClickCallback.new()
	clicks.resolve = func(c:Control): return c.name
	clicks.middle_click_released = func(n): got.append(n)
	clicks.set_node(control)
	control.gui_input.emit(_mouse(MOUSE_BUTTON_MIDDLE, false, false))
	control.gui_input.emit(_mouse(MOUSE_BUTTON_LEFT, true, false))
	_expect(failures, "a Control's gui_input routes through the resolved payload, got %s" % [got], got == [&"C"])
	clicks.clear_node()
	control.gui_input.emit(_mouse(MOUSE_BUTTON_MIDDLE, false, false))
	_expect(failures, "clear_node disconnects", got.size() == 1)
	control.free()


static func _test_set_node_errors(failures:Array[String]) -> void:
	var node = Node.new()
	var clicks = ClickCallback.new()
	clicks.set_node(node) # push_error expected: no built-in wiring for a plain Node
	_expect(failures, "an unsupported node is not wired", clicks._node == null)
	var control = Control.new()
	var two = ClickCallback.new(2)
	two.set_node(control) # push_error expected: built-in wiring passes one arg
	_expect(failures, "set_node refuses arg_count != 1", two._node == null and control.gui_input.get_connections().is_empty())
	node.free()
	control.free()


class Relay:
	signal relayed(path:String)


static func _mouse(button:int, pressed:bool, double:bool) -> InputEventMouseButton:
	var event = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.double_click = double
	return event


static func _expect(failures:Array[String], what:String, ok:bool) -> void:
	if not ok:
		failures.append(what)
