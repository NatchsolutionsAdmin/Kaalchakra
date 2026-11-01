## DialogueParser — turns a .dialogue text file into something the game can run.
##
## The format is deliberately a screenplay with a few markers, so dialogue can
## be written in TextEdit by someone who does not program. Everything this
## parser understands is documented at the top of
## game/data/dialogue/_EXAMPLE.dialogue — if the two ever disagree, the example
## file is the one a writer reads, so fix this to match it.
##
##   # note          ignored
##   :: name         starts a chunk
##   @ name args     a directive (objective, flag, music, era, ...)
##   NAME: text      a spoken line; may carry [if flag] and a (stage direction)
##   > label -> to   a choice, optionally with trailing @ directives
##   -> target       jump; "-> END" finishes the scene
##
## parse() never throws. It collects problems into `errors` so a typo gives a
## readable list instead of a crash halfway through a scene.
class_name DialogueParser
extends RefCounted

const END := "END"


static func parse_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"chunks": {}, "order": [], "errors": ["No such file: %s" % path]}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"chunks": {}, "order": [], "errors": ["Could not open: %s" % path]}
	return parse(f.get_as_text(), path)


static func parse(text: String, source: String = "") -> Dictionary:
	var chunks: Dictionary = {}
	var order: Array[String] = []
	var errors: Array[String] = []
	var current := ""
	# Counts spoken lines within the current chunk, to build voice-file ids.
	var line_number := 0

	var speaker_re := RegEx.create_from_string("^([A-Z][A-Z0-9_ ]*):\\s*(.*)$")
	var cond_re := RegEx.create_from_string("^\\[(if|ifnot)\\s+([A-Za-z0-9_]+)\\]\\s*(.*)$")
	var dir_re := RegEx.create_from_string("^\\((.*?)\\)\\s*(.*)$")

	var lines := text.split("\n")
	for i in lines.size():
		var line := lines[i].strip_edges()
		var where := "%s:%d" % [source.get_file(), i + 1]
		if line.is_empty() or line.begins_with("#"):
			continue

		# :: chunk
		if line.begins_with("::"):
			line_number = 0
			current = line.substr(2).strip_edges()
			if current.is_empty():
				errors.append("%s: chunk with no name" % where)
				continue
			if chunks.has(current):
				errors.append("%s: chunk '%s' defined twice" % [where, current])
			chunks[current] = []
			order.append(current)
			continue

		if current.is_empty():
			errors.append("%s: content before the first :: chunk" % where)
			continue
		var steps: Array = chunks[current]

		# @ directive
		if line.begins_with("@"):
			var tokens := _tokenize(line.substr(1).strip_edges())
			if tokens.is_empty():
				errors.append("%s: empty @ directive" % where)
				continue
			steps.append({
				"type": "directive",
				"name": tokens[0],
				"args": tokens.slice(1),
				"where": where,
			})
			continue

		# > choice
		if line.begins_with(">"):
			var body := line.substr(1).strip_edges()
			if not body.contains("->"):
				errors.append("%s: choice has no -> target" % where)
				continue
			var label := body.get_slice("->", 0).strip_edges()
			var tail := body.substr(body.find("->") + 2).strip_edges()
			var target := tail
			var extra: Array = []
			if tail.contains("@"):
				target = tail.get_slice("@", 0).strip_edges()
				for piece: String in tail.substr(tail.find("@") + 1).split("@"):
					var t := _tokenize(piece.strip_edges())
					if not t.is_empty():
						extra.append({"name": t[0], "args": t.slice(1)})
			# Group runs of > lines into one choice point.
			if steps.is_empty() or steps[-1].get("type") != "choices":
				steps.append({"type": "choices", "options": [], "where": where})
			steps[-1]["options"].append({
				"label": _unquote(label),
				"target": target,
				"directives": extra,
			})
			continue

		# -> goto
		if line.begins_with("->"):
			steps.append({
				"type": "goto",
				"target": line.substr(2).strip_edges(),
				"where": where,
			})
			continue

		# NAME: line
		var m := speaker_re.search(line)
		if m == null:
			# A bare line continues the one above it, so a long speech can be
			# wrapped in the editor and still be ONE beat on screen and ONE
			# file for the voice actor.
			if not steps.is_empty() and steps[-1].get("type") == "line":
				var prev: Dictionary = steps[-1]
				prev["text"] = (prev["text"] + " " + line).strip_edges()
				continue
			errors.append("%s: don't understand this line — %s" % [where, line])
			continue
		var rest := m.get_string(2).strip_edges()
		var condition := ""
		var negate := false
		var c := cond_re.search(rest)
		if c != null:
			negate = c.get_string(1) == "ifnot"
			condition = c.get_string(2)
			rest = c.get_string(3).strip_edges()
		var direction := ""
		var d := dir_re.search(rest)
		if d != null:
			direction = d.get_string(1).strip_edges()
			rest = d.get_string(2).strip_edges()
		line_number += 1
		steps.append({
			"type": "line",
			# Stable name for this line's voice file. Changes if lines are
			# added or removed above it — which is exactly when a recording
			# would need redoing anyway.
			"id": "%s_%02d" % [current, line_number],
			"speaker": m.get_string(1).strip_edges(),
			"text": rest,
			"direction": direction,
			"condition": condition,
			"negate": negate,
			"where": where,
		})

	errors.append_array(_check_targets(chunks))
	return {"chunks": chunks, "order": order, "errors": errors}


## Every jump must land somewhere. This is the check that turns a typo into a
## readable message instead of a scene that silently stops.
static func _check_targets(chunks: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	for name: String in chunks:
		for step: Dictionary in chunks[name]:
			var targets: Array = []
			if step["type"] == "goto":
				targets.append(step["target"])
			elif step["type"] == "choices":
				for opt: Dictionary in step["options"]:
					targets.append(opt["target"])
			for t: String in targets:
				if t != END and not chunks.has(t):
					problems.append("%s: jumps to '%s', which does not exist"
						% [step.get("where", name), t])
	return problems


## Splits on spaces but keeps "quoted phrases" together, so
## `objective "Clear the trench floor"` is two tokens, not five.
static func _tokenize(s: String) -> Array[String]:
	var out: Array[String] = []
	var buf := ""
	var quoted := false
	for ch: String in s:
		if ch == '"':
			quoted = not quoted
		elif ch == " " and not quoted:
			if not buf.is_empty():
				out.append(buf)
				buf = ""
		else:
			buf += ch
	if not buf.is_empty():
		out.append(buf)
	return out


static func _unquote(s: String) -> String:
	if s.length() >= 2 and s.begins_with('"') and s.ends_with('"'):
		return s.substr(1, s.length() - 2)
	return s
