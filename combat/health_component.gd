class_name HealthComponent
extends Node
## Owns hit points. All damage goes through here so one place decides health state
## (in multiplayer, only the server will call apply_damage).

signal health_changed(current: float, maximum: float)
signal died

@export var max_health: float = 100.0

var current: float


func _ready() -> void:
	current = max_health


func apply_damage(amount: float, _source: Node = null) -> void:
	if current <= 0.0 or amount <= 0.0:
		return
	current = maxf(current - amount, 0.0)
	health_changed.emit(current, max_health)
	if current == 0.0:
		died.emit()


func reset() -> void:
	current = max_health
	health_changed.emit(current, max_health)


func get_ratio() -> float:
	return current / max_health
