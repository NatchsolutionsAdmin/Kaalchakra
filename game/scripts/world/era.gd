## The three "mornings" the Kaalchakra snaps between.
##
## This file holds no behaviour — it is a shared vocabulary so every other
## script can say Era.Id.PAST instead of a magic number. Because it declares
## `class_name`, Godot makes `Era` available everywhere without an import.
class_name Era
extends RefCounted

enum Id { PAST, PRESENT, FUTURE }

const ALL: Array[Id] = [Id.PAST, Id.PRESENT, Id.FUTURE]

## Which physics collision layer each era's solid geometry lives on.
## These are bit VALUES, not layer numbers: layer 2 = 2, layer 3 = 4, layer 4 = 8.
## The player's collision mask is rebuilt from this on every shift, which is how
## the inactive eras stop existing as far as walking is concerned.
const MASK: Dictionary = {
	Id.PAST: 2,
	Id.PRESENT: 4,
	Id.FUTURE: 8,
}

const SHORT: Dictionary = {
	Id.PAST: "PAST",
	Id.PRESENT: "PRESENT",
	Id.FUTURE: "FUTURE",
}

const TITLE: Dictionary = {
	Id.PAST: "1900 BCE  ·  Dholarath",
	Id.PRESENT: "2026  ·  The Dig",
	Id.FUTURE: "2087  ·  The Drowned Site",
}

## Era tints from CLAUDE.md: warm-gold past, neutral present, cold blue-grey future.
const TINT: Dictionary = {
	Id.PAST: Color(0.98, 0.78, 0.50),
	Id.PRESENT: Color(0.92, 0.90, 0.86),
	Id.FUTURE: Color(0.58, 0.72, 0.84),
}

const ACTION: Dictionary = {
	Id.PAST: "era_past",
	Id.PRESENT: "era_present",
	Id.FUTURE: "era_future",
}
