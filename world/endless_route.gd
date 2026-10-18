class_name EndlessRoute
extends Path3D
## Endless winding road. Grows in fixed-length segments ahead of the fortress and drops the part
## left behind. Positions are addressed by total route distance (metres from the start), which
## never changes when old segments are dropped. Same RNG seed → same road.

## Emitted for every new segment so content can be placed along [from_distance, to_distance].
signal segment_added(from_distance: float, to_distance: float)

@export var segment_length: float = 20.0
## Max heading change per segment.
@export var max_turn_degrees: float = 14.0
## Max angle away from the overall forward direction (-Z); keeps the road from turning back.
@export var max_heading_degrees: float = 55.0
## Road kept generated ahead of the requested distance.
@export var look_ahead: float = 160.0
## Road kept behind the requested distance before old segments are dropped.
@export var keep_behind: float = 60.0
@export var first_stop: float = 350.0
@export var stop_interval: float = 350.0

## Route distance at the curve's first point (grows as old segments are dropped).
var base_distance: float = 0.0

var _rng: RandomNumberGenerator
var _heading: float = 0.0
## Route distance of every curve point, parallel to the curve's point list.
var _point_distances: Array[float] = []


func setup(rng: RandomNumberGenerator) -> void:
	_rng = rng
	curve = Curve3D.new()
	curve.add_point(Vector3.ZERO, Vector3.ZERO, _direction() * segment_length / 3.0)
	_point_distances = [0.0]
	base_distance = 0.0
	ensure_ahead(0.0)


## Generates road up to `distance + look_ahead` and drops what lies beyond `keep_behind`.
func ensure_ahead(distance: float) -> void:
	while generated_to() < distance + look_ahead:
		_add_segment()
	_trim_behind(distance)


func generated_to() -> float:
	return _point_distances[-1]


## World transform on the road at `distance`; -Z points along the road.
func sample(distance: float) -> Transform3D:
	var offset := clampf(distance - base_distance, 0.0, curve.get_baked_length())
	return global_transform * curve.sample_baked_with_rotation(offset)


func position_at(distance: float) -> Vector3:
	return sample(distance).origin


func stop_distance(index: int) -> float:
	return first_stop + index * stop_interval


func _direction() -> Vector3:
	return Vector3(-sin(_heading), 0.0, -cos(_heading))


func _add_segment() -> void:
	var max_turn := deg_to_rad(max_turn_degrees)
	var max_heading := deg_to_rad(max_heading_degrees)
	_heading = clampf(_heading + _rng.randf_range(-max_turn, max_turn), -max_heading, max_heading)
	var direction := _direction()
	var handle := direction * segment_length / 3.0
	var from := generated_to()
	var last := curve.point_count - 1
	curve.add_point(curve.get_point_position(last) + direction * segment_length, -handle, handle)
	_point_distances.append(base_distance + curve.get_baked_length())
	segment_added.emit(from, generated_to())


func _trim_behind(distance: float) -> void:
	while curve.point_count > 2 and _point_distances[1] < distance - keep_behind:
		curve.remove_point(0)
		_point_distances.remove_at(0)
		base_distance = _point_distances[0]
