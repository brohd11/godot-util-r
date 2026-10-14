#! namespace UtilR.Signals class USignal

const PLUGIN_EXPORTED = false
const PRINT_ERR = not PLUGIN_EXPORTED

static func connect_signal(callable:Callable, _signal:Signal):
	if not _signal.is_connected(callable):
		_signal.connect(callable)

static func disconnect_signal(callable:Callable, _signal:Signal):
	if _signal.is_connected(callable):
		_signal.disconnect(callable)

static func get_signal_callable(object:Object, signal_name:StringName, callable_name:StringName):
	for data in object.get_signal_connection_list(signal_name):
		var callable = data.get("callable") as Callable
		if callable and callable.get_method() == callable_name:
			return callable


static func disconnect_signals_of_name(object:Object, signal_name:String) -> Array[Dictionary]:
	var signal_list:Array[Dictionary] = object.get_signal_connection_list(signal_name)
	for data:Dictionary in signal_list:
		var callable:Callable = data.get("callable")
		object.text_changed.disconnect(callable)
	return signal_list

static func connect_signals_from_list(object:Object, signal_list:Array[Dictionary]) -> void:
	for data:Dictionary in signal_list:
		var callable:Callable = data.get("callable")
		var flags:int = data.get("flags")
		if not object.text_changed.is_connected(callable):
			object.text_changed.connect(callable, flags)
		elif PRINT_ERR:
			printerr("SIGNAL ALREADY CONNECTED::",callable.get_object(), "::", callable.get_method())
