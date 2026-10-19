class_name NetSync
extends Node
## Co-op traffic for one match. The host simulates; clients only send what their player wants and
## draw what the host sends back.
##   client → host: `client_input` every tick (unreliable, the next one replaces it) and
##                  `client_events` for one-off presses (reliable, carries the input of that tick).
##   host → client: a snapshot 20 times a second (fortress, noise, route, warriors, enemies…),
##                  compressed and cut into `server_snapshot_part`s that each fit one UDP packet,
##                  `begin_run` to load the same road, `run_finished` when the fortress falls,
##                  `fx` for one-off happenings (toasts, blasts, a tree losing wood, a bomb going off).
## The road and its content are generated from the shared seed on every machine, so only what
## changes during play travels.

const SNAPSHOT_INTERVAL := 0.05
## Bytes of compressed snapshot per packet, safely under ENet's MTU (1392) with RPC overhead.
const SNAPSHOT_PART_BYTES := 1200
## Stop-panel actions a client may ask for (see Match.handle_request).
const ALLOWED_REQUESTS: Array[StringName] = [&"tier", &"fortress", &"weapon", &"route", &"ready"]
## Events a client may send; anything else is dropped.
const ALLOWED_EVENTS: Array[StringName] = [&"dash", &"interact", &"place", &"cancel", &"select", &"skill", &"ready", &"overdrive", &"divine", &"ping"]

var _match: Match
## Host: peers whose match has loaded and that receive snapshots.
var _ready_peers: Dictionary = {}
var _snapshot_left: float = 0.0
## Host: number of the next snapshot. Client: parts of the snapshot being collected.
var _snapshot_seq: int = 0
var _parts_seq: int = -1
var _parts: Array = []
var _parts_left: int = 0
var _applied_seq: int = -1


func setup(match_node: Match) -> void:
	_match = match_node
	process_mode = Node.PROCESS_MODE_ALWAYS  # the lobby runs behind a paused tree
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_match.on_host_lost)
	if not multiplayer.is_server():
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			_announce_ready()
		else:
			multiplayer.connected_to_server.connect(_announce_ready, CONNECT_ONE_SHOT)


## Host: tells everyone (itself included) to load the road for `run_seed`.
func start_shared_run(run_seed: int) -> void:
	begin_run.rpc(run_seed)
	begin_run(run_seed)


func _announce_ready() -> void:
	if _match.in_lobby():
		return  # joined from the menu: wait for the host to start a run
	client_ready.rpc_id(1, PlayerClasses.ALL.find(PlayerClasses.chosen()))


func _physics_process(delta: float) -> void:
	if not Net.is_online(multiplayer) or _match.in_lobby():
		return
	if multiplayer.is_server():
		_snapshot_left -= delta
		if _snapshot_left <= 0.0:
			_snapshot_left += SNAPSHOT_INTERVAL
			_send_snapshot(_match.net_snapshot())
	elif _match.local_warrior:
		var input := _match.local_warrior.input
		var state := input.export_state()
		var events := input.take_local_events()
		if events.is_empty():
			client_input.rpc_id(1, state)
		else:
			client_events.rpc_id(1, events, state)


@rpc("authority", "call_remote", "reliable")
func begin_run(run_seed: int) -> void:
	_match.load_shared_run(run_seed)


@rpc("any_peer", "call_remote", "reliable")
func client_ready(class_index: int) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	_ready_peers[id] = true
	var valid := class_index >= 0 and class_index < PlayerClasses.ALL.size()
	_match.spawn_player(id, PlayerClasses.ALL[class_index] if valid else null)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func client_input(state: Dictionary) -> void:
	var warrior := _sender_warrior()
	if warrior:
		warrior.input.apply_remote_state(_clean_state(state))


@rpc("any_peer", "call_remote", "reliable")
func client_events(events: Array, state: Dictionary) -> void:
	var warrior := _sender_warrior()
	if warrior == null:
		return
	warrior.input.apply_remote_state(_clean_state(state))
	var clean: Array = []
	for event in events:
		if event is Array and not event.is_empty() and ALLOWED_EVENTS.has(event[0]):
			if event[0] == &"select" and not (event.size() == 2 and event[1] is int):
				continue
			if event[0] == &"ping" and not (event.size() == 2 and event[1] is Vector3 and (event[1] as Vector3).is_finite()):
				continue
			clean.append(event)
	warrior.input.apply_remote_events(clean)


