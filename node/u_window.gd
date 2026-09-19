#! namespace UtilR.Nodes class UWindow

static func get_control_absolute_position(control:Control) -> Vector2:
	return get_window_global_position(control.get_window()) + control.global_position

static func get_window_global_position(window:Window, vec2:bool=true):
	var id = window.get_window_id()
	var pos = DisplayServer.window_get_position(id)
	if vec2:
		return Vector2(pos)
	return pos
