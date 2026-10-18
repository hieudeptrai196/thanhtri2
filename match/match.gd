extends Node3D
## Root of one endless run: wires the route, fortress, players and spawner together and owns the
## match flow: stops, purchases, respawns and the end of the run (fortress destroyed).

enum Result { NONE, LOST }

## 0 picks a random seed each run.
@export var rng_seed: int = 0
## Seconds before a fallen warrior returns next to the fortress.
@export var respawn_delay: float = 3.0
## The warrior cannot get farther than this from the fortress.
@export var leash_radius: float = 90.0
## Loose pickups farther than this from the fortress are removed.
@export var pickup_despawn_radius: float = 150.0

const PICKUP_SCENE := preload("res://resources/pickup.tscn")
## Colour for piles holding more than one resource type.
const MIXED_PILE_COLOR := Color(0.9, 0.85, 0.7)

@onready var _route: EndlessRoute = $Route
@onready var _content: RouteContent = $RouteContent
@onready var _fortress: Fortress = $Fortress
@onready var _follower: RouteFollower = $Fortress/RouteFollower
@onready var _warrior: Warrior = $Warrior
@onready var _spawner: Spawner = $Spawner
@onready var _pickups: Node3D = $Pickups
@onready var _structures: StructureNetwork = $Structures
@onready var noise: NoiseMeter = $NoiseMeter
@onready var _hud: Hud = $UI/HUD
@onready var _upgrade_panel: UpgradePanel = $UI/UpgradePanel
@onready var _result_screen: ResultScreen = $UI/ResultScreen

## Gameplay randomness (enemy spawns, weapon cards). The road has its own RNGs derived from
## run_seed so the same seed always gives the same road, whatever happens in play.
var rng := RandomNumberGenerator.new()
var run_seed: int = 0
var result: Result = Result.NONE
var elapsed: float = 0.0
var kills: int = 0

## Route types offered at the current stop, the pick (-1 = none yet), and the stretch being driven.
var route_offers: Array[RouteType] = []
var route_choice: int = -1
var current_route: RouteType = null

## Weapon cards offered at the current stop, and which one was bought (-1 = none yet).
var weapon_offers: Array[WeaponUpgrade] = []
var weapon_choice: int = -1

var _respawn_left: float = 0.0
var _route_rng: RandomNumberGenerator


func _ready() -> void:
	run_seed = rng_seed if rng_seed != 0 else randi()
	rng.seed = run_seed
	_follower.reached_stop.connect(_on_reached_stop)
	_follower.departed.connect(_on_departed)
	_fortress.health.died.connect(_finish)
	_warrior.input.ready_requested.connect(_on_ready_requested)
	_warrior.input.overdrive_requested.connect(request_overdrive)
	_warrior.input.divine_requested.connect(request_divine_crossbow)
	_warrior.health.died.connect(_on_warrior_died)
	_spawner.enemy_dropped.connect(_on_enemy_dropped, CONNECT_DEFERRED)
	_upgrade_panel.setup(_fortress)
	_upgrade_panel.tier_upgrade_requested.connect(request_tier_upgrade)
	_upgrade_panel.fortress_upgrade_requested.connect(request_fortress_upgrade)
	_upgrade_panel.weapon_upgrade_requested.connect(request_weapon_upgrade)
	_upgrade_panel.route_requested.connect(request_route)
	_upgrade_panel.depart_requested.connect(_on_ready_requested)
	_upgrade_panel.hide()
	_result_screen.restart_requested.connect(restart)
	_content.bomb_exploded.connect(_on_bomb_exploded)
	_content.setup(_route, _seeded_rng("content"))
	# Roadside content past the first stop waits until a route is picked there.
	_content.set_content_limit(_route.stop_distance(0))
	_route_rng = _seeded_rng("routes")
	_route.setup(_seeded_rng("route"))

	var players: Array[Node3D] = [_warrior]
	_spawner.setup(rng, _fortress, _follower, players)
	noise.setup(_fortress)
	_spawner.noise = noise
	noise.level_changed.connect(_on_noise_level_changed)
	var divine := _fortress.divine_crossbow
	_fortress.service_zone.deposited.connect(func(contents: Dictionary) -> void:
		for id in contents:
			divine.add_charge(divine.charge_per_deposited_unit * contents[id]))
	_structures.structure_built.connect(func(_structure: Structure) -> void: divine.add_charge(divine.charge_per_structure_built))
	_spawner.active = true
	_follower.start(_route)
	_structures.setup(_fortress, _route, _fortress.storage)
	_warrior.builder.network = _structures
	_warrior.builder.storage = _fortress.storage
	_warrior.builder.place_requested.connect(request_place.bind(_warrior))
	_warrior.builder.recover_requested.connect(request_recover.bind(_warrior))
	_hud.setup(_fortress, _warrior, noise)
	_hud.show_toast(tr("Bảo vệ thành trì — đi càng xa càng tốt!"))


