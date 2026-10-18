class_name Tower
extends Node3D
## Fortress-mounted tower. Shoots the nearest enemy Hurtbox inside its range every `interval` seconds.
## Which hurtboxes count as targets is decided by the Range area's collision mask.

@export var damage: float = 10.0
## Seconds between shots.
@export var interval: float = 1.0

@onready var _range: Area3D = $Range
@onready var _muzzle: Marker3D = $Muzzle
@onready var _tracer: MeshInstance3D = $Tracer

var _cooldown: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0:
		return
	var target := _nearest_target()
	if target == null:
		return
	_cooldown = interval
	_show_tracer(target.global_position + Vector3(0.0, 1.0, 0.0))
	target.take_hit(damage, self)


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


# Placeholder shot: a thin bar from the muzzle to the target, visible for a moment.
func _show_tracer(to: Vector3) -> void:
	var from := _muzzle.global_position
	var length := from.distance_to(to)
	if length < 0.01:
		return
	var basis := Basis.looking_at(to - from).scaled(Vector3(1.0, 1.0, length))
	_tracer.global_transform = Transform3D(basis, (from + to) * 0.5)
	_tracer.visible = true
	get_tree().create_timer(0.08).timeout.connect(_tracer.hide)
