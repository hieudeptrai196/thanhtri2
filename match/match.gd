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
const BLAST_SCENE := preload("res://world/blast_fx.tscn")
const TRACER_COLOR := Color(1.0, 0.9, 0.5)
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
## Who did what this run (host keeps it; clients get it with the result).
var team_stats := TeamStats.new()

## Route types offered at the current stop, the pick (-1 = none yet), and the stretch being driven.
var route_offers: Array[RouteType] = []
var route_choice: int = -1
var current_route: RouteType = null

## Weapon cards offered at the current stop (the same three for everyone); each player may buy one
## for their own weapon. Card bought by each peer this stop.
var weapon_offers: Array[WeaponUpgrade] = []
var _weapon_choices: Dictionary = {}
## Card this machine's player bought at this stop (-1 = none yet).
var weapon_choice: int:
	get:
		return _weapon_choices.get(local_warrior.peer_id if local_warrior else 1, -1)
## Players who pressed ready at this stop (the fortress leaves when all have).
var _ready_players: Dictionary = {}

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
## Host: shots fired since the last snapshot (pairs of from / to), and the next pickup id.
var _net_shots := PackedVector3Array()
var _next_pickup_id: int = 1
## Client: piles shown, by id.
var _pickups_by_id: Dictionary = {}
## The current ping of each peer (one each; a new one replaces it), and when each player may ping again.
var _pings: Dictionary = {}
var _ping_ready_at: Dictionary = {}


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
	_spawner.enemy_slain.connect(_on_enemy_slain)
	_fortress.service_zone.player_deposited.connect(func(player: Node3D, contents: Dictionary) -> void:
		if player is Warrior:
			team_stats.add(player.peer_id, &"haul", contents.values().reduce(func(a: int, b: int) -> int: return a + b, 0)))
	_upgrade_panel.setup(_fortress)
	_upgrade_panel.tier_upgrade_requested.connect(_panel_request.bind(&"tier", -1))
	_upgrade_panel.fortress_upgrade_requested.connect(func(upgrade: FortressUpgrade) -> void:
		_panel_request(&"fortress", FortressUpgrades.ALL.find(upgrade)))
	_upgrade_panel.weapon_upgrade_requested.connect(func(index: int) -> void: _panel_request(&"weapon", index))
	_upgrade_panel.route_requested.connect(func(index: int) -> void: _panel_request(&"route", index))
	_upgrade_panel.depart_requested.connect(_panel_request.bind(&"ready", -1))
	_upgrade_panel.hide()
	_result_screen.restart_requested.connect(restart)
	_content.bomb_exploded.connect(_on_bomb_exploded)
	_content.resource_gathered.connect(func(left: int, id: int) -> void: _send_fx(&"resource", [id, left]))
	_content.bomb_triggered.connect(func(_at: Vector3, id: int) -> void: _send_fx(&"bomb", [id]))
	_structures.shot_fired.connect(_on_shot_fired)
	$Fortress/Crossbow.fired.connect(_on_shot_fired)
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
	_structures.structure_built.connect(_try_engrave)
	_spawner.active = _is_host()
	_follower.start(_route)
	_structures.setup(_fortress, _route, _fortress.storage)
	# The scene's own warrior is always the host's (peer 1).
	var host_warrior: Warrior = $Warrior
	add_player(host_warrior)
	if _is_host():
		host_warrior.apply_class(PlayerClasses.chosen())
		_update_team_bonuses()
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
	_apply_structure_auras()
	_tick_downed(delta)
	_tick_crossbow_seat()
	_count_hammering(delta)
	_despawn_far_pickups()
	_tick_respawns(delta)


## Adds a warrior to the run: enemies may target it, its build mode works, its intents count.
func add_player(warrior: Warrior) -> void:
	players.append(warrior)
	_player_targets.append(warrior)
	team_stats.set_class(warrior.peer_id, PlayerClasses.ALL.find(warrior.player_class))  # join order names class-less players
	warrior.input.ready_requested.connect(request_departure.bind(warrior))
	warrior.input.overdrive_requested.connect(request_overdrive)
	warrior.input.divine_requested.connect(request_divine_crossbow)
	warrior.input.ping_requested.connect(request_ping.bind(warrior))
	warrior.fell.connect(_on_player_died.bind(warrior))
	warrior.builder.network = _structures
	warrior.builder.storage = _fortress.storage
	warrior.builder.place_requested.connect(request_place.bind(warrior))
	warrior.builder.recover_requested.connect(request_recover.bind(warrior))
	warrior.skills.fortress = _fortress
	warrior.skills.used.connect(_on_skill_used.bind(warrior))


