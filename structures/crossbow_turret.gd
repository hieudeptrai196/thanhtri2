class_name CrossbowTurret
extends Structure
## Foldable turret. Shoots the nearest enemy in range while running. When its buffer runs out it
## overloads ("last shot"): fires faster for a few seconds, then explodes and is gone.

const BLAST_SCENE := preload("res://world/blast_fx.tscn")

@export var damage: float = 10.0
## Seconds between shots.
@export var interval: float = 1.0
@export var last_shot_duration: float = 4.0
@export var last_shot_rate_multiplier: float = 3.0
@export var blast_damage: float = 60.0

@onready var _range: Area3D = $Range
@onready var _blast_area: Area3D = $BlastArea
@onready var _muzzle: Marker3D = $Muzzle
@onready var _tracer: MeshInstance3D = $Tracer
@onready var _status: Label3D = $Status

var _cooldown: float = 0.0
## Seconds of overload left; negative when not overloading.
var _last_shot_left: float = -1.0


func is_overloading() -> bool:
	return _last_shot_left >= 0.0


func can_recover() -> bool:
	return super() and not is_overloading()


func _physics_process(delta: float) -> void:
	if not built:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if is_overloading():
		_last_shot_left -= delta
		if _last_shot_left <= 0.0:
			_explode()
			return
	_update_status()
	if (not is_running() and not is_overloading()) or _cooldown > 0.0:
		return
	var target := _nearest_target()
	if target == null:
		return
	_cooldown = interval / (last_shot_rate_multiplier if is_overloading() else 1.0)
	_show_tracer(target.global_position + Vector3(0.0, 1.0, 0.0))
	target.take_hit(damage, self)


func _on_buffer_empty() -> void:
	if not is_overloading():
		_last_shot_left = last_shot_duration


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


func _explode() -> void:
	for area in _blast_area.get_overlapping_areas():
		if area is Hurtbox:
			area.take_hit(blast_damage, self)
	var blast: Node3D = BLAST_SCENE.instantiate()
	get_parent().add_child(blast)
	blast.global_position = global_position
	destroyed.emit(self)
	queue_free()


# Placeholder status: seconds of buffer left while unpowered, warning while overloading.
func _update_status() -> void:
	if is_overloading():
		_status.text = "!!!"
		_status.modulate = Color(1.0, 0.35, 0.2)
	elif not powered:
		_status.text = "%ds" % ceili(buffer)
		_status.modulate = Color(1.0, 0.85, 0.3) if buffer > 10.0 else Color(1.0, 0.45, 0.25)
	_status.visible = is_overloading() or not powered


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
