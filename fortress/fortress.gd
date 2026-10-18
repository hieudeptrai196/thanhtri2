class_name Fortress
extends AnimatableBody3D
## The moving citadel. Burns coal from its storage to move (overdrive burns more for speed; with no
## coal it crawls) and slows down as it loses health; repaired with resources from its storage;
## upgraded through its body material tier. Starts with some resources in its storage.
## Defends itself a little: a weak crossbow on top hits enemies right at its walls, and thorns hurt
## whatever strikes it. Upgrades bought at stops (FortressUpgrades) strengthen the crossbow and add
## boiling oil, a coal furnace and a regenerating shield. Holding the line is still the job of field
## structures and players.

## Body material levels in order; the fortress starts at the first.
const TIERS: Array[FortressTier] = [
	preload("res://fortress/tiers/wood.tres"),
	preload("res://fortress/tiers/stone.tres"),
]

enum SpeedMode { MARCH, OVERDRIVE, OUT_OF_FUEL }

## Speed fraction at 0 HP, so the fortress never stops completely.
@export_range(0.0, 1.0, 0.05) var min_speed_ratio: float = 0.4
@export var repair_resource: ResourceType
## Health restored per unit of repair_resource.
@export var repair_per_unit: float = 10.0
## Seconds between repair steps while someone keeps repairing.
@export var repair_interval: float = 0.2
## Damage reflected to an enemy each time it hits the fortress.
@export var thorns_damage: float = 3.0
## Put into the storage at the start of a run, keyed by ResourceType.id.
@export var starting_resources: Dictionary = {&"wood": 30, &"coal": 15}
@export var fuel_resource: ResourceType
## Fuel units burned per second while marching / in overdrive.
@export var fuel_per_second: float = 0.125
@export var overdrive_fuel_per_second: float = 0.6
## Speed multipliers per mode (combined with the health multiplier).
@export var overdrive_speed: float = 1.6
@export var out_of_fuel_speed: float = 0.35
@export_group("Upgrades")
## Crossbow damage / seconds between shots / range per level (index 0 = base).
@export var crossbow_damage_levels: Array[float] = [6.0, 9.0, 12.0, 15.0]
@export var crossbow_interval_levels: Array[float] = [1.2, 1.0, 0.85, 0.7]
@export var crossbow_range_levels: Array[float] = [10.5, 12.0, 13.5, 15.0]
@export var oil_damage: float = 40.0
## Oil pours each time health drops past another step of this fraction.
@export var oil_step: float = 0.2
@export var furnace_damage: float = 15.0
@export var furnace_interval: float = 2.0
@export var furnace_noise: float = 2.0
@export var shield_levels: Array[float] = [0.0, 100.0, 200.0]
@export var shield_regen_per_second: float = 15.0
@export var shield_regen_delay: float = 4.0

@onready var health: HealthComponent = $Health
@onready var follower: RouteFollower = $RouteFollower
@onready var storage: Inventory = $Storage
@onready var service_zone: ServiceZone = $ServiceZone
@onready var crossbow: AutoShooter = $Crossbow
@onready var divine_crossbow: DivineCrossbow = $DivineCrossbow
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _defense_area: Area3D = $DefenseArea
@onready var _modules: Node3D = $Modules
@onready var _body_mesh: MeshInstance3D = $Body

var tier_index: int = 0
## Players toggle this; it only applies while there is fuel.
var overdrive: bool = false
var speed_mode: SpeedMode = SpeedMode.MARCH
## Bought level per FortressUpgrade id (missing = 0).
var upgrade_levels: Dictionary = {}
## Team bonuses from classes (a Thợ máy in the team): overdrive fuel use and upgrade prices.
var overdrive_fuel_multiplier: float = 1.0
var upgrade_cost_multiplier: float = 1.0

var _repair_cooldown: float = 0.0
## Fuel burned but not yet taken out of storage (whole units are taken).
var _fuel_owed: float = 0.0
var _oil_step_reached: int = 0
var _furnace_cooldown: float = 0.0
var _since_hit: float = 0.0


