class_name PlayerInput
extends Node
## Turns local device input into player intent. Gameplay reads only this, never Input directly,
## so intent can later come from the network instead.

signal ready_requested

## Number keys that pick a structure; key 1 = StructureTypes.ALL[0], ...
const BUILD_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4]
## How far in front of the player the build ghost sits when aiming with a stick.
const STICK_GHOST_DISTANCE := 3.5

## World-space direction on the ground plane, length 0..1.
var move_direction: Vector3 = Vector3.ZERO
## World-space unit direction on the ground plane the player aims at.
var aim_direction: Vector3 = Vector3.FORWARD
## Ground point the player points at (mouse cursor, or a spot ahead along the stick aim).
var aim_point: Vector3 = Vector3.ZERO
## Raw right stick (screen space), used by the radial build menu.
var aim_stick: Vector2 = Vector2.ZERO
var attack_held: bool = false
var interact_held: bool = false
var recover_held: bool = false
## Held to open the radial build menu (gamepad LB / Q).
var radial_held: bool = false
# The flags below are true only on the tick the button goes down.
var dash_pressed: bool = false
var place_pressed: bool = false
var cancel_pressed: bool = false
## Index into StructureTypes.ALL picked by a number key this tick, or -1.
var build_select: int = -1

# Mouse aims while the player uses mouse/keyboard; with a gamepad the right stick aims.
var _using_gamepad: bool = false
var _pending_select: int = -1


# Read input before the body that consumes it, so intent is never a tick late.
func _ready() -> void:
	process_physics_priority = -10


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.3):
		_using_gamepad = true
	elif event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
		_using_gamepad = false


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var index := BUILD_KEYS.find(event.physical_keycode)
		if index != -1:
			_pending_select = index


func _physics_process(_delta: float) -> void:
	move_direction = _to_world(Input.get_vector("move_left", "move_right", "move_up", "move_down"))
	aim_stick = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	aim_direction = _read_aim()
	aim_point = _read_aim_point()
	# Clicking on UI (e.g. the stop panel) must not swing the weapon or place a structure.
	var over_ui := get_viewport().gui_get_hovered_control() != null
	attack_held = Input.is_action_pressed("attack") and not over_ui
	interact_held = Input.is_action_pressed("interact")
	recover_held = Input.is_action_pressed("recover")
	radial_held = Input.is_action_pressed("build")
	dash_pressed = Input.is_action_just_pressed("dash")
	place_pressed = (Input.is_action_just_pressed("attack") and not over_ui) or Input.is_action_just_pressed("interact")
	cancel_pressed = Input.is_action_just_pressed("cancel")
	build_select = _pending_select
	_pending_select = -1
	if Input.is_action_just_pressed("ready"):
		ready_requested.emit()


## Direction from the owning body to the ground point under a screen position, or ZERO.
func aim_from_screen(screen_position: Vector2) -> Vector3:
	var body := get_parent() as Node3D
	var hit: Variant = ground_point_from_screen(screen_position)
	if hit == null or body == null:
		return Vector3.ZERO
	var flat: Vector3 = hit - body.global_position
	flat.y = 0.0
	return flat.normalized() if flat.length() > 0.1 else Vector3.ZERO


## Ground point under a screen position, or null.
func ground_point_from_screen(screen_position: Vector2) -> Variant:
	var camera := get_viewport().get_camera_3d()
	var body := get_parent() as Node3D
	if camera == null or body == null:
		return null
	var ground := Plane(Vector3.UP, body.global_position.y)
	return ground.intersects_ray(camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position))


func _read_aim() -> Vector3:
	if aim_stick != Vector2.ZERO:
		return _to_world(aim_stick).normalized()
	if not _using_gamepad:
		var mouse_aim := aim_from_screen(get_viewport().get_mouse_position())
		if mouse_aim != Vector3.ZERO:
			return mouse_aim
	elif move_direction != Vector3.ZERO:
		return move_direction.normalized()
	return aim_direction


func _read_aim_point() -> Vector3:
	var body := get_parent() as Node3D
	if body == null:
		return Vector3.ZERO
	if aim_stick == Vector2.ZERO and not _using_gamepad:
		var hit: Variant = ground_point_from_screen(get_viewport().get_mouse_position())
		if hit != null:
			return hit
	return body.global_position + aim_direction * STICK_GHOST_DISTANCE


# Screen-relative stick -> world direction, so "up" always moves up the screen.
func _to_world(stick: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null or stick == Vector2.ZERO:
		return Vector3.ZERO
	var right := Vector3(camera.global_basis.x.x, 0.0, camera.global_basis.x.z).normalized()
	var forward := Vector3(-camera.global_basis.z.x, 0.0, -camera.global_basis.z.z).normalized()
	return (right * stick.x - forward * stick.y).limit_length(1.0)
