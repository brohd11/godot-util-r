#! namespace UtilR.Resources class UResource

const UFile = preload("uid://bqfy5cvhth0m1") #! resolve UtilR.Files.UFile

static func ensure_fresh_load(resource:Resource, cache_hint:=ResourceLoader.CACHE_MODE_IGNORE_DEEP) -> Resource:
	if not UFile.path_in_res(resource.resource_path):
		return ResourceLoader.load(resource.resource_path, "", cache_hint)
	return resource

static func save_resource_to_path(res:Resource,path:String, name_overide:String="") -> Error:
	if name_overide == "":
		res.resource_name = path.get_file().get_basename()
	else:
		res.resource_name = name_overide
	var err = ResourceSaver.save(res, path)
	if err == OK:
		res.take_over_path(path)
	return err


static func load_or_get_icon(name_or_path:String):
	if FileAccess.file_exists(name_or_path):
		return load(name_or_path)
	if not Engine.is_editor_hint():
		return null
	var editor_interface = Engine.get_singleton(&"EditorInterface")
	if is_instance_valid(editor_interface):
		var theme = editor_interface.get_editor_theme()
		if theme.has_icon(name_or_path, &"EditorIcons"):
			return theme.get_icon(name_or_path, &"EditorIcons")
	return null
