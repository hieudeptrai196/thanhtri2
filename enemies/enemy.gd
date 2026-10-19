class_name Enemy
extends CharacterBody3D
## Basic melee monster. Walks toward the fortress, but turns on a structure within that structure's
## lure radius or a living player who comes close, and hits its current target once that target's
## Hurtbox is inside the attack area.

## Emitted on death with what it leaves behind; whoever owns the world spawns the pickup.
signal dropped(contents: Dictionary, at: Vector3)
## Dies from `killer`'s hit (a warrior, a structure, the fortress… or null).
signal slain(killer: Node)

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

## Looks, picked by net_id so every machine shows the same one: [model, accessories].
const VARIANTS := [
	["res://assets/kaykit/skeletons/Skeleton_Minion.glb", []],
	["res://assets/kaykit/skeletons/Skeleton_Minion.glb", []],
	["res://assets/kaykit/skeletons/Skeleton_Warrior.glb", ["Skeleton_Warrior_Helmet"]],
]  # no hooded / hatted skeletons: they read like the Thầy pháp or Thợ máy players
const MODEL_SCALE := 0.75
## Ground speed at which the run clip plays at normal speed.
const RUN_CLIP_SPEED := 4.0
## Seconds a fallen enemy's body stays before vanishing.
const CORPSE_SECONDS := 1.4

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
var _model: CharacterModel
var _flash: StandardMaterial3D
var _last_visual_position: Vector3
var _visual_speed: float = 0.0
var _running: bool = false
var _net_position: Variant = null
# Forced target and seconds left (a Võ tướng's Hét trận); speed factor and seconds left (Bùa trận).
var _taunt_target: Node3D = null
var _taunt_left: float = 0.0
var _slow: float = 1.0
var _slow_left: float = 0.0
var _exposed_left: float = 0.0


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
	_build_look()
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	set_process(false)  # only clients glide (see set_simulated)


## Off on clients: the host moves and fights; this enemy only shows where it is. No physics either.
func set_simulated(on: bool) -> void:
	set_physics_process(on)
	# Clients glide in _process, so physics-tick interpolation would fight it.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_INHERIT if on else Node.PHYSICS_INTERPOLATION_MODE_OFF
	set_process(not on)
	_collision.disabled = not on
	_attack_area.monitoring = on
	_hurtbox.monitoring = on
	_hurtbox.monitorable = on


## Makes this enemy go for `target` for `seconds`, whatever else is around.
func taunt(target: Node3D, seconds: float) -> void:
	_taunt_target = target
	_taunt_left = seconds


func is_taunted() -> bool:
	return _taunt_left > 0.0 and is_instance_valid(_taunt_target)


## Takes `multiplier` times the damage for `seconds` (renewed while the cause lasts).
func expose(multiplier: float, seconds: float) -> void:
	_health.damage_taken_multiplier = multiplier
	_exposed_left = seconds


## Moves at `factor` of its speed for `seconds` (renewed while it stays in a slowing area).
func slow(factor: float, seconds: float) -> void:
	_slow = factor
	_slow_left = seconds


func apply_net_state(at: Vector3, yaw: float, current: float, maximum: float) -> void:
	if _net_position == null:
		global_position = at
	_net_position = at
	rotation.y = yaw
	_health.set_net_state(current, maximum, 0.0, 0.0)


func _process(delta: float) -> void:
	if _net_position != null:
		global_position = global_position.lerp(_net_position, 1.0 - exp(-net_smoothing * delta))
	_animate(delta)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_taunt_left = maxf(_taunt_left - delta, 0.0)
	_slow_left = maxf(_slow_left - delta, 0.0)
	if _exposed_left > 0.0:
		_exposed_left -= delta
		if _exposed_left <= 0.0:
			_health.damage_taken_multiplier = 1.0
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
				if _model:
					_model.play(&"Unarmed_Melee_Attack_Punch_A", 1.6, 0.05, true)
		else:
			var direction := to_target.normalized()
			var speed := move_speed * (_slow if _slow_left > 0.0 else 1.0)
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed

	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()
	_animate(delta)


