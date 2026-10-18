class_name PlayerInput
extends Node
## Turns local device input into player intent. Gameplay reads only this, never Input directly,
## so intent can later come from the network instead.

signal ready_requested

## World-space direction on the ground plane, length 0..1.
var move_direction: Vector3 = Vector3.ZERO
## World-space unit direction on the ground plane the player aims at.
var aim_direction: Vector3 = Vector3.FORWARD
var attack_held: bool = false

# Mouse aims while the player uses mouse/keyboard; with a gamepad the right stick aims.
var _using_gamepad: bool = false


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.3):
		_using_gamepad = true
	elif event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
		_using_gamepad = false


func _physics_process(_delta: float) -> void:
	move_direction = _to_world(Input.get_vector("move_left", "move_right", "move_up", "move_down"))
	aim_direction = _read_aim()
	attack_held = Input.is_action_pressed("attack")
	if Input.is_action_just_pressed("ready"):
		ready_requested.emit()


## Direction from the owning body to the ground point under a screen position, or ZERO.
func aim_from_screen(screen_position: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	var body := get_parent() as Node3D
	if camera == null or body == null:
		return Vector3.ZERO
	var ground := Plane(Vector3.UP, body.global_position.y)
	var hit: Variant = ground.intersects_ray(
		camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position))
	if hit == null:
		return Vector3.ZERO
	var flat: Vector3 = hit - body.global_position
	flat.y = 0.0
	return flat.normalized() if flat.length() > 0.1 else Vector3.ZERO


func _read_aim() -> Vector3:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick != Vector2.ZERO:
		return _to_world(stick).normalized()
	if not _using_gamepad:
		var mouse_aim := aim_from_screen(get_viewport().get_mouse_position())
		if mouse_aim != Vector3.ZERO:
			return mouse_aim
	elif move_direction != Vector3.ZERO:
		return move_direction.normalized()
	return aim_direction


# Screen-relative stick -> world direction, so "up" always moves up the screen.
func _to_world(stick: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null or stick == Vector2.ZERO:
		return Vector3.ZERO
	var right := Vector3(camera.global_basis.x.x, 0.0, camera.global_basis.x.z).normalized()
	var forward := Vector3(-camera.global_basis.z.x, 0.0, -camera.global_basis.z.z).normalized()
	return (right * stick.x - forward * stick.y).limit_length(1.0)
