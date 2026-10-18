class_name MeleeWeapon
extends Area3D
## Swings in an arc toward a direction and hits every Hurtbox inside it.
## The area's shape sets the reach; its collision mask decides what counts as a target.
## `pick_target` chooses what an auto-attacking wielder should swing at.

signal swung(direction: Vector3, hit_count: int)

@export var damage: float = 10.0
## Seconds between swings.
@export var cooldown: float = 0.5
## Full width of the swing arc.
@export_range(10.0, 360.0) var arc_degrees: float = 120.0
## Hurtboxes on these layers are always preferred over others (enemies over trees and rocks).
@export_flags_3d_physics var priority_layers: int = 4
## How strongly the preferred direction outweighs distance when picking a target.
@export var aim_weight: float = 3.0

var _cooldown_left: float = 0.0
var _reach_shape: SphereShape3D


func _ready() -> void:
	# Own copy of the reach shape so upgrades do not grow every instance sharing the scene.
	var collision: CollisionShape3D = $Collision
	_reach_shape = collision.shape.duplicate()
	collision.shape = _reach_shape


func get_reach() -> float:
	return _reach_shape.radius


func apply_upgrade(upgrade: WeaponUpgrade) -> void:
	damage *= upgrade.damage_multiplier
	cooldown *= upgrade.cooldown_multiplier
	arc_degrees = minf(arc_degrees + upgrade.arc_bonus_degrees, 360.0)
	_reach_shape.radius *= upgrade.reach_multiplier


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func is_ready() -> bool:
	return _cooldown_left == 0.0


## Best Hurtbox in reach: priority layers first, then by distance plus how far it is from
## `preferred_direction` (ZERO = nearest). Returns null when nothing is in reach.
func pick_target(preferred_direction: Vector3) -> Hurtbox:
	var best: Hurtbox = null
	var best_score := INF
	var best_priority := false
	for area in get_overlapping_areas():
		if not area is Hurtbox:
			continue
		var priority: bool = area.collision_layer & priority_layers != 0
		if best_priority and not priority:
			continue
		var to_target: Vector3 = area.global_position - global_position
		to_target.y = 0.0
		var score := to_target.length()
		if preferred_direction != Vector3.ZERO and to_target.length() > 0.01:
			score += aim_weight * (1.0 - to_target.normalized().dot(preferred_direction))
		if (priority and not best_priority) or score < best_score:
			best = area
			best_score = score
			best_priority = priority
	return best


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
