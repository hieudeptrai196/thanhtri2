class_name RouteContent
extends Node3D
## Places the visible road strip, trees, coal deposits, hidden bombs and stop markers along each new road
## segment, and frees them once they fall far behind the fortress. Uses its own seeded RNG so the same seed always
## gives the same layout, independent of gameplay timing.

signal bomb_exploded(at: Vector3)
## Host side, for clients: a tree / deposit lost a unit, a bomb went off. Content is identified by
## the order it was placed in, which is the same on every machine for the same seed and routes.
signal resource_gathered(amount_left: int, content_id: int)
signal bomb_triggered(at: Vector3, content_id: int)

const TREE_SCENE := preload("res://resources/tree.tscn")
const COAL_SCENE := preload("res://resources/coal_deposit.tscn")
const BOMB_SCENE := preload("res://world/hidden_bomb.tscn")
const STOP_MARKER_SCENE := preload("res://world/stop_marker.tscn")

## No content before this distance, so the start area stays clear.
@export var clear_start: float = 30.0
## Content this far behind the fortress is freed.
@export var despawn_behind: float = 90.0
## Half the road width that stays free of trees and coal deposits.
@export var road_half_width: float = 8.0
@export var trees_per_segment: Vector2i = Vector2i(0, 2)
@export var tree_band: Vector2 = Vector2(9.0, 22.0)
@export_range(0.0, 1.0) var coal_chance: float = 0.3
@export var coal_band: Vector2 = Vector2(20.0, 40.0)
## Chance per segment; ~1 bomb every 300 m at 20 m segments.
@export_range(0.0, 1.0) var bomb_chance: float = 0.07
## Bombs keep this far from stops (both sides).
@export var bomb_stop_margin: float = 40.0
## Width of the drawn dirt road (the fortress is 10 m wide).
@export var road_visual_width: float = 12.0
@export var road_color: Color = Color(0.33, 0.26, 0.19)
@export_group("Scenery")
## Decoration only (no collision, no gameplay): far woods / hills, near rocks and camp props.
@export var far_band: Vector2 = Vector2(26.0, 60.0)
@export var near_band: Vector2 = Vector2(10.0, 24.0)
@export var far_per_side: Vector2i = Vector2i(2, 4)
@export var near_per_side: Vector2i = Vector2i(1, 2)

const KIT := "res://assets/kaykit/"
## [piece (under KIT), scale, weight] for the far and near bands; route types shift the weights
## (trees by tree_multiplier, rock-like pieces by coal_multiplier). A cursed, war-torn land.
const FAR_PIECES := [["halloween/tree_dead_large.gltf", 1.3, 3], ["halloween/tree_dead_large_decorated.gltf", 1.3, 1],
	["halloween/tree_pine_orange_large.gltf", 1.0, 2], ["halloween/tree_pine_yellow_medium.gltf", 1.1, 2],
	["medieval/hills_A_trees.gltf", 4.0, 1.5], ["medieval/mountain_A_grass_trees.gltf", 5.0, 0.8],
	["halloween/crypt.gltf", 0.9, 0.25]]
const NEAR_PIECES := [["halloween/tree_dead_medium.gltf", 1.1, 2], ["halloween/tree_dead_small.gltf", 1.2, 2],
	["halloween/gravestone.gltf", 0.9, 1.2], ["halloween/grave_A_destroyed.gltf", 0.8, 0.8],
	["halloween/gravemarker_A.gltf", 1.0, 1], ["halloween/skull.gltf", 0.6, 0.8], ["halloween/ribcage.gltf", 0.9, 0.6],
	["halloween/bone_C.gltf", 1.0, 0.8], ["halloween/fence_broken.gltf", 1.0, 1], ["halloween/post_skull.gltf", 0.9, 0.5],
	["halloween/post_lantern.gltf", 0.9, 0.5], ["dungeon/rubble_half.glb", 0.6, 0.6],
	["dungeon/barrel_large.glb", 0.5, 0.4], ["dungeon/sword_shield_broken.glb", 0.8, 0.4],
	["medieval/rock_single_A.gltf", 6.0, 1], ["medieval/rock_single_B.gltf", 6.0, 1]]
