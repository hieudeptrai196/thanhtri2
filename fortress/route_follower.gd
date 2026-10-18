class_name RouteFollower
extends Node
## Moves the parent Node3D along a Path3D, pausing at every Marker3D child of the route.

signal reached_stop(index: int)
signal departed
signal reached_end

## Metres per second at full speed.
@export var base_speed: float = 3.0
## Scales base_speed; later driven by fortress state (e.g. damage).
@export_range(0.0, 2.0, 0.05) var speed_multiplier: float = 1.0

var progress: float = 0.0
var is_stopped: bool = false
var is_finished: bool = false

var _route: Path3D
var _body: Node3D
var _stop_offsets: Array[float] = []
var _next_stop: int = 0


func start(route: Path3D) -> void:
	assert(route.curve != null, "RouteFollower: route has no curve")
	_route = route
	_body = get_parent() as Node3D
	for child in route.get_children():
		if child is Marker3D:
			_stop_offsets.append(route.curve.get_closest_offset(route.to_local(child.global_position)))
	_stop_offsets.sort()
	_apply_transform()


func depart() -> void:
	if is_stopped:
		is_stopped = false
		departed.emit()


func _physics_process(delta: float) -> void:
	if _route == null or is_stopped or is_finished:
		return

	progress += base_speed * speed_multiplier * delta

	if _next_stop < _stop_offsets.size() and progress >= _stop_offsets[_next_stop]:
		progress = _stop_offsets[_next_stop]
		is_stopped = true
		_apply_transform()
		reached_stop.emit(_next_stop)
		_next_stop += 1
		return

	var length := _route.curve.get_baked_length()
	if progress >= length:
		progress = length
		is_finished = true
		_apply_transform()
		reached_end.emit()
		return

	_apply_transform()


func _apply_transform() -> void:
	_body.global_transform = _route.global_transform * _route.curve.sample_baked_with_rotation(progress)
