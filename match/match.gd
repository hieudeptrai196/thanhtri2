class_name Match
extends Node3D
## Root of one endless run: wires the route, fortress, players and spawner together and owns the
## match flow: stops, purchases, respawns and the end of the run (fortress destroyed).

enum Result { NONE, LOST }
## RANDOM = a fresh seed each run; DAILY = today's seed, the same road for everyone.
enum Mode { RANDOM, DAILY }

## 0 picks a random seed each run (or today's seed in daily mode).
@export var rng_seed: int = 0
## main.tscn turns this on: the run waits behind the start menu. Tests leave it off.
@export var wait_for_start: bool = false
## Seconds before a fallen warrior returns next to the fortress.
@export var respawn_delay: float = 3.0
## The warrior cannot get farther than this from the fortress.
@export var leash_radius: float = 90.0
## Loose pickups farther than this from the fortress are removed.
@export var pickup_despawn_radius: float = 150.0

const PICKUP_SCENE := preload("res://resources/pickup.tscn")
const WARRIOR_SCENE := preload("res://player/warrior.tscn")
## Colour for piles holding more than one resource type.
const MIXED_PILE_COLOR := Color(0.9, 0.85, 0.7)

@onready var _route: EndlessRoute = $Route
@onready var _content: RouteContent = $RouteContent
@onready var _fortress: Fortress = $Fortress
@onready var _follower: RouteFollower = $Fortress/RouteFollower
@onready var _spawner: Spawner = $Spawner
@onready var _pickups: Node3D = $Pickups
@onready var _structures: StructureNetwork = $Structures
@onready var noise: NoiseMeter = $NoiseMeter
@onready var _hud: Hud = $UI/HUD
@onready var _upgrade_panel: UpgradePanel = $UI/UpgradePanel
@onready var _result_screen: ResultScreen = $UI/ResultScreen
@onready var _start_menu: StartMenu = $UI/StartMenu

## Gameplay randomness (enemy spawns, weapon cards). The road has its own RNGs derived from
## run_seed so the same seed always gives the same road, whatever happens in play.
var rng := RandomNumberGenerator.new()
var run_seed: int = 0
var mode: Mode = Mode.RANDOM
## YYYY-MM-DD of the daily challenge being played (daily mode only).
var daily_date: String = ""
## Record for this mode before the run started (shown on the HUD).
var best_before: float = 0.0

## The run picked on the menu / result screen, carried across the scene reload that starts it.
static var _queued_mode: int = -1
static var _queued_daily_date: String = ""
## Online runs: the seed the host picked, so every machine builds the same road (0 = none).
static var _queued_seed: int = 0
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

## Every warrior in the run (index 0 is the host's, the scene's own $Warrior).
var players: Array[Warrior] = []
## The warrior played on this machine (HUD and camera follow it).
var local_warrior: Warrior
## Same warriors as targets for enemies (shared with the spawner).
var _player_targets: Array[Node3D] = []
## Seconds until each fallen warrior respawns.
var _respawns: Dictionary = {}
var _route_rng: RandomNumberGenerator
## Online only (null in solo).
var _net: NetSync
## True while the start menu (and the co-op lobby) is up and the run has not begun.
var _in_lobby: bool = false
var _join_address: String = ""


