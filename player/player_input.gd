class_name PlayerInput
extends Node
## Turns local device input into player intent. Gameplay reads only this, never Input directly,
## so intent can later come from the network instead.

signal ready_requested

## World-space direction on the ground plane, length 0..1.
var move_direction: Vector3 = Vector3.ZERO


func _physics_process(_delta: float) -> void:
	var stick := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	move_direction = _to_world(stick)
	if Input.is_action_just_pressed("ready"):
		ready_requested.emit()


# Screen-relative stick -> world direction, so "up" always moves up the screen.
func _to_world(stick: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null or stick == Vector2.ZERO:
		return Vector3.ZERO
	var right := Vector3(camera.global_basis.x.x, 0.0, camera.global_basis.x.z).normalized()
	var forward := Vector3(-camera.global_basis.z.x, 0.0, -camera.global_basis.z.z).normalized()
	return (right * stick.x - forward * stick.y).limit_length(1.0)
