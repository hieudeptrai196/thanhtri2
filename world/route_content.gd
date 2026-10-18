class_name RouteContent
extends Node3D
## Places the visible road strip, trees, rocks, hidden bombs and stop markers along each new road
## segment, and frees them once they fall far behind the fortress. Uses its own seeded RNG so the same seed always
## gives the same layout, independent of gameplay timing.

signal bomb_exploded(at: Vector3)

const TREE_SCENE := preload("res://resources/tree.tscn")
const ROCK_SCENE := preload("res://resources/rock.tscn")
const BOMB_SCENE := preload("res://world/hidden_bomb.tscn")
const STOP_MARKER_SCENE := preload("res://world/stop_marker.tscn")

## No content before this distance, so the start area stays clear.
@export var clear_start: float = 30.0
## Content this far behind the fortress is freed.
@export var despawn_behind: float = 90.0
## Half the road width that stays free of trees and rocks.
@export var road_half_width: float = 8.0
@export var trees_per_segment: Vector2i = Vector2i(0, 2)
@export var tree_band: Vector2 = Vector2(9.0, 22.0)
@export_range(0.0, 1.0) var rock_chance: float = 0.3
@export var rock_band: Vector2 = Vector2(20.0, 40.0)
## Chance per segment; ~1 bomb every 300 m at 20 m segments.
@export_range(0.0, 1.0) var bomb_chance: float = 0.07
## Bombs keep this far from stops (both sides).
@export var bomb_stop_margin: float = 40.0
## Width of the drawn dirt road (the fortress is 10 m wide).
@export var road_visual_width: float = 12.0
@export var road_color: Color = Color(0.55, 0.45, 0.3)

var _route: EndlessRoute
var _rng: RandomNumberGenerator
## [node, route distance] for everything spawned, oldest first.
var _spawned: Array = []
var _next_stop_index: int = 0
var _road_material: StandardMaterial3D


func setup(route: EndlessRoute, rng: RandomNumberGenerator) -> void:
	_route = route
	_rng = rng
	_road_material = StandardMaterial3D.new()
	_road_material.albedo_color = road_color
	_road_material.roughness = 1.0
	route.segment_added.connect(_on_segment_added)


## Frees content that lies `despawn_behind` metres behind `distance`.
func despawn_before(distance: float) -> void:
	while not _spawned.is_empty() and _spawned[0][1] < distance - despawn_behind:
		# Entries may already be gone (exploded bomb, chopped tree), so check before typing.
		var node: Variant = _spawned.pop_front()[0]
		if is_instance_valid(node):
			node.queue_free()


## Puts a hidden bomb in the middle of the road at `distance`.
func place_bomb(distance: float) -> HiddenBomb:
	var bomb: HiddenBomb = BOMB_SCENE.instantiate()
	bomb.exploded.connect(bomb_exploded.emit)
	_place(bomb, distance, 0.0)
	return bomb


func bombs() -> Array[HiddenBomb]:
	var result: Array[HiddenBomb] = []
	for entry in _spawned:
		if is_instance_valid(entry[0]) and entry[0] is HiddenBomb:
			result.append(entry[0])
	return result


func resource_nodes(id: StringName) -> Array[ResourceNode]:
	var result: Array[ResourceNode] = []
	for entry in _spawned:
		if is_instance_valid(entry[0]) and entry[0] is ResourceNode and entry[0].resource_type.id == id:
			result.append(entry[0])
	return result


func _on_segment_added(from_distance: float, to_distance: float) -> void:
	_add_road_strip(from_distance, to_distance)
	while _route.stop_distance(_next_stop_index) <= to_distance:
		_place(STOP_MARKER_SCENE.instantiate(), _route.stop_distance(_next_stop_index), 0.0)
		_next_stop_index += 1
	if to_distance <= clear_start:
		return
	var start := maxf(from_distance, clear_start)
	for i in _rng.randi_range(trees_per_segment.x, trees_per_segment.y):
		_place(TREE_SCENE.instantiate(), _rng.randf_range(start, to_distance), _random_side(tree_band))
	if _rng.randf() < rock_chance:
		_place(ROCK_SCENE.instantiate(), _rng.randf_range(start, to_distance), _random_side(rock_band))
	if _rng.randf() < bomb_chance:
		var at := _rng.randf_range(start, to_distance)
		if not _near_stop(at):
			place_bomb(at)


# Flat dirt strip following the curve, built in world space; despawned with the content behind it.
func _add_road_strip(from_distance: float, to_distance: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3.UP)
	var steps := maxi(ceili((to_distance - from_distance) / 2.0), 1)
	var previous: Array[Vector3] = []
	for i in steps + 1:
		var road := _route.sample(lerpf(from_distance, to_distance, float(i) / steps))
		var side := road.basis.x.normalized() * road_visual_width * 0.5
		var lift := Vector3(0.0, 0.03, 0.0)
		var current: Array[Vector3] = [road.origin - side + lift, road.origin + side + lift]
		if not previous.is_empty():
			for vertex in [previous[0], current[0], previous[1], previous[1], current[0], current[1]]:
				surface.add_vertex(vertex)
		previous = current
	var strip := MeshInstance3D.new()
	strip.mesh = surface.commit()
	strip.material_override = _road_material
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(strip)
	_spawned.append([strip, to_distance])


func _random_side(band: Vector2) -> float:
	var offset := _rng.randf_range(maxf(band.x, road_half_width), band.y)
	return offset if _rng.randf() < 0.5 else -offset


func _near_stop(at: float) -> bool:
	var index := roundi((at - _route.first_stop) / _route.stop_interval)
	return absf(at - _route.stop_distance(maxi(index, 0))) < bomb_stop_margin


# `lateral` is metres to the right (+) or left (-) of the road centre at `distance`.
func _place(node: Node3D, distance: float, lateral: float) -> void:
	var road := _route.sample(distance)
	add_child(node)
	node.global_position = road.origin + road.basis.x.normalized() * lateral
	node.rotation.y = _rng.randf() * TAU if node is ResourceNode else road.basis.get_euler().y
	_spawned.append([node, distance])
	_spawned.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