func _ready() -> void:
	if _queued_mode != -1:
		mode = _queued_mode as Mode
		daily_date = _queued_daily_date
		_queued_mode = -1
		wait_for_start = false
	if _queued_seed != 0:
		run_seed = _queued_seed
		_queued_seed = 0
	elif rng_seed != 0:
		run_seed = rng_seed
	elif mode == Mode.DAILY:
		run_seed = daily_seed(daily_date)
	else:
		run_seed = randi()
	best_before = SaveManager.best_daily(daily_date) if mode == Mode.DAILY else SaveManager.best_distance()
	rng.seed = run_seed
	if _is_host():
		_follower.reached_stop.connect(_on_reached_stop)
		_follower.departed.connect(_on_departed)
	_fortress.health.died.connect(_finish)
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

	_spawner.setup(rng, _fortress, _follower, _player_targets)
	noise.setup(_fortress)
	_spawner.noise = noise
	noise.level_changed.connect(_on_noise_level_changed)
	var divine := _fortress.divine_crossbow
	_fortress.service_zone.deposited.connect(func(contents: Dictionary) -> void:
		for id in contents:
			divine.add_charge(divine.charge_per_deposited_unit * contents[id]))
	_structures.structure_built.connect(func(_structure: Structure) -> void: divine.add_charge(divine.charge_per_structure_built))
	_spawner.active = _is_host()
	_follower.start(_route)
	_structures.setup(_fortress, _route, _fortress.storage)
	# The scene's own warrior is always the host's (peer 1).
	var host_warrior: Warrior = $Warrior
	add_player(host_warrior)
	if _is_host():
		_set_local_warrior(host_warrior)
	else:
		# Clients draw what the host simulates; their own warrior arrives with the first snapshot.
		host_warrior.input.remote = true
		host_warrior.set_simulated(false)
		for node: Node in [_spawner, _structures, noise, _fortress, _fortress.service_zone, $Fortress/Crossbow]:
			node.set_physics_process(false)
	if Net.is_online(multiplayer):
		_ensure_net_sync()
	_hud.show_toast(tr("Bảo vệ thành trì — đi càng xa càng tốt!"))
	_start_menu.play_requested.connect(func() -> void: start_run(Mode.RANDOM))
	_start_menu.daily_requested.connect(func() -> void: start_run(Mode.DAILY))
	_start_menu.host_requested.connect(host_room)
	_start_menu.join_requested.connect(join_room)
	_start_menu.online_start_requested.connect(func() -> void: _net.start_shared_run(randi_range(1, 0x7fffffff)))
	_start_menu.leave_requested.connect(leave_room)
	_result_screen.menu_requested.connect(back_to_menu)
	if wait_for_start:
		_in_lobby = true
		_start_menu.open()
		get_tree().paused = true


func _physics_process(delta: float) -> void:
	if result != Result.NONE:
		return
	elapsed += delta
	_content.despawn_before(_follower.distance)
	if not _is_host():
		return
	for player in players:
		_keep_on_leash(player)
	_despawn_far_pickups()
	_tick_respawns(delta)


## Adds a warrior to the run: enemies may target it, its build mode works, its intents count.
func add_player(warrior: Warrior) -> void:
	players.append(warrior)
	_player_targets.append(warrior)
	warrior.input.ready_requested.connect(_on_ready_requested)
	warrior.input.overdrive_requested.connect(request_overdrive)
	warrior.input.divine_requested.connect(request_divine_crossbow)
	warrior.health.died.connect(_on_player_died.bind(warrior))
	warrior.builder.network = _structures
	warrior.builder.storage = _fortress.storage
	warrior.builder.place_requested.connect(request_place.bind(warrior))
	warrior.builder.recover_requested.connect(request_recover.bind(warrior))


## The warrior of multiplayer peer `id`, or null.
func player_by_peer(id: int) -> Warrior:
	for warrior in players:
		if warrior.peer_id == id:
			return warrior
	return null


## Online: creates the warrior of peer `id` next to the fortress (host: when that peer is ready;
## client: when a snapshot first mentions it).
func spawn_player(id: int) -> Warrior:
	var existing := player_by_peer(id)
	if existing:
		return existing
	var warrior: Warrior = WARRIOR_SCENE.instantiate()
	warrior.name = "Warrior_%d" % id
	warrior.peer_id = id
	add_child(warrior)
	warrior.global_position = _fortress.global_transform * Vector3(8.0, 0.1, 2.0 * players.size())
	var is_mine := id == multiplayer.get_unique_id()
	warrior.input.remote = not is_mine
	warrior.input.record_events = is_mine and not _is_host()
	if not _is_host():
		warrior.set_simulated(false)
	add_player(warrior)
	if is_mine:
		_set_local_warrior(warrior)
	_hud.show_toast(tr("Người chơi %d đã vào") % players.size())
	return warrior


