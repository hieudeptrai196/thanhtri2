class_name Warrior
extends CharacterBody3D
## On-foot warrior. Moves, faces and attacks according to its PlayerInput intent.

## Metres per second.
@export var move_speed: float = 7.0
## Higher turns faster.
@export var turn_speed: float = 18.0

@onready var input: PlayerInput = $PlayerInput
@onready var _weapon: MeleeWeapon = $Weapon
@onready var _swing_fx: Node3D = $SwingFx

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	_weapon.swung.connect(_on_swung)


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


# Placeholder swing flash until there are real attack animations.
func _on_swung(direction: Vector3, _hit_count: int) -> void:
	_swing_fx.global_rotation.y = atan2(-direction.x, -direction.z)
	_swing_fx.visible = true
	get_tree().create_timer(0.1).timeout.connect(_swing_fx.hide)
