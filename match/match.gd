extends Node3D
## Root of one run: wires the route, fortress, players and spawner together and owns the match flow.

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
@onready var _status: Label = $DebugUI/Status
@onready var _fortress_info: Label = $DebugUI/FortressInfo
@onready var _player_info: Label = $DebugUI/PlayerInfo
@onready var _carry_info: Label = $DebugUI/CarryInfo
@onready var _storage_info: Label = $DebugUI/StorageInfo
@onready var _upgrade_panel: UpgradePanel = $UI/UpgradePanel

var rng := RandomNumberGenerator.new()

## Weapon cards offered at the current stop, and which one was bought (-1 = none yet).
var weapon_offers: Array[WeaponUpgrade] = []
var weapon_choice: int = -1


func _ready() -> void:
	if rng_seed != 0:
		rng.seed = rng_seed
	_follower.reached_stop.connect(_on_reached_stop)
	_follower.departed.connect(_on_departed)
	_follower.reached_end.connect(_on_reached_end)
	_fortress.health.health_changed.connect(_on_fortress_health_changed)
	_warrior.input.ready_requested.connect(_on_ready_requested)
	_warrior.health.died.connect(_on_warrior_died)
	_spawner.enemy_dropped.connect(_spawn_pickup, CONNECT_DEFERRED)
	_upgrade_panel.setup(_fortress)
	_upgrade_panel.tier_upgrade_requested.connect(request_tier_upgrade)
	_upgrade_panel.tower_requested.connect(request_build_tower)
	_upgrade_panel.weapon_upgrade_requested.connect(request_weapon_upgrade)
	_upgrade_panel.depart_requested.connect(_on_ready_requested)
	_upgrade_panel.hide()
	for bomb: HiddenBomb in $Bombs.get_children():
		bomb.exploded.connect(_on_bomb_exploded)

	var players: Array[Node3D] = [_warrior]
	_spawner.setup(rng, _fortress, players)
	_spawner.active = true
	_follower.start(_route)

	_status.text = "Đang chạy"
	_on_fortress_health_changed(_fortress.health.current, _fortress.health.max_health)


func _process(_delta: float) -> void:
	var warrior_text := "Chiến binh: %d / %d" % [_warrior.health.current, _warrior.health.max_health]
	if not _warrior.is_alive:
		warrior_text = "Chiến binh đã ngã — đang hồi sinh"
	_player_info.text = "%s   |   Quái: %d" % [warrior_text, _spawner.alive_count()]
	_carry_info.text = "Đang mang (%d/%d): %s" % [
		_warrior.inventory.total(), _warrior.inventory.capacity, _format_amounts(_warrior.inventory)]
	_storage_info.text = "Kho pháo đài: %s   [giữ E cạnh pháo đài: sửa bằng Gỗ]" % _format_amounts(_fortress.storage)


# TODO(giai đoạn 7): bỏ phím debug này khi đã có quái gây sát thương thật.
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_K:
		_fortress.health.apply_damage(50.0, self)


# Solo: one player's ready is enough. Multiplayer will wait for every player here.
func _on_ready_requested() -> void:
	if _follower.is_stopped:
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


func _on_warrior_died() -> void:
	var carried := _warrior.inventory.take_all()
	if not carried.is_empty():
		_spawn_pickup.call_deferred(carried, _warrior.global_position)
	await get_tree().create_timer(respawn_delay).timeout
	_warrior.respawn_at(_fortress.global_transform * Vector3(8.0, 0.0, 0.0))


# Deferred by callers: deaths happen inside physics callbacks, where adding areas is not allowed.
func _spawn_pickup(contents: Dictionary, at: Vector3) -> void:
	var pickup: Pickup = PICKUP_SCENE.instantiate()
	pickup.contents = contents
	_pickups.add_child(pickup)
	pickup.global_position = Vector3(at.x, 0.0, at.z)
	var type: ResourceType = ResourceTypes.find(contents.keys()[0]) if contents.size() == 1 else null
	pickup.set_color(type.color if type else MIXED_PILE_COLOR)


func _format_amounts(inventory: Inventory) -> String:
	var parts: PackedStringArray = []
	for type in ResourceTypes.ALL:
		parts.append("%s %d" % [tr(type.display_name), inventory.get_amount(type.id)])
	return "  ".join(parts)


func _on_bomb_exploded(_at: Vector3) -> void:
	print("Match: pháo đài dẫm phải bom")
	_status.text = "Pháo đài dẫm phải bom! Giữ E cạnh pháo đài để sửa"


func _on_fortress_health_changed(current: float, maximum: float) -> void:
	_fortress_info.text = "Pháo đài: %d / %d — tốc độ %d%%  [K: -50 máu]" % [
		current, maximum, roundi(_follower.speed_multiplier * 100.0)]


# Stops are safe zones: no spawning and no monsters left around.
func _on_reached_stop(index: int) -> void:
	print("Match: tới điểm dừng %d" % index)
	_spawner.active = false
	_spawner.clear()
	_status.text = "Điểm dừng %d — bấm Space / Start để khởi hành" % (index + 1)
	weapon_offers = WeaponUpgrades.draw(rng, 3)
	weapon_choice = -1
	_upgrade_panel.show()
	_upgrade_panel.set_weapon_offers(weapon_offers)


func _on_departed() -> void:
	print("Match: khởi hành")
	_spawner.active = true
	_upgrade_panel.hide()
	_status.text = "Đang chạy"


func _on_reached_end() -> void:
	print("Match: tới đích")
	_spawner.active = false
	_spawner.clear()
	_status.text = "Tới đích!"
