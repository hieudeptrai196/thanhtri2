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


func _ready() -> void:
	current = max_health


func apply_damage(amount: float, _source: Node = null) -> void:
	if current <= 0.0 or amount <= 0.0:
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


func reset() -> void:
	current = max_health
	health_changed.emit(current, max_health)


func get_ratio() -> float:
	return current / max_health
