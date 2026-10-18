class_name Inventory
extends Node
## Resource amounts keyed by ResourceType.id, with an optional total capacity.
## Contents/costs elsewhere use the same shape: { &"wood": 3, &"coal": 1 }.

signal changed

## Max total units across all types; 0 means unlimited.
@export var capacity: int = 0

var amounts: Dictionary = {}


func total() -> int:
	var sum := 0
	for count in amounts.values():
		sum += count
	return sum


func get_amount(id: StringName) -> int:
	return amounts.get(id, 0)


## Adds up to `count`; returns how many fit.
func add(id: StringName, count: int) -> int:
	var accepted := count if capacity <= 0 else mini(count, capacity - total())
	if accepted <= 0:
		return 0
	amounts[id] = get_amount(id) + accepted
	changed.emit()
	return accepted


## Adds as much of `contents` as fits; returns what is left over.
func add_all(contents: Dictionary) -> Dictionary:
	var left := {}
	for id in contents:
		var rest: int = contents[id] - add(id, contents[id])
		if rest > 0:
			left[id] = rest
	return left


func has_all(cost: Dictionary) -> bool:
	for id in cost:
		if get_amount(id) < cost[id]:
			return false
	return true


func spend(cost: Dictionary) -> bool:
	if not has_all(cost):
		return false
	for id in cost:
		amounts[id] -= cost[id]
	changed.emit()
	return true


## Client side: replaces the amounts with the host's and notifies listeners if they changed.
func set_net_amounts(new_amounts: Dictionary) -> void:
	if new_amounts != amounts:
		amounts = new_amounts.duplicate()
		changed.emit()


func take_all() -> Dictionary:
	var taken := amounts.duplicate()
	amounts.clear()
	changed.emit()
	return taken