# Players are duck-typed: anything with `is_alive` and a Hurtbox child can be chased.
# Structures (group "structures") win over players and the fortress inside their lure radius.
func _pick_target() -> Node3D:
	if _taunt_left > 0.0 and is_instance_valid(_taunt_target) and _taunt_target.get("is_alive") != false:
		return _taunt_target
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
		# Someone up on the fortress crossbow is out of reach; the enemy goes for the walls instead.
		if not is_instance_valid(player) or not player.get("is_alive") or player.get("manning"):
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
	slain.emit(_health.last_source if is_instance_valid(_health.last_source) else null)
	dropped.emit(drops.duplicate(), global_position)
	_leave_corpse.call_deferred()
	queue_free()


func _on_health_changed(_current: float, _maximum: float) -> void:
	_material.albedo_color = Color.WHITE
	create_tween().tween_property(_material, "albedo_color", _base_color, 0.15)
	Sfx.play(self, &"enemy_die" if _current <= 0.0 else &"hit", global_position)
	Burst.spawn(self, &"bone" if _current <= 0.0 else &"spark", global_position + Vector3(0.0, 1.0, 0.0))
	if _model == null or _current <= 0.0:
		return
	# White flash over the model, only while it lasts (an overlay costs a draw per mesh).
	_set_overlay(_flash)
	_flash.albedo_color.a = 0.7
	var tween := create_tween()
	tween.tween_property(_flash, "albedo_color:a", 0.0, 0.15)
	tween.tween_callback(_set_overlay.bind(null))
	if not _model.is_busy():
		_model.play(&"Hit_A", 1.8, 0.05, true)


func _build_look() -> void:
	var variant: Array = VARIANTS[net_id % VARIANTS.size()]
	_model = CharacterModel.new()
	_model.name = "Model"
	add_child(_model)
	_model.setup(load(variant[0]), MODEL_SCALE, PackedStringArray(variant[1]), null, Color.WHITE, false, true)
	_model.set_crowd(1, net_id)
	_flash = StandardMaterial3D.new()
	_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash.albedo_color = Color(1, 1, 1, 0)
	$Body.visible = false
	$Eyes.visible = false
	_model.play(&"Idle")


func _set_overlay(material: Material) -> void:
	if not is_instance_valid(_model):
		return
	for mesh: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		mesh.material_overlay = material


# Host moves by velocity, clients by glide: either way, animate from how far the body moved.
func _animate(delta: float) -> void:
	# The bigger the crowd, the less often each one's animation steps.
	if _model and Engine.get_physics_frames() % 30 == net_id % 30:
		_model.set_crowd(1 + get_tree().get_nodes_in_group(&"enemies").size() / 70, net_id)
	var moved := global_position - _last_visual_position
	_last_visual_position = global_position
	# Host: real velocity. Clients: smoothed glide distance, with hysteresis (see Warrior).
	var raw := Vector2(velocity.x, velocity.z).length() if is_physics_processing() \
		else Vector2(moved.x, moved.z).length() / maxf(delta, 0.0001)
	if raw > 40.0:
		raw = 0.0
	_visual_speed = raw if is_physics_processing() else lerpf(_visual_speed, raw, 1.0 - exp(-10.0 * delta))
	_running = _visual_speed > (0.3 if _running else 0.8)
	if _model == null or _model.is_busy():
		return
	if _running:
		_model.play(&"Running_A", clampf(_visual_speed / RUN_CLIP_SPEED, 0.6, 1.6))
	else:
		_model.play(&"Idle_Combat")


# The body falls over where the enemy died, then goes; the enemy itself is gone at once.
func _leave_corpse() -> void:
	var world := get_parent().get_parent() if get_parent() and get_parent().get_parent() else null
	if world == null or not is_instance_valid(_model) or not world.is_inside_tree():
		return
	var corpse := Node3D.new()
	corpse.name = "Corpse"
	world.add_child(corpse)
	corpse.global_transform = global_transform
	corpse.reset_physics_interpolation()
	_model.reparent(corpse, false)
	_model.play(&"Death_A", 1.3, 0.05, true)
	corpse.get_tree().create_timer(CORPSE_SECONDS).timeout.connect(corpse.queue_free)
