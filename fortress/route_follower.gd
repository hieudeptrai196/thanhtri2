class_name RouteFollower
extends Node
## Moves the parent Node3D along an EndlessRoute, pausing at every stop the route defines.
## `distance` is the total route distance travelled (the run's score).

signal reached_stop(index: int)
signal departed

## Metres per second at full speed.
@export var base_speed: float = 3.0
## Scales base_speed; driven by fortress state (e.g. damage).
@export_range(0.0, 2.0, 0.05) var speed_multiplier: float = 1.0

var distance: float = 0.0
var is_stopped: bool = false

var _route: EndlessRoute
var _body: Node3D
var _next_stop: int = 0


func start(route: EndlessRoute) -> void:
	_route = route
	_body = get_parent() as Node3D
	_apply_transform()


func depart() -> void:
	if is_stopped:
		is_stopped = false
		departed.emit()


func next_stop_distance() -> float:
	return _route.stop_distance(_next_stop)


func previous_stop_distance() -> float:
	return _route.stop_distance(_next_stop - 1) if _next_stop > 0 else 0.0


func _physics_process(delta: float) -> void:
	if _route == null or is_stopped:
		return
	distance += base_speed * speed_multiplier * delta
	var stop := next_stop_distance()
	if distance >= stop:
		distance = stop
		is_stopped = true
		_apply_transform()
		reached_stop.emit(_next_stop)
		_next_stop += 1
		return
	_apply_transform()


func _apply_transform() -> void:
	_route.ensure_ahead(distance)
	_body.global_transform = _route.sample(distance)
