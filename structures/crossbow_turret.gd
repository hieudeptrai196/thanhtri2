class_name CrossbowTurret
extends Structure
## Foldable turret. Its AutoShooter fires at the nearest enemy while the turret runs. When its buffer
## runs out it overloads ("last shot"): fires faster for a few seconds, then explodes and is gone.

const BLAST_SCENE := preload("res://world/blast_fx.tscn")

@export var last_shot_duration: float = 4.0
@export var last_shot_rate_multiplier: float = 3.0
@export var blast_damage: float = 60.0

@onready var _shooter: AutoShooter = $AutoShooter
@onready var _blast_area: Area3D = $BlastArea
@onready var _status: Label3D = $Status

## Seconds of overload left; negative when not overloading.
var _last_shot_left: float = -1.0


func is_overloading() -> bool:
	return _last_shot_left >= 0.0


func can_recover() -> bool:
	return super() and not is_overloading()


func _physics_process(delta: float) -> void:
	if not built:
		_shooter.enabled = false
		return
	if is_overloading():
		_last_shot_left -= delta
		if _last_shot_left <= 0.0:
			_explode()
			return
	_update_status()
	_shooter.enabled = is_running() or is_overloading()
	_shooter.rate_multiplier = last_shot_rate_multiplier if is_overloading() else 1.0


func _on_buffer_empty() -> void:
	if not is_overloading():
		_last_shot_left = last_shot_duration


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
