extends RefCounted
## StringMap: string and comment masks, contents and quote pairs. Every case runs against the
## GDScript parser, and against StringMapNative when it is loaded, so the two can't drift apart.

const StringMap = preload("res://addons/_lib/util_r/src/string/string_map.gd")


static func run_tests() -> Dictionary:
	var failures:Array[String] = []
	_run_cases(failures, "gd", func(text:String) -> StringMap: return StringMap.new(text))
	if ClassDB.class_exists("StringMapNative"):
		_run_cases(failures, "native", func(text:String) -> StringMap: return StringMap.create(text))
	return {"result": failures.size(), "output": failures}


static func _run_cases(failures:Array[String], leg:String, parse:Callable) -> void:
	# A lone quote inside a triple string doesn't close it.
	var map:StringMap = parse.call('"""a "b" c""" x')
	_expect(failures, leg, "triple: whole literal masked", _masked(map, 0, 13))
	_expect(failures, leg, "triple: code after it unmasked", map.string_mask[14] == 0)
	_expect(failures, leg, "triple: raw content", map.string_map.get(0) == 'a "b" c')
	_expect(failures, leg, "triple: quote_map ends on the last quote", map.quote_map.get(0) == 12 and map.quote_map.get(12) == 0)

	map = parse.call('"""\n# not a comment\n""" # real')
	_expect(failures, leg, "triple: '#' inside is not a comment", map.comment_mask[4] == 0 and map.string_mask[4] == 1)
	_expect(failures, leg, "triple: comment after it", map.comment_mask[24] == 1)

	map = parse.call('"""a\\"""b"""')
	_expect(failures, leg, "triple: an escaped quote doesn't close it", map.string_map.get(0) == 'a\\"""b' and map.quote_map.get(0) == 11)
	_expect(failures, leg, "triple: escape fully masked", _masked(map, 0, 12) and not map.has_errors)

	map = parse.call("'''it's''' x")
	_expect(failures, leg, "single-quote triple", map.string_map.get(0) == "it's" and map.string_mask[11] == 0)

	map = parse.call('x = """a""" + y')
	_expect(failures, leg, "triple mid-line", map.string_map.get(4) == "a" and map.string_mask[14] == 0 and map.string_mask[0] == 0)

	map = parse.call('"a\\"b" x')
	_expect(failures, leg, "escape: content kept raw", map.string_map.get(0) == 'a\\"b')
	_expect(failures, leg, "escape: string closes after it", map.quote_map.get(0) == 5 and map.string_mask[7] == 0)

	map = parse.call('"" + x')
	_expect(failures, leg, "empty string is not a triple", map.string_map.get(0) == "" and map.quote_map.get(0) == 1 and map.string_mask[5] == 0)

	map = parse.call('""""""')
	_expect(failures, leg, "empty triple", map.string_map.get(0) == "" and map.quote_map.get(0) == 5 and not map.has_errors)

	map = parse.call('"abc\\')
	_expect(failures, leg, "trailing backslash: unterminated, no overrun", map.has_errors and map.string_mask.size() == 5)

	map = parse.call('"""abc')
	_expect(failures, leg, "unterminated triple", map.has_errors and _masked(map, 0, 6))


## True when every index in [from, to) is masked as string.
static func _masked(map:StringMap, from:int, to:int) -> bool:
	for i in range(from, to):
		if map.string_mask[i] != 1:
			return false
	return true


static func _expect(failures:Array[String], leg:String, what:String, ok:bool) -> void:
	if not ok:
		failures.append("%s: %s" % [leg, what])
