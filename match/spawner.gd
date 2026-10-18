class_name Spawner
extends Node3D
## Spawns waves of enemies on a ring around the fortress while active. Wave timing, size, cap and
## enemy strength follow a Difficulty resource and the fortress's route distance; noise makes waves
## denser and bigger, and in pursuit they come from behind the fortress, faster and faster.
## Spawned enemies are children of this node.

signal enemy_dropped(contents: Dictionary, at: Vector3)

@export var enemy_scene: PackedScene
@export var difficulty: Difficulty
@export var ring_radius: float = 35.0
## Angle spread of one wave around its centre direction.
@export var pack_spread_degrees: float = 25.0
## In pursuit, wave centres fall within this angle of straight behind the fortress.
@export var pursuit_rear_degrees: float = 60.0

## Optional; without it noise has no effect.
var noise: NoiseMeter
## Set by the match from the current route type.
var route_rate_multiplier: float = 1.0
var route_health_multiplier: float = 1.0

var active: bool = false

var _rng: RandomNumberGenerator
var _fortress: Node3D
var _follower: RouteFollower
var _players: Array[Node3D] = []
var _time_left: float = 0.0
## Host: id for the next enemy. Client: enemies shown, by id.
var _next_net_id: int = 1
var _by_net_id: Dictionary = {}


func setup(rng: RandomNumberGenerator, fortress: Node3D, follower: RouteFollower, players: Array[Node3D]) -> void:
	_rng = rng
	_fortress = fortress
	_follower = follower
	_players = players
	_time_left = difficulty.spawn_interval(0.0)


func distance() -> float:
	return _follower.distance if _follower else 0.0


func _physics_process(delta: float) -> void:
	if not active:
		return
	_time_left -= delta
	if _time_left > 0.0:
		return
	var at := distance()
	_time_left = difficulty.spawn_interval(at) / (noise.spawn_rate_multiplier() if noise else 1.0) / route_rate_multiplier
	spawn_wave(difficulty.pack_size(at) + (noise.extra_pack_size() if noise else 0))


## Spawns up to `size` enemies around one random direction, respecting the alive cap.
func spawn_wave(size: int) -> void:
	var centre := _rng.randf() * TAU
	if noise and noise.level() == NoiseMeter.Level.PURSUIT:
		var behind := _fortress.global_basis.z
		centre = atan2(behind.z, behind.x) + deg_to_rad(_rng.randf_range(-pursuit_rear_degrees, pursuit_rear_degrees))
	for i in size:
		if alive_count() >= difficulty.max_alive(distance()):
			return
		spawn_one(centre + deg_to_rad(_rng.randf_range(-pack_spread_degrees, pack_spread_degrees)))


## Spawns one enemy on the ring (random direction unless given), scaled for the current distance.
func spawn_one(angle: float = NAN) -> Enemy:
	if is_nan(angle):
		angle = _rng.randf() * TAU
	var spawn_position := _fortress.global_position + Vector3(cos(angle), 0.0, sin(angle)) * ring_radius
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.net_id = _next_net_id
	_next_net_id += 1
	add_child(enemy)
	enemy.global_position = spawn_position
	enemy.setup(_fortress, _players)
	enemy.apply_scaling(difficulty.health_multiplier(distance()) * route_health_multiplier, difficulty.damage_multiplier(distance()),
		noise.enemy_speed_multiplier() if noise else 1.0)
	enemy.dropped.connect(enemy_dropped.emit)
	return enemy


func alive_count() -> int:
	var count := 0
	for child in get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count


## Host: every living enemy as ids + 6 floats each (x, y, z, yaw, health, max health), compact
## because there can be hundreds.
func net_state() -> Array:
	var ids := PackedInt32Array()
	var data := PackedFloat32Array()
	for enemy: Enemy in get_children():
		if enemy.is_queued_for_deletion():
			continue
		var health: HealthComponent = enemy.get_node("Health")
		ids.append(enemy.net_id)
		var at := enemy.global_position
		data.append_array([at.x, at.y, at.z, enemy.rotation.y, health.current, health.max_health])
	return [ids, data]


## Client: shows exactly the enemies in the host's snapshot (new ones appear, missing ones are gone).
func apply_net_state(state: Array) -> void:
	var ids: PackedInt32Array = state[0]
	var data: PackedFloat32Array = state[1]
	var seen := {}
	for i in ids.size():
		var id := ids[i]
		seen[id] = true
		var enemy: Enemy = _by_net_id.get(id)
		if enemy == null:
			enemy = enemy_scene.instantiate()
			enemy.net_id = id
			add_child(enemy)
			enemy.set_simulated(false)
			_by_net_id[id] = enemy
		var f := i * 6
		enemy.apply_net_state(Vector3(data[f], data[f + 1], data[f + 2]), data[f + 3], data[f + 4], data[f + 5])
	for id: int in _by_net_id.keys():
		if not seen.has(id):
			_by_net_id[id].queue_free()
			_by_net_id.erase(id)


func clear() -> void:
	for child in get_children():
		child.queue_free()