## The warrior of multiplayer peer `id`, or null.
func player_by_peer(id: int) -> Warrior:
	for warrior in players:
		if warrior.peer_id == id:
			return warrior
	return null


## Online: creates the warrior of peer `id` next to the fortress (host: when that peer is ready;
## client: when a snapshot first mentions it).
func spawn_player(id: int, player_class: PlayerClass = null) -> Warrior:
	var existing := player_by_peer(id)
	if existing:
		return existing
	var warrior: Warrior = WARRIOR_SCENE.instantiate()
	warrior.name = "Warrior_%d" % id
	warrior.peer_id = id
	add_child(warrior)
	warrior.global_position = _fortress.global_transform * Vector3(8.0, 0.1, 2.0 * players.size())
	warrior.apply_class(player_class)
	var is_mine := id == multiplayer.get_unique_id()
	warrior.input.remote = not is_mine
	warrior.input.record_events = is_mine and not _is_host()
	if not _is_host():
		warrior.set_simulated(false)
	add_player(warrior)
	_update_team_bonuses()
	if is_mine:
		_set_local_warrior(warrior)
	else:
		_hud.show_toast(tr("Người chơi %d đã vào") % players.size())
	return warrior


func remove_player(id: int) -> void:
	var warrior := player_by_peer(id)
	if warrior == null or warrior == local_warrior:
		return
	if _is_host():
		_drop_belongings(warrior)  # nothing they carried is lost for the team
	players.erase(warrior)
	_player_targets.erase(warrior)
	_respawns.erase(warrior)
	_ready_players.erase(warrior)
	warrior.queue_free()
	_update_team_bonuses()
	_check_all_ready()  # the one who left may have been the last not ready
	_hud.show_toast(tr("Một người chơi đã rời đi"))


func _set_local_warrior(warrior: Warrior) -> void:
	local_warrior = warrior
	$IsoCamera.target = warrior
	_hud.setup(_fortress, warrior, noise, best_before)


## Team-wide class bonuses: the best one in the team applies (they do not stack).
func _update_team_bonuses() -> void:
	var fuel := 1.0
	var prices := 1.0
	for warrior in players:
		if warrior.player_class:
			fuel = minf(fuel, warrior.player_class.overdrive_fuel_multiplier)
			prices = minf(prices, warrior.player_class.upgrade_cost_multiplier)
	_fortress.overdrive_fuel_multiplier = fuel
	# With teammates around, 0 health downs a warrior so others can get them up.
	for warrior in players:
		warrior.downed_enabled = players.size() > 1
	# More players, more monsters (see Difficulty); follows joins and leaves at once.
	_spawner.team_size = players.size()
	_fortress.upgrade_cost_multiplier = prices
	_upgrade_panel.refresh()


# Structures near a living warrior with an aura class (Thầy pháp) fire faster.
func _apply_structure_auras() -> void:
	for structure in _structures.structures():
		var bonus := 1.0
		for warrior in players:
			var c := warrior.player_class
			if c and c.structure_aura_radius > 0.0 and warrior.is_alive \
					and warrior.global_position.distance_to(structure.global_position) <= c.structure_aura_radius:
				bonus = maxf(bonus, c.structure_fire_rate)
		structure.fire_rate_bonus = bonus * structure.engrave_bonus