func _ready() -> void:
	health.health_changed.connect(func(_current: float, _maximum: float) -> void: _update_speed())
	_apply_tier(TIERS[tier_index])
	storage.add_all(starting_resources)
	_hurtbox.hit_taken.connect(_on_hit_taken)
	health.health_changed.connect(_check_boiling_oil)
	_apply_upgrades()


func _physics_process(delta: float) -> void:
	_repair_cooldown = maxf(_repair_cooldown - delta, 0.0)
	_burn_fuel(delta)
	_update_speed()
	_tick_furnace(delta)
	_tick_shield(delta)


func fuel_left() -> int:
	return storage.get_amount(fuel_resource.id)


## Seconds of marching left at the current burn rate.
func fuel_seconds_left() -> float:
	var rate := overdrive_fuel_per_second * overdrive_fuel_multiplier if overdrive else fuel_per_second
	return (fuel_left() - _fuel_owed) / rate


func _burn_fuel(delta: float) -> void:
	if follower.is_stopped:
		return
	_fuel_owed += (overdrive_fuel_per_second * overdrive_fuel_multiplier if overdrive else fuel_per_second) * delta
	while _fuel_owed >= 1.0 and storage.spend({fuel_resource.id: 1}):
		_fuel_owed -= 1.0
	# Out of fuel once a whole unit is owed and none is left; refuelling clears it next tick.
	if _fuel_owed >= 1.0:
		speed_mode = SpeedMode.OUT_OF_FUEL
		_fuel_owed = 1.0
	else:
		speed_mode = SpeedMode.OVERDRIVE if overdrive else SpeedMode.MARCH


func _update_speed() -> void:
	var health_factor := lerpf(min_speed_ratio, 1.0, health.get_ratio())
	var mode_factor := 1.0
	match speed_mode:
		SpeedMode.OVERDRIVE:
			mode_factor = overdrive_speed
		SpeedMode.OUT_OF_FUEL:
			mode_factor = out_of_fuel_speed
	follower.speed_multiplier = health_factor * mode_factor


func get_tier() -> FortressTier:
	return TIERS[tier_index]


## The tier an upgrade would reach, or null at the top.
func get_next_tier() -> FortressTier:
	return TIERS[tier_index + 1] if tier_index + 1 < TIERS.size() else null


func upgrade_tier() -> bool:
	var next := get_next_tier()
	if next == null or not storage.spend(tier_cost(next)):
		return false
	tier_index += 1
	_apply_tier(next)
	return true


## What clients need to draw the fortress and its HUD.
func net_state() -> Dictionary:
	return {"follow": follower.net_state(), "hp": [health.current, health.max_health, health.shield, health.max_shield],
		"storage": storage.amounts, "overdrive": overdrive, "mode": speed_mode, "tier": tier_index,
		"upgrades": upgrade_levels, "divine": divine_crossbow.charge, "speed": follower.speed_multiplier,
		"prices": upgrade_cost_multiplier}


func apply_net_state(state: Dictionary) -> void:
	var follow: Array = state.follow
	follower.set_net_state(follow[0], follow[1], follow[2])
	follower.speed_multiplier = state.speed
	var hp: Array = state.hp
	health.set_net_state(hp[0], hp[1], hp[2], hp[3])
	storage.set_net_amounts(state.storage)
	overdrive = state.overdrive
	speed_mode = state.mode
	upgrade_cost_multiplier = state.prices
	if state.tier != tier_index or state.upgrades != upgrade_levels:
		tier_index = state.tier
		upgrade_levels = state.upgrades.duplicate()
		var material := StandardMaterial3D.new()
		material.albedo_color = get_tier().color
		_body_mesh.material_override = material
		for module in _modules.get_children():
			module.visible = upgrade_level(StringName(module.name.to_snake_case())) > 0
	if state.divine != divine_crossbow.charge:
		divine_crossbow.charge = state.divine
		divine_crossbow.charge_changed.emit(divine_crossbow.charge, divine_crossbow.max_charge)


func upgrade_level(id: StringName) -> int:
	return upgrade_levels.get(id, 0)


## Cost of the next level of `upgrade`, or empty when maxed.
func next_upgrade_cost(upgrade: FortressUpgrade) -> Dictionary:
	var level := upgrade_level(upgrade.id)
	return _scaled_cost(upgrade.costs[level]) if level < upgrade.max_level() else {}


