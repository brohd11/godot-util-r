extends RefCounted
## Placer: popup positions are in the embedder's canvas when the window embeds subwindows (a
## game), and on the screen when popups are their own windows (the editor).

const Placer = preload("res://addons/_lib/util_r/src/node/popup/placer.gd")


static func run_tests() -> Dictionary:
	var failures:Array[String] = []
	var root:Window = Engine.get_main_loop().root
	var embedding = root.gui_embed_subwindows
	var control = Control.new()
	control.position = Vector2(100, 50)
	control.size = Vector2(40, 20)
	root.add_child(control)

	root.gui_embed_subwindows = true
	var centered = Placer.get_centered_control_position(control)
	_expect(failures, "embedded: the control's top centre in the canvas, got %s" % [centered], centered == Vector2i(120, 50))
	var offset = Placer.get_window_offset_position(control, Vector2i(110, 60))
	_expect(failures, "embedded: a canvas point stays put, got %s" % [offset], offset == Vector2i(110, 60))

	root.gui_embed_subwindows = false
	var screen = Vector2i(control.get_screen_transform() * Vector2(20, 0))
	centered = Placer.get_centered_control_position(control)
	_expect(failures, "native: on the screen, got %s, expected %s" % [centered, screen], centered == screen)
	_expect(failures, "native: the mouse on the screen", Placer.mouse_popup_position(control) == DisplayServer.mouse_get_position())

	root.gui_embed_subwindows = embedding
	control.free()
	return {"result": failures.size(), "output": failures}


static func _expect(failures:Array[String], what:String, ok:bool) -> void:
	if not ok:
		failures.append(what)