# Công binh × Thầy pháp: a turret a Công binh finishes inside a Thầy pháp's aura is khắc phù for good.
func _try_engrave(structure: Structure) -> void:
	if not _is_host() or structure.find_children("*", "AutoShooter", true, false).is_empty():
		return
	var engrave := 1.0
	for hammerer in structure.finished_by:
		var c: PlayerClass = hammerer.get("player_class") if is_instance_valid(hammerer) else null
		if c:
			engrave = maxf(engrave, c.engrave_fire_rate)
	if engrave <= 1.0 or not _in_structure_aura(structure):
		return
	structure.engrave(engrave)
	_toast_all("Khắc phù! %s bắn nhanh hơn mãi mãi", [structure.type.display_name])  # i18n


func _in_structure_aura(structure: Structure) -> bool:
	for warrior in players:
		var c := warrior.player_class
		if c and c.structure_aura_radius > 0.0 and warrior.is_alive \
				and warrior.global_position.distance_to(structure.global_position) <= c.structure_aura_radius:
			return true
	return false


## Distance at which a teammate holding interact helps a downed warrior up.
const REVIVE_REACH := 2.0


func _tick_downed(delta: float) -> void:
	for downed in players:
		if not downed.downed:
			continue
		var helpers: Array[Warrior] = []
		for helper in players:
			if helper != downed and helper.is_alive and helper.input.interact_held:
				var offset := helper.global_position - downed.global_position
				if Vector2(offset.x, offset.z).length() <= REVIVE_REACH:
					downed.add_reviver()
					helpers.append(helper)
		downed.tick_downed(delta)
		if downed.is_alive:  # helped up this tick
			for helper in helpers:
				team_stats.add(helper.peer_id, &"revives", 1)


# Seconds each player spends hammering a blueprint (the "build" stat).
func _count_hammering(delta: float) -> void:
	for warrior in players:
		var target := warrior.builder.hammer_target
		if warrior.is_alive and target and is_instance_valid(target) and not target.built:
			team_stats.add(warrior.peer_id, &"build", delta)


# A warrior's own blow, or the fortress crossbow while someone mans it, counts as that player's kill.
func _on_enemy_slain(killer: Node) -> void:
	if killer is Warrior:
		team_stats.add(killer.peer_id, &"kills", 1)
	elif killer == _fortress and _fortress.gunner:
		team_stats.add(_fortress.gunner.peer_id, &"kills", 1)


# E at the foot of the ladder climbs onto the fortress crossbow; E or dash climbs down.
func _tick_crossbow_seat() -> void:
	for warrior in players:
		if warrior.manning:
			if warrior.input.interact_pressed or warrior.input.dash_pressed:
				_fortress.release_gunner()
		elif warrior.input.interact_pressed:
			_fortress.try_man_crossbow(warrior)


# Downed > respawn countdown > nothing, for this machine's player.
func _update_center_message(respawn_left: float) -> void:
	if local_warrior and local_warrior.downed:
		_hud.set_center_message(tr("Bạn đã gục — đồng đội giữ E cạnh bạn để đỡ dậy (%d)") % ceili(local_warrior.downed_left))
	else:
		_hud.set_center_message(tr("Hồi sinh sau %d…") % ceili(respawn_left) if respawn_left > 0.0 else "")


func _tick_respawns(delta: float) -> void:
	for warrior: Warrior in _respawns.keys():
		_respawns[warrior] -= delta
		if _respawns[warrior] <= 0.0:
			_respawns.erase(warrior)
			warrior.respawn_at(_fortress.global_transform * Vector3(8.0, 0.0, 0.0))
	_update_center_message(_respawns.get(local_warrior, 0.0))


## `player` is ready to leave the stop; the fortress departs once every player is (solo: at once).
func request_departure(player: Warrior) -> void:
	if not _is_host() or not _follower.is_stopped or result != Result.NONE or _ready_players.has(player):
		return
	_ready_players[player] = true
	_check_all_ready()


func _check_all_ready() -> void:
	if not _is_host() or not _follower.is_stopped or result != Result.NONE:
		return
	_upgrade_panel.set_ready_count(_ready_players.size(), players.size(), _ready_players.has(local_warrior))
	if _ready_players.size() >= players.size():
		_follower.depart()


# Stop panel presses: the host acts for its own player; a client asks the host.
func _panel_request(kind: StringName, index: int) -> void:
	if _is_host():
		handle_request(kind, index, local_warrior)
	elif _net and local_warrior:
		_net.send_request(kind, index)


