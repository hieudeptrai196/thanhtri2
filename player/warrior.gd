class_name Warrior
extends CharacterBody3D
## On-foot warrior. Moves according to its PlayerInput intent.

## Metres per second.
@export var move_speed: float = 7.0
## Higher turns faster.
@export var turn_speed: float = 12.0

@onready var input: PlayerInput = $PlayerInput

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta: float) -> void:
	var direction := input.move_direction
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	if direction != Vector3.ZERO:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))

	move_and_slide()
