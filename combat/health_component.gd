class_name HealthComponent
extends Node
## Owns hit points. All damage goes through here so one place decides health state
## (in multiplayer, only the server will call apply_damage). An optional shield soaks damage first.

signal health_changed(current: float, maximum: float)
signal died
signal shield_changed(shield: float, maximum: float)

@export var max_health: float = 100.0

var current: float
var shield: float = 0.0
var max_shield: float = 0.0


## Scales incoming damage (e.g. a Võ tướng's Hét trận halves it for a while).
var damage_taken_multiplier: float = 1.0

func _ready() -> void:
	current = max_health


func apply_damage(amount: float, _source: Node = null) -> void:
	amount *= damage_taken_multiplier
	# Only the host decides damage; clients get health from snapshots (offline counts as host).
	if current <= 0.0 or amount <= 0.0 or not multiplayer.is_server():
		return
	if shield > 0.0:
		var absorbed := minf(shield, amount)
		shield -= absorbed
		amount -= absorbed
		shield_changed.emit(shield, max_shield)
		if amount <= 0.0:
			return
	current = maxf(current - amount, 0.0)
	health_changed.emit(current, max_health)
	if current == 0.0:
		died.emit()


func heal(amount: float) -> void:
	if current <= 0.0 or amount <= 0.0 or current >= max_health:
		return
	current = minf(current + amount, max_health)
	health_changed.emit(current, max_health)


## Changes max health; current health moves by the same amount so damage already taken is kept.
func set_max_health(value: float) -> void:
	current = clampf(current + value - max_health, 0.0, value)
	max_health = value
	health_changed.emit(current, max_health)


func set_max_shield(value: float) -> void:
	max_shield = value
	shield = minf(shield, value)
	shield_changed.emit(shield, max_shield)


func restore_shield(amount: float) -> void:
	if amount <= 0.0 or shield >= max_shield:
		return
	shield = minf(shield + amount, max_shield)
	shield_changed.emit(shield, max_shield)


## Client side: takes the host's numbers and notifies listeners (HUD) like a real change.
func set_net_state(new_current: float, new_max: float, new_shield: float, new_max_shield: float) -> void:
	if new_current != current or new_max != max_health:
		current = new_current
		max_health = new_max
		health_changed.emit(current, max_health)
	if new_shield != shield or new_max_shield != max_shield:
		shield = new_shield
		max_shield = new_max_shield
		shield_changed.emit(shield, max_shield)


func reset() -> void:
	current = max_health
	health_changed.emit(current, max_health)


func get_ratio() -> float:
	return current / max_health
