#! namespace UtilR.Nodes.Trees class UTree

const UVersion = preload("uid://dn156lc18d1vt") #! resolve UtilR.UVersion

static func get_line_edit(tree:Tree):
	var version = UVersion.get_minor_version()
	if version < 6:
		return tree.get_child(1, true).get_child(0, true).get_child(0, true)
	else: #elif version <= 7: # Deal with when there is an issue in new version
		return tree.get_child(0, true).get_child(0, true).get_child(0, true)

## manually calc item text overflow, for use with a right aligned icon
## assumes standard tree, column 0
static func item_text_overflows(tree:Tree, item: TreeItem, custom_icon:Texture2D) -> bool:
	var font = tree.get_theme_font(&"font")
	var font_size = tree.get_theme_font_size(&"font_size")
	
	var text: String = item.get_text(0)
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var available_width: float = tree.get_column_width(0)
	
	
	var depth = 0
	var parent = item.get_parent()
	while parent != null:
		depth += 1
		parent = parent.get_parent()
	
	# Subtract the margin for every level of depth
	available_width -= (tree.get_theme_constant(&"item_margin") * depth)
	# *3 to account for the margin for the custom icon + separation
	available_width -= tree.get_theme_constant(&"icon_h_separation") * 3
	available_width -= custom_icon.get_width()
	
	
	# 5. Check if the Text Width + Icon Width clashes with the Column Width
	var icon_width = item.get_icon(0).get_width()
	
	# We leave a small margin (e.g., 10 pixels) for spacing
	var is_clashing = (text_width + icon_width) > available_width
	
	return is_clashing

static func find_item_by_meta(start_item: TreeItem, meta_value) -> TreeItem:
	var metadata = start_item.get_metadata(0)
	if metadata == meta_value:
		return start_item
	
	for child in start_item.get_children():
		var found_item = find_item_by_meta(child, meta_value)
		if found_item:
			return found_item
	
	return null

static func uncollapse_items(items:Array, item_collapsed_callable:Callable):
	for item in items:
		var parent = item.get_parent()
		while parent:
			parent.collapsed = false
			item_collapsed_callable.call(parent)
			parent = parent.get_parent()
		item.collapsed = false


class GetDropData:
	static func files(selected_item_paths, from_node):
		var data_type = "files"
		var selected_paths = []
		for path in selected_item_paths:
			#print(path)
			if DirAccess.dir_exists_absolute(path):
				data_type = "files_and_dirs"
				if not path.ends_with("/"):
					path = path + "/"
				selected_paths.append(path)
			else:
				selected_paths.append(path)
		
		var data = {"type": data_type, "files": selected_paths, "from": from_node}
		return data

class CanDropData:
	static func files(at_position: Vector2, data: Variant, extensions:Array=[]) -> bool:
		var type = data.get("type")
		if type == "files" or type == "files_and_dirs":
			if extensions == []:
				return true
			var files = data.get(type)
			for f in files:
				var ext = f.get_extension()
				if ext in extensions:
					return true
		return false
