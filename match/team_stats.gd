class_name TeamStats
extends RefCounted
## What each player did in the run, for the end-of-run summary by role (MVPs). Kept by the host,
## keyed by peer id so it survives respawns, and sent to clients with the result.
##   build   — seconds spent hammering blueprints
##   haul    — resource units brought to the fortress storage
##   kills   — enemies the player finished off (manning the fortress crossbow counts)
##   revives — teammates helped up

const CATEGORIES: Array[StringName] = [&"build", &"haul", &"kills", &"revives"]

# peer id -> {"order": join order, "class": PlayerClasses index or -1, category: amount...}
var _by_peer: Dictionary = {}


func add(peer: int, category: StringName, amount: float) -> void:
	_entry(peer)[category] = _entry(peer).get(category, 0.0) + amount


func set_class(peer: int, class_index: int) -> void:
	_entry(peer)["class"] = class_index


func value(peer: int, category: StringName) -> float:
	return _by_peer.get(peer, {}).get(category, 0.0)


func class_index(peer: int) -> int:
	return _by_peer.get(peer, {}).get("class", -1)


## 1-based order in which the player first showed up in the stats (a name for class-less players).
func order(peer: int) -> int:
	return _by_peer.get(peer, {}).get("order", 0)


func peers() -> Array:
	return _by_peer.keys()


## Peer with the most of `category`, or 0 when nobody did any. Ties go to whoever joined first.
func best(category: StringName) -> int:
	var best_peer := 0
	var best_value := 0.0
	for peer: int in _by_peer:
		var amount := value(peer, category)
		if amount > best_value or (amount == best_value and amount > 0.0 and order(peer) < order(best_peer)):
			best_peer = peer
			best_value = amount
	return best_peer


func net_state() -> Dictionary:
	return _by_peer.duplicate(true)


func apply_net_state(state: Dictionary) -> void:
	_by_peer = state.duplicate(true)


func _entry(peer: int) -> Dictionary:
	if not _by_peer.has(peer):
		_by_peer[peer] = {"order": _by_peer.size() + 1, "class": -1}
	return _by_peer[peer]
