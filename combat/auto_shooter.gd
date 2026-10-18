class_name AutoShooter
extends Node3D
## Shoots the nearest Hurtbox inside its Range area every `interval` seconds while `enabled`.
## Which hurtboxes count as targets is decided by the Range area's collision mask.
## Used by field turrets and the fortress's own crossbow.

## Every shot, so the host can show it to clients.
signal fired(from: Vector3, to: Vector3)

@export var damage: float = 10.0
## Seconds between shots.
@export var interval: float = 1.0
@export var enabled: bool = true
@export var range_radius: float = 14.0
## > 1 shoots faster (e.g. a turret's last shot).
var rate_multiplier: float = 1.0

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
	var target := _nearest_target()
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


## Placeholder shot: a thin bar from the muzzle to the target, visible for a moment.
## Clients call it with the shots the host reports.
func show_tracer(from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.01:
		return
	var basis := Basis.looking_at(to - from).scaled(Vector3(1.0, 1.0, length))
	_tracer.global_transform = Transform3D(basis, (from + to) * 0.5)
	_tracer.visible = true
	get_tree().create_timer(0.08).timeout.connect(_tracer.hide)