## Pieces that carry a warm light (lanterns, torches): [piece, light height].
const LIT_PIECES := {"halloween/post_lantern.gltf": 3.4, "dungeon/torch_lit.glb": 1.2}

var _route: EndlessRoute
var _rng: RandomNumberGenerator
## [node, route distance] for everything spawned, oldest first.
var _spawned: Array = []
var _next_stop_index: int = 0
var _road_material: StandardMaterial3D
## Random roadside content is only placed up to this distance (the next stop, until a route is
## picked there); later segments wait their turn. INF = no limit.
var content_limit: float = INF
## The stretch being generated (null = neutral, no modifiers).
var route_type: RouteType = null
## [from, to] segments waiting for `content_limit` to move past them, in order.
var _pending: Array = []
var _next_content_id: int = 1
var _by_content_id: Dictionary = {}
# Scenery has its own random stream (seeded from the run and the segment), so adding or changing
# it never shifts where trees, coal and bombs go.
var _scenery_seed: int = 0
static var _kit_cache: Dictionary = {}


func setup(route: EndlessRoute, rng: RandomNumberGenerator) -> void:
	_route = route
	_rng = rng
	_scenery_seed = rng.seed
	_road_material = StandardMaterial3D.new()
	_road_material.albedo_color = road_color
	_road_material.roughness = 1.0
	route.segment_added.connect(_on_segment_added)


## Frees content that lies `despawn_behind` metres behind `distance`.
func despawn_before(distance: float) -> void:
	while not _spawned.is_empty() and _spawned[0][1] < distance - despawn_behind:
		# Entries may already be gone (exploded bomb, chopped tree), so check before typing.
		var entry: Array = _spawned.pop_front()
		_by_content_id.erase(entry[2])
		if is_instance_valid(entry[0]):
			entry[0].queue_free()


## Puts a hidden bomb in the middle of the road at `distance`.
func place_bomb(distance: float) -> HiddenBomb:
	var bomb: HiddenBomb = BOMB_SCENE.instantiate()
	bomb.exploded.connect(bomb_exploded.emit)
	_place(bomb, distance, 0.0)
	return bomb


## Raises the content limit and places any waiting segments now inside it.
func set_content_limit(limit: float) -> void:
	content_limit = limit
	while not _pending.is_empty() and _pending[0][0] < content_limit:
		var segment: Array = _pending.pop_front()
		_place_random_content(segment[0], segment[1])


## Client: a tree / deposit on the host has `amount` left.
func apply_resource_amount(content_id: int, amount: int) -> void:
	var node: Variant = _by_content_id.get(content_id)
	if is_instance_valid(node) and node is ResourceNode:
		node.set_net_amount(amount)


## Client: the host's copy of this bomb exploded.
func explode_bomb(content_id: int) -> void:
	var node: Variant = _by_content_id.get(content_id)
	if is_instance_valid(node) and node is HiddenBomb:
		node.explode_from_host()


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
	_add_scenery(from_distance, to_distance)
	while _route.stop_distance(_next_stop_index) <= to_distance:
		_place(STOP_MARKER_SCENE.instantiate(), _route.stop_distance(_next_stop_index), 0.0)
		_add_stop_camp(_route.stop_distance(_next_stop_index))
		_next_stop_index += 1
	_spawned.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
	if from_distance >= content_limit or not _pending.is_empty():
		_pending.append([from_distance, to_distance])
	else:
		_place_random_content(from_distance, to_distance)


# Trees, coal and bombs for one segment, scaled by the current route type.
func _place_random_content(from_distance: float, to_distance: float) -> void:
	if to_distance <= clear_start:
		return
	var start := maxf(from_distance, clear_start)
	var trees := _rng.randi_range(trees_per_segment.x, trees_per_segment.y)
	for i in floori(trees * (route_type.tree_multiplier if route_type else 1.0) + _rng.randf()):
		_place(TREE_SCENE.instantiate(), _rng.randf_range(start, to_distance), _random_side(tree_band))
	if _rng.randf() < coal_chance * (route_type.coal_multiplier if route_type else 1.0):
		_place(COAL_SCENE.instantiate(), _rng.randf_range(start, to_distance), _random_side(coal_band))
	if _rng.randf() < bomb_chance * (route_type.bomb_multiplier if route_type else 1.0):
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
	_spawned.append([strip, to_distance, 0])