func _physics_process(delta: float) -> void:
	if result != Result.NONE:
		return
	elapsed += delta
	_content.despawn_before(_follower.distance)
	_keep_warrior_on_leash()
	_despawn_far_pickups()
	if _respawn_left > 0.0:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			_warrior.respawn_at(_fortress.global_transform * Vector3(8.0, 0.0, 0.0))
			_hud.set_center_message("")
		else:
			_hud.set_center_message(tr("Hồi sinh sau %d…") % ceili(_respawn_left))


# Solo: one player's ready is enough. Multiplayer will wait for every player here.
func _on_ready_requested() -> void:
	if _follower.is_stopped and result == Result.NONE:
		_follower.depart()


## Purchases are only allowed while stopped; in multiplayer this check runs on the server.
func request_fortress_upgrade(upgrade: FortressUpgrade) -> bool:
	var done := _follower.is_stopped and _fortress.buy_upgrade(upgrade)
	_upgrade_panel.refresh()
	return done


func request_tier_upgrade() -> bool:
	var done := _follower.is_stopped and _fortress.upgrade_tier()
	_upgrade_panel.refresh()
	return done


## One card per stop; the buyer's weapon gets it. Paid from the shared fortress storage.
func request_weapon_upgrade(index: int) -> bool:
	if not _follower.is_stopped or weapon_choice != -1 or index < 0 or index >= weapon_offers.size():
		return false
	if not _fortress.storage.spend(weapon_offers[index].cost):
		return false
	_warrior.weapon.apply_upgrade(weapon_offers[index])
	weapon_choice = index
	_upgrade_panel.set_weapon_choice(index)
	return true


## Places a structure for `player` (in their build range, not blocked): a carried one goes down
## finished; otherwise a blueprint the team builds together, paid while hammering.
## In multiplayer this check runs on the server.
func request_place(type: StructureType, point: Vector3, player: Warrior) -> bool:
	if result != Result.NONE or not player.is_alive:
		return false
	var reach := Vector2(point.x - player.global_position.x, point.z - player.global_position.z).length()
	if reach > player.builder.build_range + 0.1:
		return false
	if _structures.check_placement(type, point) == StructureNetwork.Placement.BLOCKED:
		return false
	if player.carried_type == type:
		_structures.place(type, point, player.carried_health)
		player.clear_carried()
	else:
		_structures.place_blueprint(type, point)
	return true


## Takes down an unfinished blueprint (refunding what was paid), or folds a finished foldable
## structure onto `player`'s back if their hands are free.
func request_recover(structure: Structure, player: Warrior) -> bool:
	if result != Result.NONE or not player.is_alive or not is_instance_valid(structure) or not structure.can_recover():
		return false
	if structure.global_position.distance_to(player.global_position) > player.builder.recover_range + 0.5:
		return false
	if not structure.built:
		_structures.dismantle(structure)
		return true
	if player.carried_type != null:
		return false
	var data := _structures.recover(structure)
	player.carry(data.type, data.health)
	return true


## Any player may toggle the fortress overdrive; in multiplayer the server applies it.
func request_overdrive() -> void:
	if result != Result.NONE:
		return
	_fortress.overdrive = not _fortress.overdrive
	_hud.show_toast(tr("Tăng tốc! Tốn Than gấp nhiều lần") if _fortress.overdrive else tr("Chạy bình thường"))


## Any player may fire the Nỏ thần once it is fully charged.
func request_divine_crossbow() -> bool:
	if result != Result.NONE or not _fortress.divine_crossbow.is_ready():
		return false
	var hits := _fortress.divine_crossbow.fire()
	_hud.show_toast(tr("NỎ THẦN! Trúng %d quái") % hits)
	return true


func _on_noise_level_changed(level: NoiseMeter.Level) -> void:
	if level == NoiseMeter.Level.PURSUIT:
		_hud.show_toast(tr("TRUY ĐUỔI! Bầy quái dồn tới từ phía sau — chạy tới điểm dừng!"))


