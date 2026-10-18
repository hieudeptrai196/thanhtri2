class_name Structure
extends StaticBody3D
## A building placed in the field. It starts as a blueprint that players finish together by
## hammering (more hammers = faster), paying its cost bit by bit. Once built, it is supplied while
## near the fortress; away from it, a structure that needs power runs on its buffer.
## Recovering is shared too: every helper holding recover adds to the same progress.

signal destroyed(structure: Structure)
signal built_finished(structure: Structure)

## Set by the StructureNetwork when spawned.
var type: StructureType

@export var needs_power: bool = true
## Seconds of operation away from the fortress.
@export var buffer_seconds: float = 30.0
## Enemies within this distance turn to attack the structure.
@export var lure_radius: float = 6.0
## Seconds of hammering for one player to finish the blueprint.
@export var build_time: float = 4.0
## Team speed-up: n hammers build `n ^ team_exponent` times as fast.
@export var team_exponent: float = 0.85
## Blueprint transparency while unbuilt (0 = opaque).
@export_range(0.0, 1.0) var blueprint_transparency: float = 0.6

@onready var health: HealthComponent = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox

var built: bool = true
## Seconds of work done on the blueprint.
var build_progress: float = 0.0
## Resources already put into the blueprint, keyed by ResourceType.id.
var paid: Dictionary = {}
## True when the last hammering tick could not be paid for, and which resource ran out.
var starved: bool = false
var starved_resource: StringName = &""
var buffer: float
var powered: bool = false
## Seconds of (summed) recover holding; reset when nobody holds.
var recover_progress: float = 0.0
## Hammers / recover helpers counted this tick (for HUD).
var helpers: int = 0
## Identifies this structure between host and clients (given by the host's StructureNetwork).
var net_id: int = 0

var _hammer_purses: Array[Inventory] = []
var _hammer_weight: float = 0.0
## Multiplies how fast this structure's shooter fires (set by the match, e.g. a Thầy pháp nearby).
var fire_rate_bonus: float = 1.0
var _recover_helpers: int = 0


func _ready() -> void:
	buffer = buffer_seconds
	health.died.connect(_on_died)
	if built:
		_on_built()
	else:
		_hurtbox.monitorable = false
		_set_transparency(blueprint_transparency)


## Makes this a blueprint. Call before adding to the tree.
func start_as_blueprint() -> void:
	built = false
	build_progress = 0.0


## A player hammers this blueprint this tick; `purse` pays first, before the shared storage.
## `weight` > 1 counts as more than one hammer (a Công binh).
func add_hammer(purse: Inventory, weight: float = 1.0) -> void:
	_hammer_purses.append(purse)
	_hammer_weight += weight


## A player holds recover on this structure this tick.
func add_recover_helper() -> void:
	_recover_helpers += 1


## Off on clients: the host runs the structure; this one only shows its state.
func set_simulated(on: bool) -> void:
	set_physics_process(on)
	for shooter in find_children("*", "AutoShooter", true, false):
		shooter.set_physics_process(on)


## What clients need to draw this structure and the build / recover prompts. Index 1 is the type,
## filled in by the StructureNetwork (StructureTypes would be a cyclic reference from here).
func net_state() -> Array:
	return [net_id, -1, global_position, rotation.y, built, build_progress,
		health.current, health.max_health, buffer, powered, starved, starved_resource, recover_progress, helpers]


func apply_net_state(state: Array) -> void:
	build_progress = state[5]
	health.set_net_state(state[6], state[7], 0.0, 0.0)
	buffer = state[8]
	powered = state[9]
	starved = state[10]
	starved_resource = state[11]
	recover_progress = state[12]
	helpers = state[13]
	if state[4] and not built:
		built = true
		_on_built()


## Client: the host no longer has this structure (recovered, destroyed...). Subclasses may show why.
func on_net_removed() -> void:
	pass


func build_fraction() -> float:
	return 1.0 if built else build_progress / build_time


## Called every physics tick by the network. `in_range` = within the fortress service radius.
func supply(delta: float, in_range: bool, storage: Inventory) -> void:
	helpers = maxi(_hammer_purses.size(), _recover_helpers)
	recover_progress = recover_progress + delta * _recover_helpers if _recover_helpers > 0 else 0.0
	_recover_helpers = 0
	if not built:
		_advance_construction(delta, storage)
		return
	powered = in_range
	if not needs_power:
		return
	if in_range:
		buffer = buffer_seconds
	elif buffer > 0.0:
		buffer = maxf(buffer - delta, 0.0)
		if buffer == 0.0:
			_on_buffer_empty()


func is_running() -> bool:
	return built and (not needs_power or buffer > 0.0)


## Blueprints can always be taken down; built ones only if foldable (subclasses may refuse).
func can_recover() -> bool:
	return not built or (type != null and type.foldable)


func _advance_construction(delta: float, storage: Inventory) -> void:
	var hammers := _hammer_weight
	var purses := _hammer_purses.duplicate()
	_hammer_purses.clear()
	_hammer_weight = 0.0
	if purses.is_empty():
		return
	var target := minf(build_progress + delta * pow(hammers, team_exponent), build_time)
	starved = false
	var affordable := 1.0
	for id in type.cost:
		var total: int = type.cost[id]
		var owed: int = ceili(total * target / build_time) - paid.get(id, 0)
		while owed > 0 and _pay_one(id, purses, storage):
			owed -= 1
		if owed > 0:
			starved = true
			starved_resource = id
		affordable = minf(affordable, float(paid.get(id, 0)) / total)
	build_progress = minf(target, affordable * build_time)
	if build_progress >= build_time:
		built = true
		_on_built()
		built_finished.emit(self)


func _pay_one(id: StringName, purses: Array, storage: Inventory) -> bool:
	for purse: Inventory in purses + [storage]:
		if purse and purse.spend({id: 1}):
			paid[id] = paid.get(id, 0) + 1
			return true
	return false


func _on_built() -> void:
	add_to_group(&"structures")
	var status := get_node_or_null(^"Status") as Label3D
	if status:
		status.visible = false
	_hurtbox.monitorable = true
	_set_transparency(0.0)
	buffer = buffer_seconds


func _set_transparency(value: float) -> void:
	for mesh in find_children("*", "MeshInstance3D", true, false):
		if not mesh.top_level:
			mesh.transparency = value


# Placeholder blueprint label until there is real construction art.
func _process(_delta: float) -> void:
	var status := get_node_or_null(^"Status") as Label3D
	if status == null or built:
		return
	status.visible = true
	if starved:
		var missing := ResourceTypes.find(starved_resource)
		status.text = tr("Thiếu %s") % (tr(missing.display_name) if missing else "")
		status.modulate = Color(1.0, 0.45, 0.25)
	else:
		status.text = "%d%%" % roundi(build_fraction() * 100.0)
		status.modulate = Color(0.7, 0.9, 1.0)


func _on_buffer_empty() -> void:
	pass


func _on_died() -> void:
	destroyed.emit(self)
	queue_free()