func _add_scenery(from_distance: float, to_distance: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([_scenery_seed, roundi(from_distance * 10.0)])
	var trees := route_type.tree_multiplier if route_type else 1.0
	var rocks := route_type.coal_multiplier if route_type else 1.0
	for side in [-1.0, 1.0]:
		for i in rng.randi_range(far_per_side.x, far_per_side.y):
			_add_decor(_pick(FAR_PIECES, rng, trees, rocks), rng, rng.randf_range(from_distance, to_distance),
				side * rng.randf_range(far_band.x, far_band.y))
		if from_distance < clear_start:
			continue
		for i in rng.randi_range(near_per_side.x, near_per_side.y):
			_add_decor(_pick(NEAR_PIECES, rng, trees, rocks), rng, rng.randf_range(from_distance, to_distance),
				side * rng.randf_range(near_band.x, near_band.y))


# Flags along the safe zone and a small camp beside the road at a stop.
func _add_stop_camp(at: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([_scenery_seed, "camp", roundi(at)])
	for offset in [-8.0, 8.0]:
		for side in [-1.0, 1.0]:
			_add_decor(["dungeon/torch_lit.glb", 1.6, 1], rng, at + offset, side * 9.0, false)
	for side in [-1.0, 1.0]:
		_add_decor(["dungeon/banner_patternA_red.glb", 0.9, 1], rng, at, side * 9.5, false)
		_add_decor(["medieval/tent.gltf", 5.0, 1], rng, at + rng.randf_range(-6.0, 6.0), side * 14.0)
		_add_decor(["dungeon/crates_stacked.glb", 0.6, 1], rng, at + rng.randf_range(-6.0, 6.0), side * 12.0)


func _pick(pieces: Array, rng: RandomNumberGenerator, trees: float, rocks: float) -> Array:
	var weights := PackedFloat32Array()
	for piece: Array in pieces:
		var name: String = piece[0]
		var weight: float = piece[2]
		if name.contains("tree"):
			weight *= trees
		elif name.contains("rock") or name.contains("mountain") or name.contains("rubble"):
			weight *= rocks
		weights.append(weight)
	return pieces[rng.rand_weighted(weights)]


func _add_decor(piece: Array, rng: RandomNumberGenerator, distance: float, lateral: float, random_yaw: bool = true) -> void:
	var path: String = KIT + piece[0]
	if not _kit_cache.has(path):
		_kit_cache[path] = load(path)
	var node: Node3D = _kit_cache[path].instantiate()
	node.add_to_group(&"scenery")
	var road := _route.sample(distance)
	add_child(node)
	node.scale = Vector3.ONE * piece[1] * rng.randf_range(0.85, 1.15)
	node.global_position = road.origin + road.basis.x.normalized() * lateral
	node.rotation.y = rng.randf() * TAU if random_yaw else road.basis.get_euler().y
	node.reset_physics_interpolation()
	if LIT_PIECES.has(piece[0]):
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.62, 0.3)
		light.light_energy = 2.2
		light.omni_range = 8.0
		light.position.y = LIT_PIECES[piece[0]]
		node.add_child(light)
	_spawned.append([node, distance, 0])


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
	node.reset_physics_interpolation()
	node.rotation.y = _rng.randf() * TAU if node is ResourceNode else road.basis.get_euler().y
	var id := _next_content_id
	_next_content_id += 1
	_by_content_id[id] = node
	if node is ResourceNode:
		node.gathered.connect(resource_gathered.emit.bind(id))
	elif node is HiddenBomb:
		node.exploded.connect(bomb_triggered.emit.bind(id))
	_spawned.append([node, distance, id])
	_spawned.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
