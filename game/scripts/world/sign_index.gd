## SignIndex — reads data/signs/index.signs.
##
## Same block format as the dialogue files, for the same reason: a writer
## should be able to add a sign in TextEdit without opening Godot. Parsing
## never throws; problems come back as a list.
class_name SignIndex
extends RefCounted

const KEYS := ["name", "gloss", "learn", "match", "confirm", "hint", "header"]


static func parse_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"signs": {}, "order": [], "errors": ["No such file: %s" % path]}
	return parse(FileAccess.open(path, FileAccess.READ).get_as_text(), path)


static func parse(text: String, source: String = "") -> Dictionary:
	var signs: Dictionary = {}
	var order: Array[String] = []
	var errors: Array[String] = []
	var current := ""
	var last_key := ""

	var lines := text.split("\n")
	for i in lines.size():
		var raw := lines[i]
		var line := raw.strip_edges()
		var where := "%s:%d" % [source.get_file(), i + 1]
		if line.is_empty() or line.begins_with("#"):
			continue

		if line.begins_with("::"):
			current = line.substr(2).strip_edges()
			last_key = ""
			if current.is_empty():
				errors.append("%s: sign with no id" % where)
				continue
			if signs.has(current):
				errors.append("%s: sign '%s' defined twice" % [where, current])
			signs[current] = {"id": current, "header": 0}
			order.append(current)
			continue

		if current.is_empty():
			errors.append("%s: content before the first :: sign" % where)
			continue

		var colon := line.find(":")
		var key := line.substr(0, colon).strip_edges() if colon > 0 else ""
		if key in KEYS:
			var value := line.substr(colon + 1).strip_edges()
			signs[current][key] = int(value) if key == "header" else value
			last_key = key
		elif not last_key.is_empty():
			# A bare indented line continues the previous field.
			signs[current][last_key] = ("%s %s" % [signs[current][last_key], line]).strip_edges()
		else:
			errors.append("%s: don't understand this line — %s" % [where, line])

	for id: String in signs:
		for required: String in ["name", "learn", "match", "confirm"]:
			if not signs[id].has(required):
				errors.append("sign '%s' has no %s: — the chain needs all three eras" % [id, required])
	return {"signs": signs, "order": order, "errors": errors}
