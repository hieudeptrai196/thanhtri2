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
@export_group("Look")
## Model for the whole structure (empty keeps the placeholder meshes).
@export_file("*.gltf", "*.glb") var model_path: String = ""
@export var model_scale: float = 1.0
@export var model_yaw_degrees: float = 0.0
## A second model hung under another node (e.g. a turret's bow, which turns to aim).
@export_file("*.gltf", "*.glb") var part_path: String = ""
@export var part_parent: NodePath
@export var part_scale: float = 1.0
@export var part_yaw_degrees: float = 0.0
## Placeholder meshes emptied once the models are in.
@export var placeholder_meshes: PackedStringArray = []

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
## Counted as paid without being spent (a Công binh building from a Tiều phu's bag); never refunded.
var bonus_paid: Dictionary = {}
## Who hammered on the tick the blueprint was finished (class combos look at it).
var finished_by: Array[Node] = []
## Permanent fire-rate multiplier of a khắc phù turret (Công binh × Thầy pháp); 1 = none.
var engrave_bonus: float = 1.0

var _hammer_purses: Array[Inventory] = []
var _hammer_weight: float = 0.0
var _hammerers: Array[Node] = []
# Teammates' bags this tick's hammerers may pay from: Inventory -> what one unit counts as.
var _shared_bags: Dictionary = {}
var _bonus_credit: Dictionary = {}
# Construction speed-up and seconds left (a Công binh's Dựng tốc).
var _build_boost: float = 1.0
var _build_boost_left: float = 0.0
## Multiplies how fast this structure's shooter fires (set by the match, e.g. a Thầy pháp nearby).
var fire_rate_bonus: float = 1.0
var _recover_helpers: int = 0


func _ready() -> void:
	_build_look()
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


## A player hammers this blueprint this tick; `purse` pays first, then `shared` bags of teammates
## nearby (a Tiều phu's), then the shared storage. `weight` > 1 counts as more than one hammer and
## each unit from a shared bag counts as `shared_value` (a Công binh).
func add_hammer(purse: Inventory, weight: float = 1.0, hammerer: Node = null, shared: Array[Inventory] = [],
		shared_value: float = 1.0) -> void:
	_hammer_purses.append(purse)
	_hammer_weight += weight
	if hammerer:
		_hammerers.append(hammerer)
	for bag in shared:
		if not _hammer_purses.has(bag):
			_shared_bags[bag] = maxf(_shared_bags.get(bag, 1.0), shared_value)


## Makes this a khắc phù structure: it fires `bonus` times as fast for as long as it stands.
func engrave(bonus: float) -> void:
	engrave_bonus = bonus
	var rune := MeshInstance3D.new()
	rune.name = "Rune"
	var mesh := SphereMesh.new()
	mesh.radius = 0.4
	mesh.height = 0.8
	mesh.radial_segments = 4
	mesh.rings = 2
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.45, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.6, 0.35, 1.0)
	mesh.material = material
	rune.mesh = mesh
	rune.position.y = 2.4  # above a turret's bow, under its status label
	add_child(rune)


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
		health.current, health.max_health, buffer, powered, starved, starved_resource, recover_progress, helpers, engrave_bonus]


func apply_net_state(state: Array) -> void:
	build_progress = state[5]
	health.set_net_state(state[6], state[7], 0.0, 0.0)
	buffer = state[8]
	powered = state[9]
	starved = state[10]
	starved_resource = state[11]
	recover_progress = state[12]
	helpers = state[13]
	if state[14] != engrave_bonus:
		engrave(state[14])
	if state[4] and not built:
		built = true
		_on_built()


## Client: the host no longer has this structure (recovered, destroyed...). Subclasses may show why.
func on_net_removed() -> void:
	pass


## Hammering this blueprint goes `multiplier` times as fast for `seconds`.
func boost_build(multiplier: float, seconds: float) -> void:
	_build_boost = multiplier
	_build_boost_left = seconds


## Repairs a built structure (a Thầy pháp's Bùa trận).
func heal(amount: float) -> void:
	if built:
		health.heal(amount)


func build_fraction() -> float:
	return 1.0 if built else build_progress / build_time


## Called every physics tick by the network. `in_range` = within the fortress service radius.
func supply(delta: float, in_range: bool, storage: Inventory) -> void:
	helpers = maxi(_hammer_purses.size(), _recover_helpers)
	_build_boost_left = maxf(_build_boost_left - delta, 0.0)
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
	var hammerers := _hammerers.duplicate()
	var shared := _shared_bags.duplicate()
	_hammer_purses.clear()
	_hammerers.clear()
	_shared_bags.clear()
	_hammer_weight = 0.0
	if purses.is_empty():
		return
	var boost := _build_boost if _build_boost_left > 0.0 else 1.0
	var target := minf(build_progress + delta * pow(hammers, team_exponent) * boost, build_time)
	starved = false
	var affordable := 1.0
	for id in type.cost:
		var total: int = type.cost[id]
		var owed: int = ceili(total * target / build_time) - _counted(id)
		while owed > 0 and _pay_one(id, purses, shared, storage):
			owed = ceili(total * target / build_time) - _counted(id)
		if owed > 0:
			starved = true
			starved_resource = id
		affordable = minf(affordable, minf(float(_counted(id)) / total, 1.0))
	build_progress = minf(target, affordable * build_time)
	if build_progress >= build_time:
		finished_by = hammerers
		built = true
		_on_built()
		built_finished.emit(self)


# Units of `id` that count towards the cost: spent ones plus bonus ones.
func _counted(id: StringName) -> int:
	return paid.get(id, 0) + bonus_paid.get(id, 0)


func _pay_one(id: StringName, purses: Array, shared: Dictionary, storage: Inventory) -> bool:
	for purse: Inventory in purses:
		if purse and purse.spend({id: 1}):
			paid[id] = paid.get(id, 0) + 1
			return true
	for bag: Inventory in shared:
		if is_instance_valid(bag) and bag.spend({id: 1}):
			paid[id] = paid.get(id, 0) + 1
			# A unit worth more than one adds up into whole bonus units.
			_bonus_credit[id] = _bonus_credit.get(id, 0.0) + shared[bag] - 1.0
			while _bonus_credit[id] >= 1.0 - 0.0001:
				_bonus_credit[id] -= 1.0
				bonus_paid[id] = bonus_paid.get(id, 0) + 1
			return true
	if storage and storage.spend({id: 1}):
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


func _build_look() -> void:
	if model_path != "":
		var model: Node3D = load(model_path).instantiate()
		model.scale = Vector3.ONE * model_scale
		model.rotation_degrees.y = model_yaw_degrees
		add_child(model)
	if part_path != "" and has_node(part_parent):
		var part: Node3D = load(part_path).instantiate()
		part.scale = Vector3.ONE * part_scale
		part.rotation_degrees.y = part_yaw_degrees
		get_node(part_parent).add_child(part)
	for mesh_name in placeholder_meshes:
		var placeholder := get_node_or_null(NodePath(mesh_name)) as MeshInstance3D
		if placeholder:
			placeholder.mesh = null


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
	Sfx.play(self, &"break", global_position)
	Burst.spawn(self, &"chips", global_position + Vector3(0.0, 1.0, 0.0))
	destroyed.emit(self)
	queue_free()
