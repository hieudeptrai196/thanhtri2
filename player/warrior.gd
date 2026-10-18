class_name Warrior
extends CharacterBody3D
## On-foot warrior. Moves, faces and attacks according to its PlayerInput intent.

## Metres per second.
@export var move_speed: float = 7.0
## Higher turns faster.
@export var turn_speed: float = 18.0

@onready var input: PlayerInput = $PlayerInput
@onready var health: HealthComponent = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _weapon: MeleeWeapon = $Weapon
@onready var _swing_fx: Node3D = $SwingFx

var is_alive: bool = true

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _body_layer: int


func _ready() -> void:
	_body_layer = collision_layer
	_weapon.swung.connect(_on_swung)
	health.died.connect(_on_died)


## Brings the warrior back at full health. Who decides when and where is up to the match.
func respawn_at(spawn_position: Vector3) -> void:
	global_position = spawn_position
	health.reset()
	_set_alive(true)


func _physics_process(delta: float) -> void:
	var direction := input.move_direction
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	var aim := input.aim_direction
	var target_yaw := atan2(-aim.x, -aim.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))

	if input.attack_held:
		_weapon.try_attack(aim)

	move_and_slide()


func _on_died() -> void:
	_set_alive(false)


func _set_alive(alive: bool) -> void:
	is_alive = alive
	visible = alive
	collision_layer = _body_layer if alive else 0
	_hurtbox.set_deferred("monitorable", alive)
	set_physics_process(alive)


# Placeholder swing flash until there are real attack animations.
func _on_swung(direction: Vector3, _hit_count: int) -> void:
	_swing_fx.global_rotation.y = atan2(-direction.x, -direction.z)
	_swing_fx.visible = true
	get_tree().create_timer(0.1).timeout.connect(_swing_fx.hide)