func remove_player(id: int) -> void:
	var warrior := player_by_peer(id)
	if warrior == null or warrior == local_warrior:
		return
	players.erase(warrior)
	_player_targets.erase(warrior)
	_respawns.erase(warrior)
	warrior.queue_free()
	_hud.show_toast(tr("Một người chơi đã rời đi"))


func _set_local_warrior(warrior: Warrior) -> void:
	local_warrior = warrior
	$IsoCamera.target = warrior
	_hud.setup(_fortress, warrior, noise, best_before)


func _tick_respawns(delta: float) -> void:
	for warrior: Warrior in _respawns.keys():
		_respawns[warrior] -= delta
		if _respawns[warrior] <= 0.0:
			_respawns.erase(warrior)
			warrior.respawn_at(_fortress.global_transform * Vector3(8.0, 0.0, 0.0))
	var local_left: float = _respawns.get(local_warrior, 0.0)
	_hud.set_center_message(tr("Hồi sinh sau %d…") % ceili(local_left) if local_left > 0.0 else "")


# Solo: one player's ready is enough. Multiplayer will wait for every player here (M2.1d).
func _on_ready_requested() -> void:
	if _is_host() and _follower.is_stopped and result == Result.NONE:
		_follower.depart()


## Purchases are only allowed while stopped; in multiplayer this check runs on the server.
func request_fortress_upgrade(upgrade: FortressUpgrade) -> bool:
	var done := _is_host() and _follower.is_stopped and _fortress.buy_upgrade(upgrade)
	_upgrade_panel.refresh()
	return done


func request_tier_upgrade() -> bool:
	var done := _is_host() and _follower.is_stopped and _fortress.upgrade_tier()
	_upgrade_panel.refresh()
	return done


## One card per stop; the buyer's weapon gets it (default: this machine's warrior).
## Paid from the shared fortress storage.
func request_weapon_upgrade(index: int, buyer: Warrior = null) -> bool:
	if not _is_host() or not _follower.is_stopped or weapon_choice != -1 or index < 0 or index >= weapon_offers.size():
		return false
	if not _fortress.storage.spend(weapon_offers[index].cost):
		return false
	(buyer if buyer else local_warrior).weapon.apply_upgrade(weapon_offers[index])
	weapon_choice = index
	_upgrade_panel.set_weapon_choice(index)
	return true


## Places a structure for `player` (in their build range, not blocked): a carried one goes down
## finished; otherwise a blueprint the team builds together, paid while hammering.
## In multiplayer this check runs on the server.
func request_place(type: StructureType, point: Vector3, player: Warrior) -> bool:
	if not _is_host() or result != Result.NONE or not player.is_alive:
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
	if not _is_host() or result != Result.NONE or not player.is_alive or not is_instance_valid(structure) or not structure.can_recover():
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
	if not _is_host() or result != Result.NONE:
		return
	_fortress.overdrive = not _fortress.overdrive
	_hud.show_toast(tr("Tăng tốc! Tốn Than gấp nhiều lần") if _fortress.overdrive else tr("Chạy bình thường"))


## Any player may fire the Nỏ thần once it is fully charged.
func request_divine_crossbow() -> bool:
	if not _is_host() or result != Result.NONE or not _fortress.divine_crossbow.is_ready():
		return false
	var hits := _fortress.divine_crossbow.fire()
	_hud.show_toast(tr("NỎ THẦN! Trúng %d quái") % hits)
	return true


func _on_noise_level_changed(level: NoiseMeter.Level) -> void:
	if level == NoiseMeter.Level.PURSUIT:
		_hud.show_toast(tr("TRUY ĐUỔI! Bầy quái dồn tới từ phía sau — chạy tới điểm dừng!"))


## Picks the route for the stretch after this stop (may be changed until departure).
func request_route(index: int) -> bool:
	if not _is_host() or not _follower.is_stopped or index < 0 or index >= route_offers.size():
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