## What `tier` costs this team (after class discounts).
func tier_cost(tier: FortressTier) -> Dictionary:
	return _scaled_cost(tier.cost)


func _scaled_cost(cost: Dictionary) -> Dictionary:
	if upgrade_cost_multiplier == 1.0:
		return cost
	var scaled := {}
	for id in cost:
		scaled[id] = maxi(ceili(cost[id] * upgrade_cost_multiplier), 1)
	return scaled


func buy_upgrade(upgrade: FortressUpgrade) -> bool:
	var cost := next_upgrade_cost(upgrade)
	if cost.is_empty() or not storage.spend(cost):
		return false
	upgrade_levels[upgrade.id] = upgrade_level(upgrade.id) + 1
	_apply_upgrades()
	return true


## Called every tick while at least one player repairs; spends one unit per step.
## `rate` > 1 repairs faster (shorter wait between units).
func tick_repair(_delta: float, rate: float = 1.0) -> void:
	if _repair_cooldown > 0.0 or health.current >= health.max_health:
		return
	_repair_cooldown = repair_interval / rate
	if storage.spend({repair_resource.id: 1}):
		health.heal(repair_per_unit)


func _apply_tier(tier: FortressTier) -> void:
	health.set_max_health(tier.max_health)
	var material := StandardMaterial3D.new()
	material.albedo_color = tier.color
	_body_mesh.material_override = material


func _apply_upgrades() -> void:
	var level := upgrade_level(&"crossbow")
	crossbow.damage = crossbow_damage_levels[level]
	crossbow.interval = crossbow_interval_levels[level]
	crossbow.set_range(crossbow_range_levels[level])
	health.set_max_shield(shield_levels[upgrade_level(&"shield")])
	# Placeholder modules on the hull show what has been bought.
	for module in _modules.get_children():
		module.visible = upgrade_level(StringName(module.name.to_snake_case())) > 0
	if upgrade_level(&"shield") > 0 and health.shield == 0.0:
		health.restore_shield(health.max_shield)  # a new shield starts full


func _damage_around(amount: float) -> int:
	var hit := 0
	for area in _defense_area.get_overlapping_areas():
		if area is Hurtbox:
			area.take_hit(amount, self)
			hit += 1
	return hit


# Boiling oil pours once each time health falls past another `oil_step` of the maximum.
func _check_boiling_oil(current: float, maximum: float) -> void:
	var step := floori((1.0 - current / maximum) / oil_step + 0.0001)
	if step > _oil_step_reached and upgrade_level(&"boiling_oil") > 0:
		_damage_around.call_deferred(oil_damage)
	# Repairs lower the step again, so the oil is ready for the next drop.
	_oil_step_reached = step


# The furnace burns one coal per burst, and only fires when an enemy is at the walls.
func _tick_furnace(delta: float) -> void:
	_furnace_cooldown = maxf(_furnace_cooldown - delta, 0.0)
	if upgrade_level(&"furnace") == 0 or _furnace_cooldown > 0.0:
		return
	if not _defense_area.get_overlapping_areas().any(func(a: Area3D) -> bool: return a is Hurtbox):
		return
	if storage.spend({fuel_resource.id: 1}):
		_furnace_cooldown = furnace_interval
		_damage_around(furnace_damage)
		get_tree().call_group(&"noise", &"add", furnace_noise)


func _tick_shield(delta: float) -> void:
	_since_hit += delta
	if _since_hit >= shield_regen_delay:
		health.restore_shield(shield_regen_per_second * delta)
	$Modules/Shield.visible = health.shield > 0.0


# Thorns: an attacker with a Hurtbox of its own takes a little damage back (bombs have none).
func _on_hit_taken(_amount: float, source: Node) -> void:
	_since_hit = 0.0
	if thorns_damage <= 0.0 or not is_instance_valid(source) or source == self:
		return
	var attacker_hurtbox := source.get_node_or_null(^"Hurtbox") as Hurtbox
	if attacker_hurtbox:
		attacker_hurtbox.take_hit(thorns_damage, self)

