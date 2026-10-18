class_name Enemy
extends CharacterBody3D
## Basic melee monster. Walks toward the fortress, but turns on a structure within that structure's
## lure radius or a living player who comes close, and hits its current target once that target's
## Hurtbox is inside the attack area.

## Emitted on death with what it leaves behind; whoever owns the world spawns the pickup.
signal dropped(contents: Dictionary, at: Vector3)

## Metres per second.
@export var move_speed: float = 3.5
## A living player closer than this becomes the target instead of the fortress.
@export var aggro_radius: float = 8.0
@export var damage: float = 5.0
## Seconds between hits.
@export var attack_interval: float = 1.0
## Resources left behind on death, keyed by ResourceType.id.
@export var drops: Dictionary = {&"bronze": 1}
## Online, on clients: how quickly the enemy glides to the position the host last sent.
@export var net_smoothing: float = 12.0

@onready var _health: HealthComponent = $Health
@onready var _attack_area: Area3D = $AttackArea
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _collision: CollisionShape3D = $Collision
@onready var _material: StandardMaterial3D = $Body.mesh.material

var _fortress: Node3D
var _players: Array[Node3D] = []
var _cooldown: float = 0.0
var _base_color: Color
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## Identifies this enemy between host and clients (given by the host's Spawner).
var net_id: int = 0
var _net_position: Variant = null


func setup(fortress: Node3D, players: Array[Node3D]) -> void:
	_fortress = fortress
	_players = players


## Makes this enemy tougher for the current difficulty. Call right after it enters the tree.
func apply_scaling(health_multiplier: float, damage_multiplier: float, speed_multiplier: float = 1.0) -> void:
	move_speed *= speed_multiplier
	_health.set_max_health(_health.max_health * health_multiplier)
	_health.reset()
	damage *= damage_multiplier


func _ready() -> void:
	add_to_group(&"enemies")
	_base_color = _material.albedo_color
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	set_process(false)  # only clients glide (see set_simulated)


## Off on clients: the host moves and fights; this enemy only shows where it is. No physics either.
func set_simulated(on: bool) -> void:
	set_physics_process(on)
	set_process(not on)
	_collision.disabled = not on
	_attack_area.monitoring = on
	_hurtbox.monitoring = on
	_hurtbox.monitorable = on


func apply_net_state(at: Vector3, yaw: float, current: float, maximum: float) -> void:
	if _net_position == null:
		global_position = at
	_net_position = at
	rotation.y = yaw
	_health.set_net_state(current, maximum, 0.0, 0.0)


func _process(delta: float) -> void:
	if _net_position != null:
		global_position = global_position.lerp(_net_position, 1.0 - exp(-net_smoothing * delta))


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	var target := _pick_target()
	velocity.x = 0.0
	velocity.z = 0.0

	if target != null:
		var to_target := target.global_position - global_position
		to_target.y = 0.0
		if to_target.length() > 0.01:
			rotation.y = atan2(-to_target.x, -to_target.z)
		var hurtbox := _hurtbox_in_reach(target)
		if hurtbox != null:
			if _cooldown == 0.0:
				_cooldown = attack_interval
				hurtbox.take_hit(damage, self)
		else:
			var direction := to_target.normalized()
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed

	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()


# Players are duck-typed: anything with `is_alive` and a Hurtbox child can be chased.
# Structures (group "structures") win over players and the fortress inside their lure radius.
func _pick_target() -> Node3D:
	var best: Node3D = _fortress
	var best_distance := aggro_radius
	var best_lure := INF
	for structure: Structure in get_tree().get_nodes_in_group(&"structures"):
		if structure.is_queued_for_deletion():
			continue
		var distance := global_position.distance_to(structure.global_position)
		if distance <= structure.lure_radius and distance < best_lure:
			best = structure
			best_lure = distance
	if best != _fortress:
		return best  # a luring structure beats chasing players
	for player in _players:
		if not is_instance_valid(player) or not player.get("is_alive"):
			continue
		var distance := global_position.distance_to(player.global_position)
		if distance <= best_distance:
			best = player
			best_distance = distance
	return best


func _hurtbox_in_reach(target: Node3D) -> Hurtbox:
	for area in _attack_area.get_overlapping_areas():
		if area is Hurtbox and area.owner == target:
			return area
	return null


func _on_died() -> void:
	dropped.emit(drops.duplicate(), global_position)
	queue_free()


func _on_health_changed(_current: float, _maximum: float) -> void:
	_material.albedo_color = Color.WHITE
	create_tween().tween_property(_material, "albedo_color", _base_color, 0.15)
