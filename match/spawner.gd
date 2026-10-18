class_name Spawner
extends Node3D
## Spawns enemies at a fixed interval on a ring around the fortress while active.
## Spawned enemies are children of this node.

signal enemy_dropped(contents: Dictionary, at: Vector3)

@export var enemy_scene: PackedScene
## Seconds between spawns.
@export var interval: float = 3.0
@export var ring_radius: float = 35.0
@export var max_alive: int = 30

var active: bool = false

var _rng: RandomNumberGenerator
var _fortress: Node3D
var _players: Array[Node3D] = []
var _time_left: float = 0.0


func setup(rng: RandomNumberGenerator, fortress: Node3D, players: Array[Node3D]) -> void:
	_rng = rng
	_fortress = fortress
	_players = players
	_time_left = interval


func _physics_process(delta: float) -> void:
	if not active:
		return
	_time_left -= delta
	if _time_left > 0.0:
		return
	_time_left = interval
	if alive_count() < max_alive:
		spawn_one()


func spawn_one() -> Enemy:
	var angle := _rng.randf() * TAU
	var spawn_position := _fortress.global_position + Vector3(cos(angle), 0.0, sin(angle)) * ring_radius
	var enemy: Enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = spawn_position
	enemy.setup(_fortress, _players)
	enemy.dropped.connect(enemy_dropped.emit)
	return enemy


func alive_count() -> int:
	var count := 0
	for child in get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count


func clear() -> void:
	for child in get_children():
		child.queue_free()