## Host: compresses the snapshot and sends it in packet-sized parts to every ready client.
func _send_snapshot(snapshot: Dictionary) -> void:
	var raw := var_to_bytes(snapshot)
	var packed := raw.compress(FileAccess.COMPRESSION_DEFLATE)
	var count := ceili(float(packed.size()) / SNAPSHOT_PART_BYTES)
	_snapshot_seq += 1
	for i in count:
		var part := packed.slice(i * SNAPSHOT_PART_BYTES, (i + 1) * SNAPSHOT_PART_BYTES)
		for id: int in _ready_peers:
			server_snapshot_part.rpc_id(id, _snapshot_seq, i, count, raw.size(), part)


## Client: collects the parts of one snapshot; a newer snapshot replaces an incomplete older one
## (a lost part only costs that snapshot — the next one is 50 ms away).
@rpc("authority", "call_remote", "unreliable_ordered")
func server_snapshot_part(seq: int, index: int, count: int, raw_size: int, part: PackedByteArray) -> void:
	if seq <= _applied_seq or index < 0 or index >= count:
		return
	if seq != _parts_seq:
		if seq < _parts_seq:
			return
		_parts_seq = seq
		_parts = []
		_parts.resize(count)
		_parts_left = count
	if _parts.size() != count or _parts[index] != null:
		return
	_parts[index] = part
	_parts_left -= 1
	if _parts_left > 0:
		return
	var packed := PackedByteArray()
	for piece: PackedByteArray in _parts:
		packed.append_array(piece)
	_applied_seq = seq
	var snapshot: Variant = bytes_to_var(packed.decompress(raw_size, FileAccess.COMPRESSION_DEFLATE))
	if snapshot is Dictionary:
		_match.apply_net_snapshot(snapshot)


## Client: asks the host for a stop-panel action for this player.
func send_request(kind: StringName, index: int) -> void:
	client_request.rpc_id(1, kind, index)


@rpc("any_peer", "call_remote", "reliable")
func client_request(kind: StringName, index: int) -> void:
	var warrior := _sender_warrior()
	if warrior and ALLOWED_REQUESTS.has(kind):
		_match.handle_request(kind, index, warrior)


## Host: sends a one-off happening to every client in the run.
func send_fx(kind: StringName, args: Array) -> void:
	for id: int in _ready_peers:
		fx.rpc_id(id, kind, args)


@rpc("authority", "call_remote", "reliable")
func fx(kind: StringName, args: Array) -> void:
	_match.play_fx(kind, args)


@rpc("authority", "call_remote", "reliable")
func run_finished(distance: float, elapsed: float, kills: int, stats: Dictionary) -> void:
	_match.finish_from_host(distance, elapsed, kills, stats)


func _sender_warrior() -> Warrior:
	if not multiplayer.is_server():
		return null
	var id := multiplayer.get_remote_sender_id()
	return _match.player_by_peer(id) if _ready_peers.has(id) else null


func _on_peer_disconnected(id: int) -> void:
	_ready_peers.erase(id)
	if multiplayer.is_server():
		_match.remove_player(id)


# A client only controls its own intent, and only within what a gamepad could produce.
static func _clean_state(state: Dictionary) -> Dictionary:
	var clean := {}
	for key in ["move", "aim", "point"]:
		if state.get(key) is Vector3:
			clean[key] = state[key]
	if clean.has("move"):
		clean.move = Vector3(clean.move.x, 0.0, clean.move.z).limit_length(1.0)
	if clean.has("aim"):
		clean.aim = Vector3(clean.aim.x, 0.0, clean.aim.z).normalized()
		if clean.aim == Vector3.ZERO:
			clean.erase("aim")
	if state.get("stick") is Vector2:
		clean.stick = (state.stick as Vector2).limit_length(1.0)
	for key in ["attack", "interact", "recover", "radial"]:
		clean[key] = state.get(key) is bool and state[key]
	return clean
