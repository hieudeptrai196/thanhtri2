class_name AutoShooter
extends Node3D
## Shoots the nearest Hurtbox inside its Range area every `interval` seconds while `enabled`.
## Which hurtboxes count as targets is decided by the Range area's collision mask.
## Used by field turrets and the fortress's own crossbow. While someone aims it (`aim_direction` set),
## it shoots the target closest to that direction instead, and holds fire when nothing is in the cone.

## Every shot, so the host can show it to clients.
signal fired(from: Vector3, to: Vector3)

@export var damage: float = 10.0
## Seconds between shots.
@export var interval: float = 1.0
@export var enabled: bool = true
@export var range_radius: float = 14.0
## Half-angle of the cone searched around `aim_direction`.
@export var aim_cone_degrees: float = 35.0
## > 1 shoots faster (e.g. a turret's last shot).
var rate_multiplier: float = 1.0
## Ground-plane direction a gunner aims at; ZERO = pick the nearest target by itself.
var aim_direction: Vector3 = Vector3.ZERO

@onready var _range: Area3D = $Range
@onready var _muzzle: Marker3D = $Muzzle
@onready var _tracer: MeshInstance3D = $Tracer

var _cooldown: float = 0.0


func set_range(radius: float) -> void:
	range_radius = radius
	($Range/Collision as CollisionShape3D).shape.radius = radius


func _ready() -> void:
	# Own copy of the range shape so upgrading one shooter does not change every instance.
	var collision: CollisionShape3D = $Range/Collision
	collision.shape = collision.shape.duplicate()
	set_range(range_radius)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not enabled or _cooldown > 0.0:
		return
	var target := _aimed_target() if aim_direction != Vector3.ZERO else _nearest_target()
	if target == null:
		return
	_cooldown = interval / rate_multiplier
	var aim := target.global_position + Vector3(0.0, 1.0, 0.0)
	show_tracer(_muzzle.global_position, aim)
	fired.emit(_muzzle.global_position, aim)
	target.take_hit(damage, owner)


func _nearest_target() -> Hurtbox:
	var best: Hurtbox = null
	var best_distance := INF
	for area in _range.get_overlapping_areas():
		if area is Hurtbox:
			var distance := global_position.distance_squared_to(area.global_position)
			if distance < best_distance:
				best = area
				best_distance = distance
	return best


# The target whose direction is closest to the aim, inside the cone.
func _aimed_target() -> Hurtbox:
	var best: Hurtbox = null
	var best_angle := deg_to_rad(aim_cone_degrees)
	var aim := Vector2(aim_direction.x, aim_direction.z)
	for area in _range.get_overlapping_areas():
		if area is Hurtbox:
			var offset: Vector3 = area.global_position - global_position
			var angle := absf(aim.angle_to(Vector2(offset.x, offset.z)))
			if angle <= best_angle:
				best = area
				best_angle = angle
	return best


## Placeholder shot: a thin bar from the muzzle to the target, visible for a moment.
## Clients call it with the shots the host reports.
func show_tracer(from: Vector3, to: Vector3) -> void:
	Sfx.play(self, &"shoot", from)
	var length := from.distance_to(to)
	if length < 0.01:
		return
	var basis := Basis.looking_at(to - from).scaled(Vector3(1.0, 1.0, length))
	_tracer.global_transform = Transform3D(basis, (from + to) * 0.5)
	_tracer.visible = true
	get_tree().create_timer(0.08).timeout.connect(_tracer.hide)
