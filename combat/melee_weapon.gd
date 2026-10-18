class_name MeleeWeapon
extends Area3D
## Swings in an arc toward a direction and hits every Hurtbox inside it.
## The area's shape sets the reach; its collision mask decides what counts as a target.

signal swung(direction: Vector3, hit_count: int)

@export var damage: float = 10.0
## Seconds between swings.
@export var cooldown: float = 0.5
## Full width of the swing arc.
@export_range(10.0, 360.0) var arc_degrees: float = 120.0

var _cooldown_left: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func try_attack(direction: Vector3) -> bool:
	if _cooldown_left > 0.0 or direction == Vector3.ZERO:
		return false
	_cooldown_left = cooldown
	var min_dot := cos(deg_to_rad(arc_degrees * 0.5))
	var hit_count := 0
	for area in get_overlapping_areas():
		if area is Hurtbox:
			var to_target: Vector3 = area.global_position - global_position
			to_target.y = 0.0
			if to_target.length() < 0.01 or to_target.normalized().dot(direction) >= min_dot:
				area.take_hit(damage, owner)
				hit_count += 1
	swung.emit(direction, hit_count)
	return true
