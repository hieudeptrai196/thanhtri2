extends Node3D
## Root of one run: wires the route, fortress, players and spawner together and owns the match flow:
## stops, purchases, respawns and the final result.

enum Result { NONE, WON, LOST }

## 0 picks a random seed each run.
@export var rng_seed: int = 0
## Seconds before a fallen warrior returns next to the fortress.
@export var respawn_delay: float = 3.0

const PICKUP_SCENE := preload("res://resources/pickup.tscn")
## Colour for piles holding more than one resource type.
const MIXED_PILE_COLOR := Color(0.9, 0.85, 0.7)

@onready var _route: Path3D = $Route
@onready var _fortress: Fortress = $Fortress
@onready var _follower: RouteFollower = $Fortress/RouteFollower
@onready var _warrior: Warrior = $Warrior
@onready var _spawner: Spawner = $Spawner
@onready var _pickups: Node3D = $Pickups
@onready var _hud: Hud = $UI/HUD
@onready var _upgrade_panel: UpgradePanel = $UI/UpgradePanel
@onready var _result_screen: ResultScreen = $UI/ResultScreen

var rng := RandomNumberGenerator.new()
var result: Result = Result.NONE
var elapsed: float = 0.0
var kills: int = 0

## Weapon cards offered at the current stop, and which one was bought (-1 = none yet).
var weapon_offers: Array[WeaponUpgrade] = []
var weapon_choice: int = -1

var _respawn_left: float = 0.0


func _ready() -> void:
	if rng_seed != 0:
		rng.seed = rng_seed
	_follower.reached_stop.connect(_on_reached_stop)
	_follower.departed.connect(_on_departed)
	_follower.reached_end.connect(_finish.bind(true))
	_fortress.health.died.connect(_finish.bind(false))
	_warrior.input.ready_requested.connect(_on_ready_requested)
	_warrior.health.died.connect(_on_warrior_died)
	_spawner.enemy_dropped.connect(_on_enemy_dropped, CONNECT_DEFERRED)
	_upgrade_panel.setup(_fortress)
	_upgrade_panel.tier_upgrade_requested.connect(request_tier_upgrade)
	_upgrade_panel.tower_requested.connect(request_build_tower)
	_upgrade_panel.weapon_upgrade_requested.connect(request_weapon_upgrade)
	_upgrade_panel.depart_requested.connect(_on_ready_requested)
	_upgrade_panel.hide()
	_result_screen.restart_requested.connect(restart)
	for bomb: HiddenBomb in $Bombs.get_children():
		bomb.exploded.connect(_on_bomb_exploded)

	var players: Array[Node3D] = [_warrior]
	_spawner.setup(rng, _fortress, players)
	_spawner.active = true
	_follower.start(_route)
	_hud.setup(_fortress, _warrior)
	_hud.show_toast(tr("Bảo vệ thành trì tới đích!"))


func _physics_process(delta: float) -> void:
	if result != Result.NONE:
		return
	elapsed += delta
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
func request_tier_upgrade() -> bool:
	var done := _follower.is_stopped and _fortress.upgrade_tier()
	_upgrade_panel.refresh()
	return done


func request_build_tower() -> bool:
	var done := _follower.is_stopped and _fortress.build_tower()
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


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _finish(won: bool) -> void:
	if result != Result.NONE:
		return
	result = Result.WON if won else Result.LOST
	print("Match: %s" % ("thắng" if won else "thua"))
	_spawner.active = false
	_upgrade_panel.hide()
	_hud.set_center_message("")
	_result_screen.show_result(won, elapsed, kills, _fortress.health.current, _fortress.health.max_health)
	get_tree().paused = true


func _on_warrior_died() -> void:
	var carried := _warrior.inventory.take_all()
	if not carried.is_empty():
		_spawn_pickup.call_deferred(carried, _warrior.global_position)
	_respawn_left = respawn_delay


func _on_enemy_dropped(contents: Dictionary, at: Vector3) -> void:
	kills += 1
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
	_upgrade_panel.show()
	_upgrade_panel.set_weapon_offers(weapon_offers)
	_hud.show_toast(tr("Điểm dừng — nâng cấp rồi khởi hành"))


func _on_departed() -> void:
	_spawner.active = true
	_upgrade_panel.hide()
	_hud.show_toast(tr("Khởi hành!"))
