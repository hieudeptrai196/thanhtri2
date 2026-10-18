class_name Hurtbox
extends Area3D
## Receives hits and forwards them to a HealthComponent. Attackers never touch health directly.

signal hit_taken(amount: float, source: Node)

@export var health: HealthComponent


func take_hit(amount: float, source: Node) -> void:
	health.apply_damage(amount, source)
	hit_taken.emit(amount, source)
