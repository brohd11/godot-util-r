extends RefCounted
## ScriptRebase fixture: rebuilt onto base.gd. Its preload is relative, which a rebuilt script must
## still resolve against this file (Godot 4.4/4.5 resolve it against gdscript:// otherwise).

const Helper = preload("../lib/helper.gd")


func value() -> int:
	return Helper.VALUE
