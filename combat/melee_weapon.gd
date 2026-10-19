class_name MeleeWeapon
extends Area3D
## The wielder's basic attack, in one of three styles (set per class, see PlayerClass):
##   ARC — swings in an arc toward a direction and hits every Hurtbox inside it (default);
##   SMASH — slams the ground a little ahead and hits everything within `splash_radius` of that point;
##   PROJECTILE — fires a Projectile (axe, orb, bolt) at the picked target, dealing damage on arrival.
## The area's shape sets the reach (the range for projectiles); its collision mask decides what
## counts as a target. `pick_target` chooses what an auto-attacking wielder should attack.

signal swung(direction: Vector3, hit_count: int)

enum Style { ARC, SMASH, PROJECTILE }

@export var damage: float = 10.0
## Seconds between swings.
@export var cooldown: float = 0.5
## Full width of the swing arc.
@export_range(10.0, 360.0) var arc_degrees: float = 120.0
## Hurtboxes on these layers are always preferred over others (enemies over trees and coal deposits).
@export_flags_3d_physics var priority_layers: int = 4
## How strongly the preferred direction outweighs distance when picking a target.
@export var aim_weight: float = 3.0
@export var style: Style = Style.ARC
## SMASH: radius around the impact point; PROJECTILE: splash around the hit (0 = none).
@export var splash_radius: float = 0.0
## PROJECTILE: which projectile (see Projectile.LOOKS; anything else is a magic orb) and its speed.
@export var projectile_kind: StringName = &"bolt"
@export var projectile_speed: float = 22.0

var _cooldown_left: float = 0.0
var _reach_shape: SphereShape3D


func _ready() -> void:
	# Own copy of the reach shape so upgrades do not grow every instance sharing the scene.
	var collision: CollisionShape3D = $Collision
	_reach_shape = collision.shape.duplicate()
	collision.shape = _reach_shape


func get_reach() -> float:
	return _reach_shape.radius


## Sets the attack from a class (before any upgrades are applied on top).
func configure(new_style: Style, reach: float, arc: float, seconds_between: float, splash: float = 0.0,
		kind: StringName = &"bolt", speed: float = 22.0) -> void:
	style = new_style
	_reach_shape.radius = reach
	arc_degrees = arc
	cooldown = seconds_between
	splash_radius = splash
	projectile_kind = kind
	projectile_speed = speed


## Where a SMASH lands for a swing toward `direction`.
func smash_point(direction: Vector3) -> Vector3:
	return global_position + direction * get_reach() * 0.55


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


## Attacks toward `direction`; PROJECTILE needs the `target` to fire at.
func try_attack(direction: Vector3, target: Hurtbox = null) -> bool:
	if _cooldown_left > 0.0 or direction == Vector3.ZERO:
		return false
	if style == Style.PROJECTILE and target == null:
		return false
	_cooldown_left = cooldown
	var hit_count := 0
	match style:
		Style.ARC:
			var min_dot := cos(deg_to_rad(arc_degrees * 0.5))
			for area in get_overlapping_areas():
				if area is Hurtbox:
					var to_target: Vector3 = area.global_position - global_position
					to_target.y = 0.0
					if to_target.length() < 0.01 or to_target.normalized().dot(direction) >= min_dot:
						area.take_hit(damage, owner)
						hit_count += 1
		Style.SMASH:
			var impact := smash_point(direction)
			for area in get_overlapping_areas():
				if area is Hurtbox:
					var offset: Vector3 = area.global_position - impact
					offset.y = 0.0
					if offset.length() <= splash_radius:
						area.take_hit(damage, owner)
						hit_count += 1
		Style.PROJECTILE:
			launch(direction, target, damage)
			hit_count = 1
	swung.emit(direction, hit_count)
	return true


## Fires a projectile from the wielder's hand height. With `damage` 0 it is only a picture (what
## clients show for shots the host fired).
func launch(direction: Vector3, target: Hurtbox, shot_damage: float) -> void:
	var world := owner.get_parent() if owner and owner.get_parent() else get_parent()
	var shot := Projectile.new()
	shot.kind = projectile_kind
	shot.speed = projectile_speed
	shot.damage = shot_damage
	shot.splash_radius = splash_radius
	shot.source = owner
	shot.target = target
	shot.max_distance = get_reach() * 1.3
	shot.direction = direction
	world.add_child(shot)
	shot.global_position = global_position + Vector3(0.0, 1.1, 0.0) + direction * 0.5
	shot.reset_physics_interpolation()
