extends SceneTree
## Two-process co-op smoke test of the real flow: the host opens a room from the menu, the client
## joins by address, the host starts, both reload onto the same road and the client gets its warrior.
## Usage: tools/net_smoke.sh   (starts both processes; not part of the game build)

const TIMEOUT_SECONDS := 30.0
const SHARED_SEED := 4242

var _role: String


func _initialize() -> void:
	_role = OS.get_cmdline_user_args()[0]
	_run.call_deferred()


func _run() -> void:
	SaveManager.path = "user://thanhtri_smoke_%s.cfg" % _role
	SaveManager.reload()
	create_timer(TIMEOUT_SECONDS, true).timeout.connect(func() -> void: _done(false, "timed out"))
	change_scene_to_file("res://scenes/main.tscn")
	await _until(func() -> bool: return current_scene != null and current_scene.has_node("Match"))
	var lobby: Match = current_scene.get_node("Match")
	var lobby_id := lobby.get_instance_id()
	if _role == "host":
		lobby.host_room()
		await _until(func() -> bool: return lobby.multiplayer.get_peers().size() == 1)
		lobby._net.start_shared_run(SHARED_SEED)
		await _until(func() -> bool: return _reloaded(lobby_id) and _match().players.size() == 2)
		var seen := _match().players.size()
		await create_timer(3.0, true).timeout  # let the client check its side
		_done(_match().run_seed == SHARED_SEED, "players=%d seed=%d" % [seen, _match().run_seed])
	else:
		await create_timer(1.0, true).timeout  # the host opens the room first
		lobby.join_room("127.0.0.1")
		await _until(func() -> bool: return _reloaded(lobby_id) and _match().local_warrior != null)
		await create_timer(1.0, true).timeout
		var m := _match()
		_done(m.run_seed == SHARED_SEED and m.players.size() == 2 and not m.local_warrior.simulated,
			"players=%d seed=%d fortress at %.1f m" % [m.players.size(), m.run_seed, m.get_node("Fortress").follower.distance])


func _match() -> Match:
	return current_scene.get_node_or_null("Match") if is_instance_valid(current_scene) else null


# The menu's match is gone and the shared run's match took its place.
func _reloaded(lobby_id: int) -> bool:
	return _match() != null and _match().get_instance_id() != lobby_id


func _until(condition: Callable) -> void:
	while not condition.call():
		await process_frame


func _done(ok: bool, detail: String) -> void:
	print("%s %s: %s" % [_role.to_upper(), "OK" if ok else "FAIL", detail])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.path))
	quit(0 if ok else 1)