## Picks the route for the stretch after this stop (may be changed until departure).
func request_route(index: int) -> bool:
	if not _follower.is_stopped or index < 0 or index >= route_offers.size():
		return false
	route_choice = index
	_upgrade_panel.set_route_choice(index)
	return true


func _apply_route(type: RouteType) -> void:
	current_route = type
	_content.route_type = type
	_content.set_content_limit(_follower.next_stop_distance())
	_spawner.route_rate_multiplier = type.enemy_rate_multiplier
	_spawner.route_health_multiplier = type.enemy_health_multiplier
	var ground: ShaderMaterial = $Ground/Mesh.mesh.material
	ground.set_shader_parameter(&"color_a", type.ground_color_a)
	ground.set_shader_parameter(&"color_b", type.ground_color_b)


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _finish() -> void:
	if result != Result.NONE:
		return
	result = Result.LOST
	_spawner.active = false
	_upgrade_panel.hide()
	_hud.set_center_message("")
	_result_screen.show_result(_follower.distance, elapsed, kills)
	get_tree().paused = true


func _seeded_rng(purpose: String) -> RandomNumberGenerator:
	var generator := RandomNumberGenerator.new()
	generator.seed = hash("%s:%d" % [purpose, run_seed])
	return generator


func _keep_warrior_on_leash() -> void:
	var offset := _warrior.global_position - _fortress.global_position
	offset.y = 0.0
	if offset.length() > leash_radius:
		var pulled := _fortress.global_position + offset.normalized() * leash_radius
		_warrior.global_position = Vector3(pulled.x, _warrior.global_position.y, pulled.z)


func _despawn_far_pickups() -> void:
	for pickup in _pickups.get_children():
		if pickup.global_position.distance_to(_fortress.global_position) > pickup_despawn_radius:
			pickup.queue_free()


func _on_warrior_died() -> void:
	if _warrior.carried_type:
		# The folded structure drops where the warrior fell (unpowered unless the fortress is near).
		_structures.place.call_deferred(_warrior.carried_type, _warrior.global_position, _warrior.carried_health)
		_warrior.clear_carried()
	var carried := _warrior.inventory.take_all()
	if not carried.is_empty():
		_spawn_pickup.call_deferred(carried, _warrior.global_position)
	_respawn_left = respawn_delay


func _on_enemy_dropped(contents: Dictionary, at: Vector3) -> void:
	kills += 1
	if current_route and current_route.drop_multiplier != 1.0:
		for id in contents:
			contents[id] = roundi(contents[id] * current_route.drop_multiplier)
	_fortress.divine_crossbow.add_charge(_fortress.divine_crossbow.charge_per_kill)
	_spawn_pickup(contents, at)


# Deferred by callers: deaths happen inside physics callbacks, where adding areas is not allowed.
func _spawn_pickup(contents: Dictionary, at: Vector3) -> void:
	var pickup: Pickup = PICKUP_SCENE.instantiate()
	pickup.contents = contents
	_pickups.add_child(pickup)
	pickup.global_position = Vector3(at.x, 0.0, at.z)
	var type: ResourceType = ResourceTypes.find(contents.keys()[0]) if contents.size() == 1 else null
	pickup.set_color(type.color if type else MIXED_PILE_COLOR)


func _on_bomb_exploded(_at: Vector3) -> void:
	_hud.show_toast(tr("Pháo đài dẫm phải bom! Đứng cạnh, giữ E để sửa"))


# Stops are safe zones: no spawning and no monsters left around.
func _on_reached_stop(_index: int) -> void:
	_spawner.active = false
	_spawner.clear()
	weapon_offers = WeaponUpgrades.draw(rng, 3)
	weapon_choice = -1
	route_offers = RouteTypes.draw(_route_rng, 2)
	route_choice = -1
	_upgrade_panel.show()
	_upgrade_panel.set_weapon_offers(weapon_offers)
	_upgrade_panel.set_route_offers(route_offers)
	_hud.show_toast(tr("Điểm dừng — nâng cấp rồi khởi hành"))


func _on_departed() -> void:
	_spawner.active = true
	_upgrade_panel.hide()
	if not route_offers.is_empty():
		_apply_route(route_offers[maxi(route_choice, 0)])
		_hud.show_toast(tr("Khởi hành — tuyến %s") % tr(current_route.display_name))
	else:
		_hud.show_toast(tr("Khởi hành!"))
