#! namespace UtilR.Resources.Read class Tres

const UString = preload("uid://dce8d0wuh35gs") #! resolve UtilR.Strings.UString
const UFile = preload("uid://bqfy5cvhth0m1") #! resolve UtilR.Files.UFile


static func get_resource_script_class(path:String):
	if path.get_extension() == "tres":
		return _get_resource_script_class_file_access(path)
	var res = load(path) as Resource
	var script = res.get_script() as GDScript
	if script == null:
		return ""
	return script.get_global_name()

static func _get_resource_script_class_file_access(file_path: String) -> String:
	var result:String = ""
	var f:FileAccess = UFile.get_file_access(file_path)
	if f:
		var header:String = f.get_line()
		if "script_class=" in header:
			var start_index:int = header.find("script_class=") + 14 # Length of 'script_class="'
			var end_index:int = header.find('"', start_index)
			if end_index != -1:
				result = header.substr(start_index, end_index - start_index)
	return result
