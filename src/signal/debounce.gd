#! namespace UtilR.Signals class Debounce
extends Node

const NODE_NAME = "Debounce"

static func get_instance() -> Node:
	var root = Engine.get_main_loop().root
	var ins = root.get_node_or_null(NODE_NAME)
	if not is_instance_valid(ins):
		ins = new()
		root.add_child(ins)
		ins.name = NODE_NAME
	return ins


enum DebounceType {
	FRAME,
	TIMER,
	DEFER,
}

var _current_debounces:= {}
var debounce_timer:Timer

func _ready() -> void:
	debounce_timer = Timer.new()
	debounce_timer.one_shot = true
	add_child(debounce_timer)

static func debouncing(key:Variant):
	return get_instance()._current_debounces.has(key)

static func start_debounce(key:Variant, type:DebounceType=DebounceType.FRAME, time:=1) -> bool:
	var ins = get_instance()
	if ins._current_debounces.has(key):
		return false
	
	if type == DebounceType.DEFER:
		ins._current_debounces[key] = true
		ins._on_defer.call_deferred(key)
	elif type == DebounceType.FRAME:
		ins._current_debounces[key] = true
		ins._on_frame(key)
	elif type == DebounceType.TIMER:
		var timer = ins.get_timer()
		timer.wait_time = time
		if not timer.timeout.is_connected(ins._on_timer_timeout):
			timer.timeout.connect(ins._on_timer_timeout.bind(key))
		timer.start(time)
		ins._current_debounces[key] = timer
	
	return true


func _on_frame(key:Variant):
	await get_tree().process_frame
	_current_debounces.erase(key)

func _on_defer(key:Variant):
	_current_debounces.erase(key)

func _on_timer_timeout(key:Variant):
	var timer = _current_debounces[key]
	if timer != debounce_timer:
		timer.queue_free()
	_current_debounces.erase(key)

func get_timer() -> Timer:
	if debounce_timer.is_stopped():
		return debounce_timer
	var timer:= Timer.new()
	timer.one_shot = true
	add_child(timer)
	return timer
