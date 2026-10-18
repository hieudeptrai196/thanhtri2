class_name Warrior
extends CharacterBody3D
## On-foot warrior. Moves and dashes according to its PlayerInput intent; the basic attack is
## automatic (enemies first, then trees/coal deposits), with the aim direction only prioritising targets.
## Can carry one folded structure: slower, no attacks while carrying (or while hammering).

## Metres per second.
@export var move_speed: float = 7.0
@export var carry_speed: float = 5.0
## Higher turns faster.
@export var turn_speed: float = 18.0
@export var dash_distance: float = 4.5
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 1.2
## Seconds the warrior keeps facing what it just hit before turning back to its movement.
@export var attack_facing_time: float = 0.35
## Online, on clients: how quickly a warrior glides to the position the host last sent.
@export var net_smoothing: float = 15.0

@onready var input: PlayerInput = $PlayerInput
@onready var health: HealthComponent = $Health
@onready var inventory: Inventory = $Inventory
@onready var weapon: MeleeWeapon = $Weapon
@onready var builder: Builder = $Builder
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _collision: CollisionShape3D = $Collision
@onready var _swing_fx: Node3D = $SwingFx
@onready var _carried_prop: Node3D = $CarriedProp

var is_alive: bool = true
## Folded structure on the warrior's back (null = hands free), and its health when folded.
var carried_type: StructureType = null
var carried_health: float = 0.0
## Multiplayer peer that controls this warrior (1 = the host, also used offline).
var peer_id: int = 1
## False on clients: the host simulates and this warrior only shows what the host sends.
var simulated: bool = true
var _net_position: Variant = null

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _facing: Vector3 = Vector3.FORWARD
var _attack_facing_left: float = 0.0


func _ready() -> void:
	weapon.swung.connect(_on_swung)
	health.died.connect(_on_died)


## Brings the warrior back at full health. Who decides when and where is up to the match.
func respawn_at(spawn_position: Vector3) -> void:
	global_position = spawn_position
	health.reset()
	_set_alive(true)


func carry(type: StructureType, health_value: float) -> void:
	carried_type = type
	carried_health = health_value
	_carried_prop.visible = true


func clear_carried() -> void:
	carried_type = null
	_carried_prop.visible = false


func set_simulated(on: bool) -> void:
	simulated = on
	set_physics_process(on and is_alive)


## What clients need to draw this warrior and the HUD of its owner.
func net_state() -> Array:
	return [global_position, rotation.y, is_alive, health.current, health.max_health, inventory.amounts,
		StructureTypes.ALL.find(carried_type)]


func apply_net_state(state: Array) -> void:
	var target: Vector3 = state[0]
	# Respawns and first sightings jump; normal movement glides (see _process).
	if _net_position == null or global_position.distance_to(target) > 5.0:
		global_position = target
	_net_position = target
	rotation.y = state[1]
	if state[2] != is_alive:
		_set_alive(state[2])
	health.set_net_state(state[3], state[4], 0.0, 0.0)
	inventory.set_net_amounts(state[5])
	var carried: int = state[6]
	if carried < 0 and carried_type:
		clear_carried()
	elif carried >= 0 and carried_type != StructureTypes.ALL[carried]:
		carry(StructureTypes.ALL[carried], 0.0)


func _process(delta: float) -> void:
	if not simulated and _net_position != null:
		global_position = global_position.lerp(_net_position, 1.0 - exp(-net_smoothing * delta))


func is_dashing() -> bool:
	return _dash_time_left > 0.0


func _physics_process(delta: float) -> void:
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_attack_facing_left = maxf(_attack_facing_left - delta, 0.0)
	# On a gamepad the dash button also cancels building; cancelling must not dash.
	var cancelling := builder.is_placing() and input.cancel_pressed
	if input.dash_pressed and not cancelling and _dash_cooldown_left == 0.0 and not is_dashing():
		_start_dash()

	var direction := input.move_direction
	if is_dashing():
		_dash_time_left -= delta
		var dash_speed := dash_distance / dash_duration
		velocity.x = _dash_direction.x * dash_speed
		velocity.z = _dash_direction.z * dash_speed
		if not is_dashing():
			_hurtbox.set_deferred("monitorable", true)
	else:
		var speed := carry_speed if carried_type else move_speed
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if carried_type == null and builder.hammer_target == null:
			_auto_attack()
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta

	if _attack_facing_left == 0.0 and direction != Vector3.ZERO:
		_facing = direction.normalized()
	rotation.y = lerp_angle(rotation.y, atan2(-_facing.x, -_facing.z), 1.0 - exp(-turn_speed * delta))
	move_and_slide()


func _auto_attack() -> void:
	if not weapon.is_ready():
		return
	var target := weapon.pick_target(input.aim_direction)
	if target == null:
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() > 0.01:
		_facing = to_target.normalized()
	_attack_facing_left = attack_facing_time
	weapon.try_attack(_facing)


# Short burst along the movement (or facing) direction; the warrior cannot be hit meanwhile.
func _start_dash() -> void:
	_dash_direction = input.move_direction.normalized() if input.move_direction != Vector3.ZERO else _facing
	_dash_time_left = dash_duration
	_dash_cooldown_left = dash_cooldown
	_hurtbox.set_deferred("monitorable", false)


func _on_died() -> void:
	_set_alive(false)


func _set_alive(alive: bool) -> void:
	is_alive = alive
	visible = alive
	_dash_time_left = 0.0
	_collision.set_deferred("disabled", not alive)
	_hurtbox.set_deferred("monitorable", alive)
	set_physics_process(alive and simulated)


# Placeholder swing flash until there are real attack animations.
func _on_swung(direction: Vector3, _hit_count: int) -> void:
	_swing_fx.global_rotation.y = atan2(-direction.x, -direction.z)
	_swing_fx.visible = true
	get_tree().create_timer(0.1).timeout.connect(_swing_fx.hide)
