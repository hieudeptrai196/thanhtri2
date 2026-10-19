class_name IsoCamera
extends Camera3D
## Orthographic isometric camera that smoothly follows a target.

@export var target: Node3D
@export var distance: float = 60.0
@export var yaw_degrees: float = 45.0
@export var pitch_degrees: float = -35.0
## Higher is snappier.
@export var follow_speed: float = 5.0
## Screen shake: offset in metres at full trauma, and how fast trauma fades per second.
@export var shake_offset: float = 0.6
@export var shake_decay: float = 2.2

var _trauma: float = 0.0


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


## Adds screen shake (0..1, stacks up to 1). Uses the view offset, so it never moves the camera
## itself (no fight with physics interpolation, nothing for gameplay to notice).
func shake(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		return
	_trauma = maxf(_trauma - shake_decay * delta, 0.0)
	var power := _trauma * _trauma * shake_offset
	var t := Time.get_ticks_msec() * 0.05
	h_offset = (sin(t * 1.7) + sin(t * 3.1) * 0.5) * power
	v_offset = (cos(t * 2.3) + sin(t * 4.7) * 0.5) * power


func _desired_position() -> Vector3:
	return target.global_position + global_basis.z * distance
