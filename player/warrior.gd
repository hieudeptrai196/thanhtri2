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
## Created in _ready: the active class skill.
var skills: ClassSkills
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _collision: CollisionShape3D = $Collision
@onready var _swing_fx: Node3D = $SwingFx
@onready var _carried_prop: Node3D = $CarriedProp

var is_alive: bool = true
## Folded structure on the warrior's back (null = hands free), and its health when folded.
var carried_type: StructureType = null
var carried_health: float = 0.0
## Class (role) of this warrior; null = no class (plain stats, used by tests).
var player_class: PlayerClass = null
## Folded structures this warrior can carry at once (the top one is carried_type / carried_health).
var carry_capacity: int = 1
## Class strengths read by other systems (Builder, ServiceZone).
var hammer_multiplier: float = 1.0
var repair_multiplier: float = 1.0
var _empty_speed_multiplier: float = 1.0
# Structures carried under the top one, as [type, health].
var _carried_stack: Array = []
# Stats before any class, so changing class never compounds.
var _base_max_health: float
var _base_damage: float
var _base_capacity: int
var _base_color: Color
## Multiplayer peer that controls this warrior (1 = the host, also used offline).
var peer_id: int = 1
## False on clients: the host simulates and this warrior only shows what the host sends.
var simulated: bool = true
var _net_position: Variant = null
## Swings so far and the last one's direction, so clients can show other warriors attacking.
var _swing_count: int = 0
var _swing_yaw: float = 0.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _facing: Vector3 = Vector3.FORWARD
var _attack_facing_left: float = 0.0


func _ready() -> void:
	add_to_group(&"players")
	skills = ClassSkills.new()
	skills.name = "Skills"
	add_child(skills)
	weapon.swung.connect(_on_swung)
	health.died.connect(_on_died)
	_base_max_health = health.max_health
	_base_damage = weapon.damage
	_base_capacity = inventory.capacity
	_base_color = ($Body.mesh.material as StandardMaterial3D).albedo_color


## Gives this warrior a class (null = none): its passive strengths and placeholder colour.
func apply_class(new_class: PlayerClass) -> void:
	if new_class == player_class:
		return
	player_class = new_class
	var c := new_class if new_class else PlayerClass.new()
	health.set_max_health(_base_max_health * c.max_health_multiplier)
	health.reset()
	weapon.damage = _base_damage * c.damage_multiplier
	inventory.capacity = roundi(_base_capacity * c.capacity_multiplier)
	carry_capacity = c.carry_capacity
	hammer_multiplier = c.hammer_multiplier
	repair_multiplier = c.repair_multiplier
	_empty_speed_multiplier = c.empty_speed_multiplier
	var material := StandardMaterial3D.new()
	material.albedo_color = new_class.color if new_class else _base_color
	$Body.material_override = material


## Brings the warrior back at full health. Who decides when and where is up to the match.
func respawn_at(spawn_position: Vector3) -> void:
	global_position = spawn_position
	health.reset()
	_set_alive(true)


## Puts a folded structure on top of what is carried (check can_carry_more first).
func carry(type: StructureType, health_value: float) -> void:
	if carried_type:
		_carried_stack.push_back([carried_type, carried_health])
	carried_type = type
	carried_health = health_value
	_carried_prop.visible = true


## Removes the top carried structure; the next one (if any) comes up.
func clear_carried() -> void:
	if _carried_stack.is_empty():
		carried_type = null
		_carried_prop.visible = false
		return
	var next: Array = _carried_stack.pop_back()
	carried_type = next[0]
	carried_health = next[1]


func carried_count() -> int:
	return (1 if carried_type else 0) + _carried_stack.size()


func can_carry_more() -> bool:
	return carried_count() < carry_capacity


func set_simulated(on: bool) -> void:
	simulated = on
	set_physics_process(on and is_alive)


## What clients need to draw this warrior and the HUD of its owner.
func net_state() -> Array:
	return [global_position, rotation.y, is_alive, health.current, health.max_health, inventory.amounts,
		StructureTypes.ALL.find(carried_type), _swing_count, _swing_yaw, PlayerClasses.ALL.find(player_class), carried_count(), skills.cooldown_left]


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
	skills.cooldown_left = state[11]
	var class_index: int = state[9]
	apply_class(PlayerClasses.ALL[class_index] if class_index >= 0 else null)
	# Only the top type and the count matter on clients (prop, prompts, can_carry_more).
	var carried: int = state[6]
	_carried_stack.clear()
	carried_type = StructureTypes.ALL[carried] if carried >= 0 else null
	_carried_prop.visible = carried_type != null
	for i in maxi(state[10] - 1, 0):
		_carried_stack.append([carried_type, 0.0])
	if state[7] != _swing_count:
		_swing_count = state[7]
		_flash_swing(state[8])


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
	if input.skill_pressed:
		skills.try_use()
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
		if carried_type == null and inventory.total() == 0:
			speed *= _empty_speed_multiplier
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
	_swing_count += 1
	_swing_yaw = atan2(-direction.x, -direction.z)
	_flash_swing(_swing_yaw)


func _flash_swing(yaw: float) -> void:
	_swing_fx.global_rotation.y = yaw
	_swing_fx.visible = true
	get_tree().create_timer(0.1).timeout.connect(_swing_fx.hide)
