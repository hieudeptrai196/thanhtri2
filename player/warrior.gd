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
## Co-op: at 0 health the warrior lies downed this long, waiting for a teammate, before falling.
@export var bleed_out_time: float = 15.0
## Seconds of one teammate holding interact to get a downed warrior up (more helpers are faster).
@export var revive_time: float = 3.0
@export_range(0.05, 1.0) var revive_health_ratio: float = 0.4
## Online, on clients: how quickly a warrior glides to the position the host last sent.
@export var net_smoothing: float = 15.0

## Look without a class (and in tests): the KayKit knight.
const DEFAULT_MODEL := "res://assets/kaykit/adventurers/Knight.glb"
const DEFAULT_PARTS: PackedStringArray = ["1H_Sword", "Round_Shield", "Knight_Helmet", "Knight_Cape"]
const MODEL_SCALE := 0.75
## Ground speed at which the run clip plays at normal speed.
const RUN_CLIP_SPEED := 5.5

## Out of the fight for real (solo: at 0 health; co-op: after lying downed unrevived). The match then
## drops what was carried and schedules the respawn.
signal fell

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
## Set by the match while there are teammates: 0 health downs the warrior instead of felling it.
var downed_enabled: bool = false
var downed: bool = false
## Seconds before a downed warrior falls, and revive progress (seconds of helping).
var downed_left: float = 0.0
var revive_progress: float = 0.0
var _revivers: float = 0.0
var _down_label: Label3D
## On the fortress crossbow (synced to clients for prompts and build mode); the seat it stands on is host-only.
var manning: bool = false
var _seat: Node3D = null
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
## Class combos (see PlayerClass): teammates building nearby may use this bag; what a shared unit counts as.
var bag_share_radius: float = 0.0
var shared_bag_value: float = 1.0
var _empty_speed_multiplier: float = 1.0
# Structures carried under the top one, as [type, health].
var _carried_stack: Array = []
# Stats before any class, so changing class never compounds.
var _base_max_health: float
var _base_damage: float
var _base_capacity: int
var _base_color: Color
var _body_height: float
## Multiplayer peer that controls this warrior (1 = the host, also used offline).
var peer_id: int = 1
## False on clients: the host simulates and this warrior only shows what the host sends.
var simulated: bool = true
var _net_position: Variant = null
## Swings so far and the last one's direction, so clients can show other warriors attacking.
var _swing_count: int = 0
var _swing_yaw: float = 0.0
# Rigged model, the class-coloured ring under the feet, and where the model was last frame (to
# animate movement the same way on the host and on clients).
var _model: CharacterModel
var _ring_material: StandardMaterial3D
var _last_visual_position: Vector3
var _visual_speed: float = 0.0
var _running: bool = false

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
	_down_label = Label3D.new()
	_down_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_down_label.no_depth_test = true
	_down_label.font_size = 64
	_down_label.pixel_size = 0.012
	_down_label.outline_size = 16
	_down_label.position = Vector3(0.0, 1.8, 0.0)
	_down_label.visible = false
	add_child(_down_label)
	weapon.swung.connect(_on_swung)
	health.died.connect(_on_died)
	_base_max_health = health.max_health
	_base_damage = weapon.damage
	_base_capacity = inventory.capacity
	_base_color = ($Body.mesh.material as StandardMaterial3D).albedo_color
	_body_height = $Body.position.y
	_build_look()
	skills.used.connect(func(_id: StringName, _at: Vector3) -> void: _play_skill_clip())


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
	bag_share_radius = c.bag_share_radius
	shared_bag_value = c.shared_bag_value
	_empty_speed_multiplier = c.empty_speed_multiplier
	var material := StandardMaterial3D.new()
	material.albedo_color = new_class.color if new_class else _base_color
	$Body.material_override = material
	_apply_look(new_class)


## Placeholder colour of this warrior (its class colour), also used for its pings.
func display_color() -> Color:
	return player_class.color if player_class else _base_color