## Host: a stop-panel action by `player` (from this machine's panel or a client's NetSync request).
func handle_request(kind: StringName, index: int, player: Warrior) -> void:
	match kind:
		&"tier":
			request_tier_upgrade()
		&"fortress":
			if index >= 0 and index < FortressUpgrades.ALL.size():
				request_fortress_upgrade(FortressUpgrades.ALL[index])
		&"weapon":
			request_weapon_upgrade(index, player)
		&"route":
			request_route(index)
		&"ready":
			request_departure(player)


## Purchases are only allowed while stopped; in multiplayer this check runs on the server.
func request_fortress_upgrade(upgrade: FortressUpgrade) -> bool:
	var done := _is_host() and _follower.is_stopped and _fortress.buy_upgrade(upgrade)
	_upgrade_panel.refresh()
	return done


func request_tier_upgrade() -> bool:
	var done := _is_host() and _follower.is_stopped and _fortress.upgrade_tier()
	_upgrade_panel.refresh()
	return done


## One card per player per stop; the buyer's weapon gets it (default: this machine's warrior).
## Paid from the shared fortress storage.
func request_weapon_upgrade(index: int, buyer: Warrior = null) -> bool:
	buyer = buyer if buyer else local_warrior
	if not _is_host() or not _follower.is_stopped or _weapon_choices.has(buyer.peer_id) or index < 0 or index >= weapon_offers.size():
		return false
	if not _fortress.storage.spend(weapon_offers[index].cost):
		return false
	buyer.weapon.apply_upgrade(weapon_offers[index])
	_weapon_choices[buyer.peer_id] = index
	if buyer == local_warrior:
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
	if not player.can_carry_more():
		return false
	var data := _structures.recover(structure)
	player.carry(data.type, data.health)
	return true


## Any player may toggle the fortress overdrive; in multiplayer the server applies it.
func request_overdrive() -> void:
	if not _is_host() or result != Result.NONE:
		return
	_fortress.overdrive = not _fortress.overdrive
	_toast_all("Tăng tốc! Tốn Than gấp nhiều lần" if _fortress.overdrive else "Chạy bình thường")  # i18n


## Seconds between two pings of one player (anti-spam).
const PING_COOLDOWN := 0.6
## How far from the pinged point something still counts as pinged.
const PING_REACH := 2.5
## Pings farther than this from the pinging player are pulled in.
const PING_MAX_DISTANCE := 45.0


## Any player may mark a point for the team; what is there decides what the mark says.
func request_ping(point: Vector3, warrior: Warrior) -> void:
	if not _is_host() or result != Result.NONE or not warrior.is_alive:
		return
	if elapsed < _ping_ready_at.get(warrior, 0.0):
		return
	_ping_ready_at[warrior] = elapsed + PING_COOLDOWN
	var offset := point - warrior.global_position
	offset.y = 0.0
	point = warrior.global_position + offset.limit_length(PING_MAX_DISTANCE)
	point.y = _fortress.global_position.y
	var meaning := ping_kind(point)
	_show_ping(warrior.peer_id, meaning[0], meaning[1], point)
	_send_fx(&"ping", [warrior.peer_id, meaning[0], meaning[1], point])


## [kind, subject] of a ping at `point` (see PingMarker.kind): enemies first, then building work,
## dropped piles, resources, the fortress itself, else plain ground.
func ping_kind(point: Vector3) -> Array:
	if _nearest_in_group(&"enemies", point, PING_REACH * 1.2):
		return [&"enemy", ""]
	# Blueprints are not in the "structures" group, so ask the network.
	for structure in _structures.structures():
		if _flat_distance(structure.global_position, point) <= PING_REACH:
			return [&"structure", structure.type.display_name] if structure.built else [&"blueprint", ""]
	for pickup: Node3D in _pickups.get_children():
		if _flat_distance(pickup.global_position, point) <= PING_REACH:
			return [&"pickup", ""]
	var node: ResourceNode = _nearest_in_group(&"resource_nodes", point, PING_REACH)
	if node and node.amount > 0:
		return [&"resource", node.resource_type.display_name]
	var local := _fortress.to_local(point)
	if absf(local.x) <= FORTRESS_HALF_SIZE and absf(local.z) <= FORTRESS_HALF_SIZE:
		return [&"fortress", ""]
	return [&"ground", ""]


