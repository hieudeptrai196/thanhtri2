class_name Warrior
extends CharacterBody3D
## On-foot warrior. Moves and dashes according to its PlayerInput intent; the basic attack is
## automatic (enemies first, then trees/rocks), with the aim direction only prioritising targets.
## Can carry one folded structure: slower, no attacks while carrying.

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
		if carried_type == null:
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
	set_physics_process(alive)


# Placeholder swing flash until there are real attack animations.
func _on_swung(direction: Vector3, _hit_count: int) -> void:
	_swing_fx.global_rotation.y = atan2(-direction.x, -direction.z)
	_swing_fx.visible = true
	get_tree().create_timer(0.1).timeout.connect(_swing_fx.hide)