## Today's date as used for daily challenges (local time).
static func today() -> String:
	return Time.get_date_string_from_system()


static func daily_seed(date: String) -> int:
	return hash("thanhtri-daily:" + date)


## Queues a run for the next match that starts (the reload in start_run, or a test's next match).
static func queue_run(run_mode: Mode, date: String = "", shared_seed: int = 0) -> void:
	_queued_mode = run_mode
	_queued_seed = shared_seed
	_queued_daily_date = date if date != "" else (today() if run_mode == Mode.DAILY else "")


func start_run(run_mode: Mode) -> void:
	if Net.is_online(multiplayer):
		leave_room()
	queue_run(run_mode, daily_date if run_mode == Mode.DAILY and mode == Mode.DAILY else "")
	get_tree().paused = false
	get_tree().reload_current_scene()


## Plays again in the same mode: a new random road, or the same daily road.
func restart() -> void:
	if Net.is_online(multiplayer) and _net:
		if _is_host():
			_net.start_shared_run(randi_range(1, 0x7fffffff))
		else:
			back_to_menu()  # only the host starts runs
		return
	start_run(mode)


func back_to_menu() -> void:
	Net.leave(multiplayer)
	get_tree().paused = false
	get_tree().reload_current_scene()


func _finish() -> void:
	if result != Result.NONE:
		return
	result = Result.LOST
	_spawner.active = false
	_upgrade_panel.hide()
	_hud.set_center_message("")
	if _net and _is_host():
		_net.run_finished.rpc(_follower.distance, elapsed, kills)
	var is_record := SaveManager.record_run(_follower.distance, daily_date if mode == Mode.DAILY else "")
	var best := maxf(best_before, _follower.distance)
	_result_screen.show_result(_follower.distance, elapsed, kills, best, is_record, daily_date if mode == Mode.DAILY else "")
	# Online the world keeps running underneath: pausing one machine would stall the others' sync.
	if not Net.is_online(multiplayer):
		get_tree().paused = true


func _is_host() -> bool:
	return multiplayer.is_server()


func in_lobby() -> bool:
	return _in_lobby


func _ensure_net_sync() -> void:
	if _net:
		return
	_net = NetSync.new()
	_net.name = "NetSync"
	add_child(_net)
	_net.setup(self)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_left_lobby)


## Opens a co-op room from the menu; friends join by this machine's address.
func host_room() -> void:
	var error := Net.host(multiplayer)
	if error != OK:
		_start_menu.show_lobby_status(tr("Không mở được phòng (cổng %d đang bận?)") % Net.PORT, false)
		return
	_ensure_net_sync()
	_refresh_lobby()


func join_room(address: String) -> void:
	var error := Net.join(multiplayer, address)
	if error != OK:
		_start_menu.show_lobby_status(tr("Địa chỉ không hợp lệ"), false)
		return
	_ensure_net_sync()
	_join_address = address
	_start_menu.show_lobby_status(tr("Đang kết nối tới %s…") % address, true)
	multiplayer.connected_to_server.connect(_on_joined)
	multiplayer.connection_failed.connect(_on_join_failed)


func _on_joined() -> void:
	_start_menu.show_lobby_status(tr("Đã vào phòng — chờ chủ phòng bắt đầu"), true)


func _on_join_failed() -> void:
	leave_room()
	_start_menu.show_lobby_status(tr("Không kết nối được tới %s") % _join_address, false)


func _on_peer_left_lobby(_id: int) -> void:
	_refresh_lobby()


func leave_room() -> void:
	if multiplayer.connected_to_server.is_connected(_on_joined):
		multiplayer.connected_to_server.disconnect(_on_joined)
		multiplayer.connection_failed.disconnect(_on_join_failed)
	Net.leave(multiplayer)
	if _net:
		_net.queue_free()
		_net = null