## Brings the warrior back at full health. Who decides when and where is up to the match.
func respawn_at(spawn_position: Vector3) -> void:
	global_position = spawn_position
	reset_physics_interpolation()
	health.reset()
	_set_downed(false)
	_set_alive(true)


## Host: stands on `seat` (on top of the fortress) and aims the crossbow; no moving or attacking meanwhile.
func man_crossbow(seat: Node3D) -> void:
	_seat = seat
	manning = true
	_dash_time_left = 0.0
	_collision.set_deferred("disabled", true)
	global_position = seat.global_position
	reset_physics_interpolation()


## Host: climbs back down to `ground_point`.
func leave_crossbow(ground_point: Vector3) -> void:
	_seat = null
	manning = false
	global_position = ground_point
	reset_physics_interpolation()
	velocity = Vector3.ZERO
	_collision.set_deferred("disabled", not is_alive)


## A teammate holds interact next to this downed warrior this tick (`weight` > 1 counts for more).
func add_reviver(weight: float = 1.0) -> void:
	_revivers += weight


## Host, every tick while downed: helpers raise the revive progress (and pause the bleed-out);
## alone, the warrior bleeds out and falls.
func tick_downed(delta: float) -> void:
	if not downed:
		return
	if _revivers > 0.0:
		revive_progress += delta * pow(_revivers, 0.85)
		_revivers = 0.0
		if revive_progress >= revive_time:
			_set_downed(false)
			health.revive(revive_health_ratio)
			_set_alive(true)
		return
	downed_left -= delta
	if downed_left <= 0.0:
		_set_downed(false)
		visible = false
		fell.emit()


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
	# Clients glide in _process, so physics-tick interpolation would fight it.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_INHERIT if on else Node.PHYSICS_INTERPOLATION_MODE_OFF
	set_physics_process(on and is_alive)


## What clients need to draw this warrior and the HUD of its owner.
func net_state() -> Array:
	return [global_position, rotation.y, is_alive, health.current, health.max_health, inventory.amounts,
		StructureTypes.ALL.find(carried_type), _swing_count, _swing_yaw, PlayerClasses.ALL.find(player_class), carried_count(), skills.cooldown_left,
		downed, downed_left, revive_progress, manning]


func apply_net_state(state: Array) -> void:
	var target: Vector3 = state[0]
	# Respawns and first sightings jump; normal movement glides (see _process).
	if _net_position == null or global_position.distance_to(target) > 5.0:
		global_position = target
	_net_position = target
	rotation.y = state[1]
	if state[2] != is_alive:
		_set_alive(state[2])
	downed_left = state[13]
	revive_progress = state[14]
	if state[12] != downed:
		_set_downed(state[12])
	manning = state[15]
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
	if downed:
		_down_label.text = tr("Đỡ dậy %d%%") % roundi(revive_progress / revive_time * 100.0) if revive_progress > 0.0 \
			else tr("Gục — %ds") % ceili(downed_left)
		_down_label.modulate = Color(0.6, 1.0, 0.6) if revive_progress > 0.0 else Color(1.0, 0.5, 0.4)
	if not simulated and _net_position != null:
		global_position = global_position.lerp(_net_position, 1.0 - exp(-net_smoothing * delta))
	_update_animation(delta)


func is_dashing() -> bool:
	return _dash_time_left > 0.0


func _physics_process(delta: float) -> void:
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_attack_facing_left = maxf(_attack_facing_left - delta, 0.0)
	# On a gamepad the dash button also cancels building; cancelling must not dash.
	var cancelling := builder.is_placing() and input.cancel_pressed
	if input.skill_pressed:
		skills.try_use()
	if _seat:
		_tick_manning(delta)
		return
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


# Rides the seat as the fortress moves and faces where the crossbow aims.
func _tick_manning(delta: float) -> void:
	global_position = _seat.global_position
	velocity = Vector3.ZERO
	if input.aim_direction != Vector3.ZERO:
		_facing = input.aim_direction
	rotation.y = lerp_angle(rotation.y, atan2(-_facing.x, -_facing.z), 1.0 - exp(-turn_speed * delta))


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
	if _model:
		_model.play(&"Dodge_Forward", 2.2, 0.03, true)