## Half the fortress footprint plus a margin, for pings on the fortress.
const FORTRESS_HALF_SIZE := 5.5


# Groups span the whole SceneTree (in-process co-op tests run several worlds), so check the world.
func _nearest_in_group(group: StringName, point: Vector3, reach: float) -> Node3D:
	var best: Node3D = null
	var best_distance := reach
	for node: Node3D in get_tree().get_nodes_in_group(group):
		if node.is_queued_for_deletion() or node.get_world_3d() != _fortress.get_world_3d():
			continue
		var distance := _flat_distance(node.global_position, point)
		if distance <= best_distance:
			best = node
			best_distance = distance
	return best


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# One mark per player: a new ping replaces that player's previous one.
func _show_ping(peer: int, kind: StringName, subject: String, point: Vector3) -> void:
	var previous: Node = _pings.get(peer)
	if is_instance_valid(previous):
		previous.queue_free()
	var marker := PingMarker.new()
	marker.peer_id = peer
	marker.kind = kind
	marker.subject = subject
	var warrior := player_by_peer(peer)
	marker.color = warrior.display_color() if warrior else Color.WHITE
	add_child(marker)
	marker.global_position = point
	_pings[peer] = marker


## Any player may fire the Nỏ thần once it is fully charged.
func request_divine_crossbow() -> bool:
	if not _is_host() or result != Result.NONE or not _fortress.divine_crossbow.is_ready():
		return false
	var hits := _fortress.divine_crossbow.fire()
	_toast_all("NỎ THẦN! Trúng %d quái", [hits])  # i18n
	_send_fx(&"blast", [_fortress.divine_crossbow.global_position, 25.0])
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
	if _is_host():
		for warrior in players:
			team_stats.set_class(warrior.peer_id, PlayerClasses.ALL.find(warrior.player_class))
	if _net and _is_host():
		_net.run_finished.rpc(_follower.distance, elapsed, kills, team_stats.net_state())
	var is_record := SaveManager.record_run(_follower.distance, daily_date if mode == Mode.DAILY else "")
	var best := maxf(best_before, _follower.distance)
	_result_screen.show_result(_follower.distance, elapsed, kills, best, is_record, daily_date if mode == Mode.DAILY else "")
	_result_screen.show_team(team_stats, local_warrior.peer_id if local_warrior else 1)
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
		"enemies": _spawner.net_state(),
		"route": RouteTypes.ALL.find(current_route), "kills": kills, "elapsed": elapsed,
		"structures": _structures.net_state(), "pickups": _pickups_net_state(), "shots": _take_net_shots(),
		"stop": _stop_net_state()}


## Client: shows the host's world.
func apply_net_snapshot(snapshot: Dictionary) -> void:
	_fortress.apply_net_state(snapshot.fortress)
	noise.set_net_state(snapshot.noise[0], snapshot.noise[1])
	_spawner.apply_net_state(snapshot.enemies)
	_structures.apply_net_state(snapshot.structures)
	_apply_pickups(snapshot.pickups)
	_apply_stop(snapshot.stop)
	var shots: PackedVector3Array = snapshot.shots
	for i in range(0, shots.size() - 1, 2):
		_draw_tracer(shots[i], shots[i + 1])
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
		var respawn_left: float = warriors[local_warrior.peer_id].back()
		_update_center_message(respawn_left)


## Shows a toast here and on every client, each in its own language (pass the untranslated text).
func _toast_all(text: String, args: Array = []) -> void:
	var shown := args.map(func(value: Variant) -> Variant: return tr(value) if value is String else value)
	_hud.show_toast(tr(text) % shown if not shown.is_empty() else tr(text))
	_send_fx(&"toast", [text, args])


func _send_fx(kind: StringName, args: Array) -> void:
	if _net and _is_host() and Net.is_online(multiplayer):
		_net.send_fx(kind, args)


