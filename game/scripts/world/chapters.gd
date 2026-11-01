## Chapters — the shape of the game, as data.
##
## Prologue, five chapters, finale, from kaalchakra-story-bible.md §5. The
## chapter select reads this; so will the flow manager when it exists. Keeping
## it here means the running order lives in one place rather than being
## implied by whichever scene happens to load next.
class_name Chapters
extends RefCounted

const LIST: Array[Dictionary] = [
	{"id": "prologue", "no": "PROLOGUE", "title": "Overburden",
	 "era": Era.Id.PRESENT, "mins": 20,
	 "line": "2026, the dig at first light. She lifts a copper wheel and it is warm.",
	 "scene": "res://scenes/Main.tscn",
	 "dialogue": "res://data/dialogue/prologue_overburden.dialogue"},
	{"id": "ch1", "no": "CHAPTER ONE", "title": "The Living City",
	 "era": Era.Id.PAST, "mins": 50,
	 "line": "Dholarath at its height, and a reservoir at one third that the council calls half.",
	 "scene": "", "dialogue": ""},
	{"id": "ch2", "no": "CHAPTER TWO", "title": "The Index",
	 "era": Era.Id.PRESENT, "mins": 50,
	 "line": "The signs are not a language. They are labels — and her mother said so first.",
	 "scene": "res://scenes/Main.tscn", "dialogue": ""},
	{"id": "ch3", "no": "CHAPTER THREE", "title": "The Engineer's Gambit",
	 "era": Era.Id.PAST, "mins": 55,
	 "line": "The river cannot be argued with. But the river only takes what no one carries.",
	 "scene": "", "dialogue": ""},
	{"id": "ch4", "no": "CHAPTER FOUR", "title": "Two Floods",
	 "era": Era.Id.FUTURE, "mins": 55,
	 "line": "Two drownings, four thousand years apart, and one of them is still avoidable.",
	 "scene": "", "dialogue": ""},
	{"id": "ch5", "no": "CHAPTER FIVE", "title": "The Keeper's Ledger",
	 "era": Era.Id.FUTURE, "mins": 50,
	 "line": "The skeleton in the chamber is carbon-dated 2140 CE. Keepers come from many centuries.",
	 "scene": "", "dialogue": ""},
	{"id": "finale", "no": "FINALE", "title": "The Signboard",
	 "era": Era.Id.PAST, "mins": 30,
	 "line": "Ten signs above the north gate. Not a name. Not a prayer. An address list.",
	 "scene": "", "dialogue": ""},
]


static func playable(entry: Dictionary) -> bool:
	return not String(entry.get("scene", "")).is_empty()
