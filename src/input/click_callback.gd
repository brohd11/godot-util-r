#! namespace UtilR.Inputs class ClickCallback
extends RefCounted
## Callable slots for mouse clicks, so a host assigns actions instead of relaying signals.
## The widget owns the instance: it wires it (set_node, or handle_input/fire from its own handlers)
## and documents what the callbacks get, e.g. `## Callbacks get (path:String).` The host only
## assigns slots. Each slot takes a 0-arg callable or one taking exactly arg_count args.
## set_node: Tree / ItemList fire *_pressed and left_click_double only; other Controls fire all.
## A double-click fires *_pressed for its first click before *_double, as Godot sends both.

const ClickState = preload("res://addons/_lib/util_r/src/input/click_state.gd")
const State = ClickState.State

const SLOT_OF = {
	State.LMB_PRESSED: &"left_click_pressed", State.LMB_RELEASED: &"left_click_released",
	State.LMB_DOUBLE_CLICK: &"left_click_double",
	State.RMB_PRESSED: &"right_click_pressed", State.RMB_RELEASED: &"right_click_released",
	State.RMB_DOUBLE_CLICK: &"right_click_double",
	State.MMB_PRESSED: &"middle_click_pressed", State.MMB_RELEASED: &"middle_click_released",
	State.MMB_DOUBLE_CLICK: &"middle_click_double",
}
const PRESSED_OF_BUTTON = {
	MOUSE_BUTTON_LEFT: State.LMB_PRESSED, MOUSE_BUTTON_RIGHT: State.RMB_PRESSED,
	MOUSE_BUTTON_MIDDLE: State.MMB_PRESSED,
}

var left_click_pressed:Callable:
	set(value): left_click_pressed = _checked(&"left_click_pressed", value, left_click_pressed)
var left_click_released:Callable:
	set(value): left_click_released = _checked(&"left_click_released", value, left_click_released)
var left_click_double:Callable:
	set(value): left_click_double = _checked(&"left_click_double", value, left_click_double)
var right_click_pressed:Callable:
	set(value): right_click_pressed = _checked(&"right_click_pressed", value, right_click_pressed)
var right_click_released:Callable:
	set(value): right_click_released = _checked(&"right_click_released", value, right_click_released)
var right_click_double:Callable:
	set(value): right_click_double = _checked(&"right_click_double", value, right_click_double)
var middle_click_pressed:Callable:
	set(value): middle_click_pressed = _checked(&"middle_click_pressed", value, middle_click_pressed)
var middle_click_released:Callable:
	set(value): middle_click_released = _checked(&"middle_click_released", value, middle_click_released)
var middle_click_double:Callable:
	set(value): middle_click_double = _checked(&"middle_click_double", value, middle_click_double)

## Widget-only: maps what set_node's wiring clicked (TreeItem, ItemList index, the Control) to
## the documented payload. Unset passes that raw value through.
var resolve:Callable

var arg_count:int
var _node:Node
var _connections:Array = [] # [Signal, Callable]


func _init(_arg_count:int = 1) -> void:
	arg_count = _arg_count


func has_slot(state:State) -> bool:
	return SLOT_OF.has(state) and not (get(SLOT_OF[state]) as Callable).is_null()


## Fires the slot for `state`. True when one was set, i.e. the click was handled.
func fire(state:State, args:Array = []) -> bool:
	if not has_slot(state):
		return false
	var slot:Callable = get(SLOT_OF[state])
	if not slot.is_valid():
		return false # its object was freed
	if slot.get_argument_count() == 0 and not _is_emit(slot):
		slot.call()
	elif args.size() != arg_count:
		push_error("ClickCallback: %s got %d args, expected %d" % [SLOT_OF[state], args.size(), arg_count])
	else:
		slot.callv(args)
	return true


## The manual path for a `_gui_input`. `accept_on` accepts the event before the slot runs: the
## handler may free the node (a graph rebuilt on double-click), and accepting after would crash.
func handle_input(event:InputEvent, args:Array = [], accept_on:Control = null) -> bool:
	var state = ClickState.get_click_state(event)
	if not has_slot(state):
		return false
	if accept_on != null:
		accept_on.accept_event()
	return fire(state, args)


## Connects to `node`'s own click signals, replacing any previous node. The widget keeps this
## instance alive; the connections don't.
func set_node(node:Node) -> void:
	clear_node()
	if arg_count != 1:
		push_error("ClickCallback: set_node passes one arg, but arg_count is %d" % arg_count)
		return
	if node is Tree:
		node.allow_rmb_select = true
		_connect(node.item_mouse_selected, _on_tree_mouse_selected.bind(node))
		_connect(node.item_activated, _on_tree_activated.bind(node))
	elif node is ItemList:
		_connect(node.item_clicked, _on_item_list_clicked)
		_connect(node.item_activated, _on_item_list_activated)
	elif node is Control:
		_connect(node.gui_input, _on_control_input.bind(node))
	else:
		push_error("ClickCallback: no built-in wiring for %s, call handle_input/fire from it instead" % node.get_class())
		return
	_node = node


func clear_node() -> void:
	if is_instance_valid(_node):
		for pair in _connections:
			if pair[0].is_connected(pair[1]):
				pair[0].disconnect(pair[1])
	_connections.clear()
	_node = null


func _connect(sig:Signal, callable:Callable) -> void:
	sig.connect(callable)
	_connections.append([sig, callable])


func _payload(raw) -> Array:
	return [resolve.call(raw) if resolve.is_valid() else raw]


func _on_tree_mouse_selected(pos:Vector2, button:int, tree:Tree) -> void:
	if PRESSED_OF_BUTTON.has(button):
		fire(PRESSED_OF_BUTTON[button], _payload(tree.get_item_at_position(pos)))


func _on_tree_activated(tree:Tree) -> void:
	fire(State.LMB_DOUBLE_CLICK, _payload(tree.get_selected()))


func _on_item_list_clicked(index:int, _pos:Vector2, button:int) -> void:
	if PRESSED_OF_BUTTON.has(button):
		fire(PRESSED_OF_BUTTON[button], _payload(index))


func _on_item_list_activated(index:int) -> void:
	fire(State.LMB_DOUBLE_CLICK, _payload(index))


func _on_control_input(event:InputEvent, control:Control) -> void:
	if has_slot(ClickState.get_click_state(event)):
		handle_input(event, _payload(control), control)


# Refuses a callable that takes neither 0 args nor exactly arg_count, keeping the old one, so a
# near-miss fails on assignment rather than on the first click.
func _checked(slot:StringName, value:Callable, old:Callable) -> Callable:
	if value.is_null():
		return value
	var count = value.get_argument_count()
	if count == 0 or count == arg_count:
		return value # includes Signal.emit, which reports 0 but forwards the args
	push_error("ClickCallback: %s takes 0 or %d args, got a callable taking %d" % [slot, arg_count, count])
	return old


# Signal.emit is vararg and reports 0 args; forwarding to a signal means passing them on.
static func _is_emit(callable:Callable) -> bool:
	return callable.is_custom() and callable.get_method() == &"emit"
