class_name StructureNetwork
extends Node3D
## Owns every placed structure (they are its children, in world space — never children of the
## fortress). Supplies those within the fortress service radius each tick and holds the placement
## rules. Who may place or recover is decided by the match.

enum Placement { VALID, UNPOWERED, BLOCKED }

## Structures this close to the fortress (XZ) are supplied.
@export var service_radius: float = 12.0
## Structures must keep this far from the road centre (the fortress needs the road).
@export var road_half_width: float = 8.0
## Physics layers that block placement (trees, rocks, fortress, other structures).
@export_flags_3d_physics var blocking_layers: int = 1

var _fortress: Node3D
var _route: EndlessRoute
var _storage: Inventory


func setup(fortress: Node3D, route: EndlessRoute, storage: Inventory) -> void:
	_fortress = fortress
	_route = route
	_storage = storage


func _physics_process(delta: float) -> void:
	for structure in structures():
		structure.supply(delta, is_in_service(structure.global_position), _storage)


func structures() -> Array[Structure]:
	var result: Array[Structure] = []
	for child in get_children():
		if child is Structure and not child.is_queued_for_deletion():
			result.append(child)
	return result


func is_in_service(point: Vector3) -> bool:
	return Vector2(point.x - _fortress.global_position.x, point.z - _fortress.global_position.z).length() <= service_radius


func check_placement(type: StructureType, point: Vector3) -> Placement:
	if _distance_to_road(point) < road_half_width + type.footprint_radius:
		return Placement.BLOCKED
	if _overlaps_obstacle(point, type.footprint_radius):
		return Placement.BLOCKED
	return Placement.VALID if is_in_service(point) else Placement.UNPOWERED


## Spawns a finished structure. `health_value` >= 0 restores a recovered structure's health.
func place(type: StructureType, point: Vector3, health_value: float = -1.0) -> Structure:
	return _spawn(type, point, health_value, false)


## Spawns a blueprint that players build together; its cost is paid while hammering.
func place_blueprint(type: StructureType, point: Vector3) -> Structure:
	return _spawn(type, point, -1.0, true)


## Nearest unfinished blueprint within `max_distance` of `point`, or null.
func nearest_blueprint(point: Vector3, max_distance: float) -> Structure:
	var best: Structure = null
	var best_distance := max_distance
	for structure in structures():
		var distance := Vector2(point.x - structure.global_position.x, point.z - structure.global_position.z).length()
		if not structure.built and distance <= best_distance:
			best = structure
			best_distance = distance
	return best


## Takes down an unfinished blueprint and returns what was put into it to the shared storage.
func dismantle(structure: Structure) -> void:
	_storage.add_all(structure.paid)
	remove_child(structure)
	structure.queue_free()


func _spawn(type: StructureType, point: Vector3, health_value: float, as_blueprint: bool) -> Structure:
	var structure: Structure = type.scene.instantiate()
	structure.type = type
	if as_blueprint:
		structure.start_as_blueprint()
	add_child(structure)
	structure.global_position = Vector3(point.x, 0.0, point.z)
	if health_value >= 0.0:
		structure.health.apply_damage(structure.health.max_health - health_value)
	return structure


## Nearest structure that can be recovered within `max_distance` of `point`, or null.
func nearest_recoverable(point: Vector3, max_distance: float) -> Structure:
	var best: Structure = null
	var best_distance := max_distance
	for structure in structures():
		var distance := Vector2(point.x - structure.global_position.x, point.z - structure.global_position.z).length()
		if structure.can_recover() and distance <= best_distance:
			best = structure
			best_distance = distance
	return best


## Removes a structure and returns what is needed to place it again: { type, health }.
func recover(structure: Structure) -> Dictionary:
	var data := {"type": structure.type, "health": structure.health.current}
	remove_child(structure)
	structure.queue_free()
	return data


func _distance_to_road(point: Vector3) -> float:
	var closest := _route.to_global(_route.curve.get_closest_point(_route.to_local(point)))
	return Vector2(point.x - closest.x, point.z - closest.z).length()


func _overlaps_obstacle(point: Vector3, radius: float) -> bool:
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 2.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	# Lifted clear of the ground body so only things standing on it count.
	query.transform = Transform3D(Basis.IDENTITY, Vector3(point.x, 1.2, point.z))
	query.collision_mask = blocking_layers
	return not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