## Client: a one-off happening on the host (see NetSync.fx).
func play_fx(kind: StringName, args: Array) -> void:
	match kind:
		&"toast":
			var text: String = args[0]
			var values: Array = args[1]
			# String arguments are untranslated names (e.g. a route), translated here too.
			values = values.map(func(value: Variant) -> Variant: return tr(value) if value is String else value)
			_hud.show_toast(tr(text) % values if not values.is_empty() else tr(text))
		&"resource":
			_content.apply_resource_amount(args[0], args[1])
		&"bomb":
			_content.explode_bomb(args[0])
		&"skill":
			_show_skill(args[0], args[1], false)
		&"ping":
			_show_ping(args[0], args[1], args[2], args[3])
		&"blast":
			var blast: Node3D = BLAST_SCENE.instantiate()
			blast.max_scale = args[1]
			add_child(blast)
			blast.global_position = args[0]


# Host: a class skill went off — the parts that need the world, and what clients should see.
func _on_skill_used(skill_id: StringName, at: Vector3, warrior: Warrior) -> void:
	_show_skill(skill_id, at, true)
	_send_fx(&"skill", [skill_id, at])
	if skill_id == &"mechanic" and _fortress.gunner:
		_toast_all("Đốt lò! Lò hơi nạp tên — nỏ trên thành bắn nhanh hơn")  # i18n
	elif skill_id == &"mechanic":
		_toast_all("Đốt lò! Pháo đài tăng tốc mà không tốn thêm Than")  # i18n
	elif warrior == local_warrior and skill_id == &"general":
		_hud.show_toast(tr("Hét trận! Quái quanh bạn lao vào bạn"))


# Bùa trận is a real area on the host and a picture on clients; other skills get a pulse.
func _show_skill(skill_id: StringName, at: Vector3, simulated: bool) -> void:
	var player_class := PlayerClasses.find(skill_id)
	if player_class == null:
		return
	if skill_id == &"shaman":
		var zone := CharmZone.new()
		zone.radius = player_class.skill_radius
		zone.duration = player_class.skill_duration
		zone.heal_per_second = player_class.skill_power
		zone.simulated = simulated
		if simulated:
			zone.hexed.connect(func() -> void: _toast_all("Trấn yểm! Quái dính bùa: chậm hẳn, chịu thêm sát thương"))  # i18n
		add_child(zone)
		zone.global_position = Vector3(at.x, 0.0, at.z)
	elif skill_id in [&"general", &"engineer"]:
		var pulse: Node3D = BLAST_SCENE.instantiate()
		pulse.max_scale = player_class.skill_radius * 2.0
		add_child(pulse)
		pulse.global_position = at


func _on_shot_fired(from: Vector3, to: Vector3) -> void:
	if _net and _is_host():
		_net_shots.append(from)
		_net_shots.append(to)


func _take_net_shots() -> PackedVector3Array:
	var shots := _net_shots
	_net_shots = PackedVector3Array()
	return shots