func _on_died() -> void:
	_set_alive(false)
	if downed_enabled:
		downed_left = bleed_out_time
		revive_progress = 0.0
		_set_downed(true)
	else:
		fell.emit()


# Downed: lying on the ground, still visible, enemies ignore it (is_alive is false meanwhile).
func _set_downed(on: bool) -> void:
	downed = on
	if on:
		visible = true
	$Body.rotation_degrees.x = 90.0 if on else 0.0
	$Body.position.y = 0.35 if on else _body_height
	$Nose.visible = not on and _model == null
	_down_label.visible = on
	if _model:
		_model.play(&"Lie_Down" if on else &"Lie_StandUp", 1.0, 0.1, true)


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
	Sfx.play(self, &"swing", global_position)
	if _model:
		var clip := player_class.attack_clip if player_class else &"1H_Melee_Attack_Slice_Diagonal"
		_model.play(clip, maxf(_model.clip_length(clip) / (weapon.cooldown * 0.9), 1.0), 0.05, true)


func _build_look() -> void:
	_model = CharacterModel.new()
	_model.name = "Model"
	add_child(_model)
	var ring := MeshInstance3D.new()
	ring.name = "ClassRing"
	var disc := TorusMesh.new()
	disc.inner_radius = 0.5
	disc.outer_radius = 0.65
	disc.rings = 24
	_ring_material = StandardMaterial3D.new()
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc.material = _ring_material
	ring.mesh = disc
	ring.scale = Vector3(1.0, 0.15, 1.0)
	ring.position.y = 0.05
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	# A small warm glow so every player stays readable at night.
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = Color(1.0, 0.78, 0.55)
	glow.light_energy = 1.8
	glow.omni_range = 5.5
	glow.position.y = 2.2
	add_child(glow)
	_apply_look(null)


# The class's model and accessories (the knight without a class) and its colour on the ring and cape.
func _apply_look(look_class: PlayerClass) -> void:
	var has_model := look_class != null and look_class.model_path != ""
	var weapon: PackedScene = load(look_class.weapon_path) if has_model and look_class.weapon_path != "" else null
	var color := look_class.color if look_class else _base_color
	_model.setup(load(look_class.model_path if has_model else DEFAULT_MODEL), MODEL_SCALE,
		look_class.model_parts if has_model else DEFAULT_PARTS, weapon, color.lightened(0.15))
	_ring_material.albedo_color = Color(color, 0.75)
	$Body.visible = false
	$Nose.visible = false


func _play_skill_clip() -> void:
	if _model and player_class:
		_model.play(player_class.skill_clip, 1.4, 0.08, true)


# Runs on every machine. The host knows the real velocity; clients only see positions, and with the
# screen refreshing faster than physics (120 Hz vs 60 Hz) a raw per-frame distance flickers between
# moving and still, so it is smoothed and the run / idle switch has hysteresis.
func _update_animation(delta: float) -> void:
	var moved := global_position - _last_visual_position
	_last_visual_position = global_position
	var raw := Vector2(velocity.x, velocity.z).length() if simulated and not is_dashing() \
		else Vector2(moved.x, moved.z).length() / maxf(delta, 0.0001)
	if raw > 40.0:
		raw = 0.0  # a teleport (respawn, climbing the ladder), not movement
	_visual_speed = lerpf(_visual_speed, raw, 1.0 - exp(-12.0 * delta)) if not simulated else raw
	_running = _visual_speed > (0.5 if _running else 1.2)
	if _model == null or not visible:
		return
	if downed:
		if not _model.is_busy():
			_model.play(&"Lie_Idle")
		return
	if manning:
		_model.play(&"2H_Ranged_Aiming")
		return
	if _model.is_busy():
		return
	if _running:
		_model.play(&"Running_B" if carried_type else &"Running_A", clampf(_visual_speed / RUN_CLIP_SPEED, 0.7, 1.6))
	elif builder.hammer_target:
		_model.play(&"Interact", 1.3)
	else:
		_model.play(&"Idle")
