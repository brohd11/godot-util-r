#! namespace UtilR.Signals class URSignal


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