## Every machine reloads the match on the host's seed (sent through NetSync.begin_run).
func load_shared_run(shared_seed: int) -> void:
	if not _in_lobby and shared_seed == run_seed:
		return  # already on this road (NetSync announced itself on connecting)
	queue_run(Mode.RANDOM, "", shared_seed)
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_peer_connected(id: int) -> void:
	if not _is_host():
		return
	if _in_lobby:
		_refresh_lobby()
	else:
		_net.begin_run.rpc_id(id, run_seed)  # joined mid-run: load this road and catch up


func _refresh_lobby() -> void:
	if not _in_lobby or not _is_host() or not Net.is_online(multiplayer):
		return
	var addresses := ", ".join(Net.lan_addresses())
	_start_menu.show_lobby_status(tr("Phòng đã mở — địa chỉ: %s") % (addresses if addresses != "" else "127.0.0.1")
		+ "\n" + tr("Người chơi: %d/%d") % [multiplayer.get_peers().size() + 1, Net.MAX_PLAYERS], true, true)


## The host left or dropped: back to the menu with a note.
func on_host_lost() -> void:
	back_to_menu()


## Host: everything clients need to draw this tick.
func net_snapshot() -> Dictionary:
	var warriors := {}
	for warrior in players:
		var state := warrior.net_state()
		state.append(_respawns.get(warrior, 0.0))
		warriors[warrior.peer_id] = state
	return {"fortress": _fortress.net_state(), "noise": [noise.value, noise.pursuit_time], "warriors": warriors,
		"route": RouteTypes.ALL.find(current_route), "kills": kills, "elapsed": elapsed}


## Client: shows the host's world.
func apply_net_snapshot(snapshot: Dictionary) -> void:
	_fortress.apply_net_state(snapshot.fortress)
	noise.set_net_state(snapshot.noise[0], snapshot.noise[1])
	kills = snapshot.kills
	elapsed = snapshot.elapsed
	var route: int = snapshot.route
	if route >= 0 and RouteTypes.ALL[route] != current_route:
		_apply_route(RouteTypes.ALL[route])
	var warriors: Dictionary = snapshot.warriors
	for id: int in warriors:
		var warrior := spawn_player(id)
		warrior.apply_net_state(warriors[id])
	for warrior in players.duplicate():
		if not warriors.has(warrior.peer_id):
			remove_player(warrior.peer_id)
	if local_warrior:
		var respawn_left: float = warriors[local_warrior.peer_id][7]
		_hud.set_center_message(tr("Hồi sinh sau %d…") % ceili(respawn_left) if respawn_left > 0.0 else "")


## Client: the host says the run is over.
func finish_from_host(distance: float, host_elapsed: float, host_kills: int) -> void:
	elapsed = host_elapsed
	kills = host_kills
	_follower.distance = distance
	_finish()


func _seeded_rng(purpose: String) -> RandomNumberGenerator:
	var generator := RandomNumberGenerator.new()
	generator.seed = hash("%s:%d" % [purpose, run_seed])
	return generator


func _keep_on_leash(warrior: Warrior) -> void:
	var offset := warrior.global_position - _fortress.global_position
	offset.y = 0.0
	if offset.length() > leash_radius:
		var pulled := _fortress.global_position + offset.normalized() * leash_radius
		warrior.global_position = Vector3(pulled.x, warrior.global_position.y, pulled.z)


func _despawn_far_pickups() -> void:
	for pickup in _pickups.get_children():
		if pickup.global_position.distance_to(_fortress.global_position) > pickup_despawn_radius:
			pickup.queue_free()


func _on_player_died(warrior: Warrior) -> void:
	if warrior.carried_type:
		# The folded structure drops where the warrior fell (unpowered unless the fortress is near).
		_structures.place.call_deferred(warrior.carried_type, warrior.global_position, warrior.carried_health)
		warrior.clear_carried()
	var carried := warrior.inventory.take_all()
	if not carried.is_empty():
		_spawn_pickup.call_deferred(carried, warrior.global_position)
	_respawns[warrior] = respawn_delay


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