# Client: the host's shots as brief bars, like AutoShooter's own tracer.
func _draw_tracer(from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.01:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.06, 0.06, 1.0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = TRACER_COLOR
	mesh.material = material
	var tracer := MeshInstance3D.new()
	tracer.mesh = mesh
	add_child(tracer)
	tracer.global_transform = Transform3D(Basis.looking_at(to - from).scaled(Vector3(1.0, 1.0, length)), (from + to) * 0.5)
	get_tree().create_timer(0.08).timeout.connect(tracer.queue_free)


# The stop panel's state (empty while driving): offers by index, choices, who is ready.
func _stop_net_state() -> Dictionary:
	if not _follower.is_stopped or weapon_offers.is_empty():
		return {}
	var ready_ids := PackedInt32Array()
	for player: Warrior in _ready_players:
		ready_ids.append(player.peer_id)
	return {"weapons": weapon_offers.map(func(offer: WeaponUpgrade) -> int: return WeaponUpgrades.ALL.find(offer)),
		"routes": route_offers.map(func(offer: RouteType) -> int: return RouteTypes.ALL.find(offer)),
		"route_choice": route_choice, "weapon_choices": _weapon_choices, "ready": ready_ids, "players": players.size()}


# Client: opens / updates / closes the stop panel as the host's stop goes.
func _apply_stop(stop: Dictionary) -> void:
	if stop.is_empty():
		if _upgrade_panel.visible:
			_upgrade_panel.hide()
			weapon_offers.clear()
		return
	if not _upgrade_panel.visible:
		weapon_offers.assign(stop.weapons.map(func(i: int) -> WeaponUpgrade: return WeaponUpgrades.ALL[i]))
		route_offers.assign(stop.routes.map(func(i: int) -> RouteType: return RouteTypes.ALL[i]))
		route_choice = -1
		_open_stop_panel()
	if stop.route_choice != route_choice:
		route_choice = stop.route_choice
		_upgrade_panel.set_route_choice(route_choice)
	_weapon_choices = stop.weapon_choices
	_upgrade_panel.set_weapon_choice(weapon_choice)
	var ready_ids: PackedInt32Array = stop.ready
	_upgrade_panel.set_ready_count(ready_ids.size(), stop.players, local_warrior != null and ready_ids.has(local_warrior.peer_id))
	_upgrade_panel.refresh()  # storage and upgrade levels come with the same snapshot


func _pickups_net_state() -> Array:
	var states := []
	for pickup: Pickup in _pickups.get_children():
		if not pickup.is_queued_for_deletion():
			states.append([pickup.net_id, pickup.global_position, pickup.color])
	return states


# Client: shows exactly the host's piles; they cannot be collected here.
func _apply_pickups(states: Array) -> void:
	var seen := {}
	for state: Array in states:
		var id: int = state[0]
		seen[id] = true
		if _pickups_by_id.has(id):
			continue
		var pickup: Pickup = PICKUP_SCENE.instantiate()
		pickup.net_id = id
		pickup.monitoring = false
		_pickups.add_child(pickup)
		pickup.set_physics_process(false)
		pickup.global_position = state[1]
		pickup.set_color(state[2])
		_pickups_by_id[id] = pickup
	for id: int in _pickups_by_id.keys():
		if not seen.has(id):
			if is_instance_valid(_pickups_by_id[id]):
				_pickups_by_id[id].queue_free()
			_pickups_by_id.erase(id)


## Client: the host says the run is over.
func finish_from_host(distance: float, host_elapsed: float, host_kills: int, stats: Dictionary = {}) -> void:
	elapsed = host_elapsed
	kills = host_kills
	team_stats.apply_net_state(stats)
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
	_drop_belongings(warrior)
	_respawns[warrior] = respawn_delay


# Host: what a warrior carries falls where it stands (on falling, or leaving the run).
func _drop_belongings(warrior: Warrior) -> void:
	if warrior.manning:
		_fortress.release_gunner()  # drop things at the foot of the ladder, not on the roof
	while warrior.carried_type:
		# Folded structures drop where the warrior fell (unpowered unless the fortress is near).
		_structures.place.call_deferred(warrior.carried_type, warrior.global_position, warrior.carried_health)
		warrior.clear_carried()
	var carried := warrior.inventory.take_all()
	if not carried.is_empty():
		_spawn_pickup.call_deferred(carried, warrior.global_position)


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
	pickup.net_id = _next_pickup_id
	_next_pickup_id += 1
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
	_weapon_choices.clear()
	_ready_players.clear()
	route_offers = RouteTypes.draw(_route_rng, 2)
	route_choice = -1
	_open_stop_panel()
	_upgrade_panel.set_ready_count(0, players.size(), false)
	_toast_all("Điểm dừng — nâng cấp rồi khởi hành")  # i18n


func _open_stop_panel() -> void:
	_upgrade_panel.show()
	_upgrade_panel.set_weapon_offers(weapon_offers)
	_upgrade_panel.set_route_offers(route_offers)


func _on_departed() -> void:
	_spawner.active = true
	_upgrade_panel.hide()
	if not route_offers.is_empty():
		_apply_route(route_offers[maxi(route_choice, 0)])
		_toast_all("Khởi hành — tuyến %s", [current_route.display_name])  # i18n
	else:
		_toast_all("Khởi hành!")  # i18n
