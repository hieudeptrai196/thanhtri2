class_name IsoCamera
extends Camera3D
## Orthographic isometric camera that smoothly follows a target.

@export var target: Node3D
@export var distance: float = 60.0
@export var yaw_degrees: float = 45.0
@export var pitch_degrees: float = -35.0
## Higher is snappier.
@export var follow_speed: float = 5.0


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0.0)
	if target:
		global_position = _desired_position()


# Physics tick to stay in step with the target, which moves in _physics_process.
func _physics_process(delta: float) -> void:
	if target == null:
		return
	global_position = global_position.lerp(_desired_position(), 1.0 - exp(-follow_speed * delta))


func _desired_position() -> Vector3:
	return target.global_position + global_basis.z * distance
